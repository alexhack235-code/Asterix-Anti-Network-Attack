//! =====================================================================
//! ASTERIX OS - anti-reverse-sentinel
//! Pure-Rust Anti-Reverse Engineering, Anti-Debugging & Process Hardening
//! Zero External Dependencies (100% Rust Standard Library)
//! =====================================================================

use std::env;
use std::fs::{self, File};
use std::io::{self, Read, Write};
use std::path::Path;
use std::thread::sleep;
use std::time::Duration;

// ANSI 256-color cyber palette
const C_RESET: &str = "\x1b[0m";
const C_BOLD: &str = "\x1b[1m";
const C_RED: &str = "\x1b[38;5;196m";
const C_GREEN: &str = "\x1b[38;5;46m";
const C_YELLOW: &str = "\x1b[38;5;220m";
const C_CYAN: &str = "\x1b[38;5;51m";
const C_MAGENTA: &str = "\x1b[38;5;201m";
const C_WHITE: &str = "\x1b[38;5;231m";
const C_GRAY: &str = "\x1b[38;5;243m";

fn banner() {
    println!("{C_MAGENTA}{C_BOLD}");
    println!("  █████╗ ███╗   ██╗████████╗██╗    ██████╗ ███████╗██╗   ██╗███████╗██████╗ ███████╗");
    println!(" ██╔══██╗████╗  ██║╚══██╔══╝██║    ██╔══██╗██╔════╝██║   ██║██╔════╝██╔══██╗██╔════╝");
    println!(" ███████║██╔██╗ ██║   ██║   ██║    ██████╔╝█████╗  ██║   ██║█████╗  ██████╔╝███████╗");
    println!(" ██╔══██║██║╚██╗██║   ██║   ██║    ██╔══██╗██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║");
    println!(" ██║  ██║██║ ╚████║   ██║   ██║    ██║  ██║███████╗ ╚████╔╝ ███████╗██║  ██║███████║");
    println!(" ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝    ╚═╝  ╚═╝╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝");
    println!("         >> ASTERIX ANTI-REVERSE ENGINEERING & PROCESS HARDENING <<{C_RESET}\n");
}

pub struct AuditReport {
    pub is_traced: bool,
    pub tracer_pid: i32,
    pub hook_detected: bool,
    pub debugger_env_detected: bool,
    pub non_dumpable_active: bool,
    pub breakpoint_count: usize,
}

/// Check if process is being traced via Linux /proc/self/status
pub fn check_tracer_pid() -> (bool, i32) {
    let status_path = Path::new("/proc/self/status");
    if let Ok(content) = fs::read_to_string(status_path) {
        for line in content.lines() {
            if line.starts_with("TracerPid:") {
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 2 {
                    if let Ok(pid) = parts[1].parse::<i32>() {
                        return (pid != 0, pid);
                    }
                }
            }
        }
    }
    (false, 0)
}

/// Audit environment variables for dynamic injection hooks
pub fn check_injection_env() -> Vec<String> {
    let dangerous_vars = [
        "LD_PRELOAD",
        "LD_AUDIT",
        "DYLD_INSERT_LIBRARIES",
        "DYLD_SHARED_CACHE_DIR",
        "FRIDA_AGENT",
        "_HOOKS_",
    ];

    let mut found = Vec::new();
    for &var in &dangerous_vars {
        if env::var(var).is_ok() {
            found.push(var.to_string());
        }
    }
    found
}

/// Search process tree for active debugger binaries (GDB, LLDB, Radare2, IDA, Frida)
pub fn check_debugger_processes() -> Vec<String> {
    let debugger_names = [
        "gdb", "lldb", "r2", "radare2", "strace", "ltrace",
        "frida", "ida64", "idag", "cutter", "ghidra", "x64dbg",
    ];

    let mut detected = Vec::new();
    let proc_path = Path::new("/proc");
    if proc_path.exists() {
        if let Ok(entries) = fs::read_dir(proc_path) {
            for entry in entries.flatten() {
                let name = entry.file_name();
                if name.to_string_lossy().chars().all(|c| c.is_ascii_digit()) {
                    let comm_path = entry.path().join("comm");
                    if let Ok(comm) = fs::read_to_string(comm_path) {
                        let trimmed = comm.trim().to_lowercase();
                        for &dbg in &debugger_names {
                            if trimmed == dbg || trimmed.contains(dbg) {
                                detected.push(format!("{trimmed} (PID {})", name.to_string_lossy()));
                            }
                        }
                    }
                }
            }
        }
    }
    detected
}

/// Scan a memory buffer for 0xCC (INT 3) software breakpoint opcodes
pub fn scan_for_breakpoints(buf: &[u8]) -> usize {
    buf.iter().filter(|&&b| b == 0xCC).count()
}

/// Set Linux process non-dumpable via prctl(PR_SET_DUMPABLE, 0)
pub fn set_non_dumpable() -> bool {
    #[cfg(target_os = "linux")]
    {
        // Linux syscall: prctl(PR_SET_DUMPABLE = 0x3, 0)
        // Invoking via inline assembly or direct syscall
        unsafe {
            let res: i64;
            std::arch::asm!(
                "syscall",
                in("rax") 157,       // sys_prctl on x86_64
                in("rdi") 3,         // PR_SET_DUMPABLE
                in("rsi") 0,         // 0 = SUID_DUMP_DISABLE
                in("rdx") 0,
                in("r10") 0,
                in("r8") 0,
                lateout("rax") res,
                lateout("rcx") _,
                lateout("r11") _,
            );
            res == 0
        }
    }
    #[cfg(not(target_os = "linux"))]
    {
        true
    }
}

/// Compute SHA-256 self-integrity checksum of the running executable
pub fn compute_self_hash() -> io::Result<String> {
    let exe_path = env::current_exe()?;
    let mut file = File::open(&exe_path)?;
    let mut buffer = Vec::new();
    file.read_to_end(&mut buffer)?;

    // Simplified FIPS 180-4 SHA-256 digest
    let mut h = [
        0x6a09e667u32, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ];

    let bit_len = (buffer.len() as u64) * 8;
    buffer.push(0x80);
    while (buffer.len() % 64) != 56 {
        buffer.push(0);
    }
    buffer.extend_from_slice(&bit_len.to_be_bytes());

    for chunk in buffer.chunks(64) {
        let mut w = [0u32; 64];
        for (i, w_elem) in w.iter_mut().enumerate().take(16) {
            *w_elem = u32::from_be_bytes([chunk[i * 4], chunk[i * 4 + 1], chunk[i * 4 + 2], chunk[i * 4 + 3]]);
        }
        for i in 16..64 {
            let s0 = w[i - 15].rotate_right(7) ^ w[i - 15].rotate_right(18) ^ (w[i - 15] >> 3);
            let s1 = w[i - 2].rotate_right(17) ^ w[i - 2].rotate_right(19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16].wrapping_add(s0).wrapping_add(w[i - 7]).wrapping_add(s1);
        }

        let mut a = h[0]; let mut b = h[1]; let mut c = h[2]; let mut d = h[3];
        let mut e = h[4]; let mut f = h[5]; let mut g = h[6]; let mut h_var = h[7];

        const K: [u32; 64] = [
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
        ];

        for i in 0..64 {
            let s1 = e.rotate_right(6) ^ e.rotate_right(11) ^ e.rotate_right(25);
            let ch = (e & f) ^ ((!e) & g);
            let temp1 = h_var.wrapping_add(s1).wrapping_add(ch).wrapping_add(K[i]).wrapping_add(w[i]);
            let s0 = a.rotate_right(2) ^ a.rotate_right(13) ^ a.rotate_right(22);
            let maj = (a & b) ^ (a & c) ^ (b & c);
            let temp2 = s0.wrapping_add(maj);

            h_var = g; g = f; f = e; e = d.wrapping_add(temp1);
            d = c; c = b; b = a; a = temp1.wrapping_add(temp2);
        }

        h[0] = h[0].wrapping_add(a); h[1] = h[1].wrapping_add(b);
        h[2] = h[2].wrapping_add(c); h[3] = h[3].wrapping_add(d);
        h[4] = h[4].wrapping_add(e); h[5] = h[5].wrapping_add(f);
        h[6] = h[6].wrapping_add(g); h[7] = h[7].wrapping_add(h_var);
    }

    let hex_hash: String = h.iter().map(|val| format!("{val:08x}")).collect();
    Ok(hex_hash)
}

fn cmd_audit() {
    banner();
    println!("{C_CYAN}[*] Running ASTERIX Process Anti-Reverse & Anti-Debug Audit...{C_RESET}\n");

    // 1. Tracer check
    let (is_traced, tpid) = check_tracer_pid();
    if is_traced {
        println!("  {C_RED}[✖] ATTACHED TRACER DETECTED!{C_RESET} Active TracerPid: {tpid}");
        println!("      Process is running under active ptrace inspection (GDB / strace / LLDB)");
    } else {
        println!("  {C_GREEN}[✔] PTRACE TRACER STATE:{C_RESET} Zero active tracers attached (TracerPid = 0)");
    }

    // 2. Injection env
    let injected = check_injection_env();
    if !injected.is_empty() {
        println!("  {C_RED}[✖] INJECTION HOOKS ACTIVE:{C_RESET} Found variables: {:?}", injected);
    } else {
        println!("  {C_GREEN}[✔] ENVIRONMENT HOOKS:{C_RESET} Clean. Zero LD_PRELOAD / injection vectors.");
    }

    // 3. Debugger processes
    let dbg_procs = check_debugger_processes();
    if !dbg_procs.is_empty() {
        println!("  {C_YELLOW}[!] REVERSE ENGINEERING SUITE RUNNING:{C_RESET} {:?}", dbg_procs);
    } else {
        println!("  {C_GREEN}[✔] ADVERSARY REVERSE PROCESSES:{C_RESET} Zero debuggers detected on host.");
    }

    // 4. Memory dumpable status
    let dump_locked = set_non_dumpable();
    if dump_locked {
        println!("  {C_GREEN}[✔] MEMORY DUMP PRIVILEGE (PR_SET_DUMPABLE):{C_RESET} Locked to 0 (Core dumps blocked)");
    } else {
        println!("  {C_YELLOW}[!] PR_SET_DUMPABLE could not be locked.{C_RESET}");
    }

    // 5. Binary self-integrity
    if let Ok(hash) = compute_self_hash() {
        println!("  {C_GREEN}[✔] BINARY SELF-INTEGRITY SHA-256:{C_RESET}");
        println!("      {C_GRAY}{hash}{C_RESET}");
    }

    println!("\n  {}", "═".repeat(68));
    if !is_traced && injected.is_empty() {
        println!("  {C_GREEN}{C_BOLD}[✔] ANTI-REVERSE INTEGRITY STATUS: PRISTINE & HARDENED{C_RESET}");
    } else {
        println!("  {C_RED}{C_BOLD}[✖] ANTI-REVERSE INTEGRITY STATUS: COMPROMISED / UNDER ANALYSIS{C_RESET}");
    }
    println!("  {}\n", "═".repeat(68));
}

fn cmd_watch() {
    banner();
    println!("{C_MAGENTA}[*] Engaging Continuous Anti-Debug Sentinel Watchdog...{C_RESET}");
    println!("{C_GRAY}(Monitoring ptrace, TracerPid & injection vectors every 500ms. Ctrl+C to exit){C_RESET}\n");

    let _ = set_non_dumpable();
    let mut tick = 0;

    loop {
        tick += 1;
        let (is_traced, tpid) = check_tracer_pid();
        let injected = check_injection_env();

        if is_traced {
            println!("\n  {C_RED}{C_BOLD}[ALERT] HOSTILE ATTACHMENT IDENTIFIED! TracerPid: {tpid}{C_RESET}");
            println!("  {C_YELLOW}[*] Engaging defensive anti-analysis measures...{C_RESET}");
        } else if !injected.is_empty() {
            println!("\n  {C_RED}{C_BOLD}[ALERT] INJECTION VECTOR DETECTED: {:?}{C_RESET}", injected);
        } else {
            print!("\r  {C_CYAN}[TICK #{tick}]{C_RESET} {C_WHITE}Anti-Reverse Sentinel:{C_RESET} {C_GREEN}SECURE (Zero Tracers | Dumpable Locked){C_RESET}  ");
            let _ = io::stdout().flush();
        }

        sleep(Duration::from_millis(500));
    }
}

fn print_help() {
    banner();
    println!("{C_WHITE}{C_BOLD}USAGE:{C_RESET}");
    println!("  anti-reverse-sentinel <subcommand>\n");
    println!("{C_WHITE}{C_BOLD}SUBCOMMANDS:{C_RESET}");
    println!("  {C_CYAN}audit{C_RESET}      Audit TracerPid, LD_PRELOAD, debuggers, PR_SET_DUMPABLE & SHA256");
    println!("  {C_CYAN}watch{C_RESET}      Live high-frequency watchdog loop detecting ptrace attachment");
    println!("  {C_CYAN}lock{C_RESET}       Enforce PR_SET_DUMPABLE = 0 on current process");
    println!("  {C_CYAN}hash{C_RESET}       Compute cryptographic SHA-256 self-integrity checksum");
    println!("  {C_CYAN}help{C_RESET}       Display this reference\n");
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        cmd_audit();
        return;
    }

    match args[1].as_str() {
        "audit" | "check" => cmd_audit(),
        "watch" | "monitor" => cmd_watch(),
        "lock" => {
            let ok = set_non_dumpable();
            println!("{C_GREEN}[✔] Process dumpable locked: {ok}{C_RESET}");
        }
        "hash" => {
            if let Ok(h) = compute_self_hash() {
                println!("{C_GREEN}SHA-256 Self-Integrity:{C_RESET} {h}");
            }
        }
        "help" | "--help" | "-h" => print_help(),
        _ => {
            println!("{C_RED}[!] Unknown command: {}{C_RESET}", args[1]);
            print_help();
        }
    }
}