# 🛡️ ASTERIX Anti-Network Attack & Process Defense Suite
### Standalone, Portable Cybersecurity Defense & Hardening Tools

This suite provides active network defense countermeasures, email/account security auditing, and process anti-debugging capabilities. It is **100% standalone** and runs on **any Linux distribution** (Ubuntu, Debian, Kali, Arch, Fedora, Alpine) as well as **Android Termux**, with **zero dependency on Asterix OS**.

---

## ⚡ Quick Start (Run Standalone Without Asterix OS)

### Option 1: 1-Command Automated Installer
```bash
git clone https://github.com/your-repo/ASTERIX-OS.git
cd "ASTERIX OS/asterix-anti-network-attack"
chmod +x install-standalone.sh
./install-standalone.sh
```
This automatically builds the Rust sentinel and installs all tools into `/usr/local/bin` (or `~/.local/bin` / Termux `$PREFIX/bin`).

### Option 2: Standard Makefile Install
```bash
sudo make install
```
On Android Termux (no root required):
```bash
make install PREFIX=$PREFIX
```

### Option 3: Run Directly In-Place (No Installation Required!)
You can execute any script directly from this directory:
```bash
./anti-net-shield.sh          # Launch interactive defense hub
./anti-email-shield.sh audit google.com
./anti-arp-spoof.sh status
./anti-synflood.sh status
./anti-dns-hijack.sh check
./anti-portscan.sh status
```

---

## 🛠️ Standalone Tool Arsenal

| Tool Name | Global Alias | Primary Capabilities |
| :--- | :--- | :--- |
| `anti-net-shield.sh` | **`anti-net`** | Master interactive terminal defense dashboard & automated full audit (`anti-net audit`) |
| `anti-email-shield.sh` | **`anti-email`** | SPF, DKIM, DMARC verification, MX STARTTLS auditing, k-anonymity breach checking & `.eml` header analysis (Zero password storage) |
| `anti-arp-spoof.sh` | **`anti-arp`** | Active ARP poisoning detection, gateway MAC monitoring & permanent static kernel binding (`nud permanent`) |
| `anti-synflood.sh` | **`anti-syn`** | Kernel TCP SYN cookies (`net.ipv4.tcp_syncookies = 1`), backlog optimization & iptables embryonic connection rate limiter |
| `anti-dns-hijack.sh` | **`anti-dns`** | Rogue DNS & DHCP redirect detector; cross-verifies answers against Cloudflare `1.1.1.1` and Quad9 `9.9.9.9`; locks `/etc/resolv.conf` |
| `anti-portscan.sh` | **`anti-scan`** | Stealth port scan detection (NULL, XMAS, FIN); automatically quarantines scanning IPs for 30 minutes via iptables `recent` module |
| `anti-reverse-sentinel` | **`anti-rev`** | Pure-Rust anti-debugging engine; detects ptrace attachments (`TracerPid != 0`), memory breakpoints (`0xCC`), locks memory dumps (`PR_SET_DUMPABLE = 0`) |

---

## 📖 Command Reference & Examples

### 1. 📧 Email & Account Security (`anti-email`)
Defends domains and accounts without ever prompting for or storing user passwords:
```bash
# Verify anti-spoofing policies (SPF/DMARC) on a domain
anti-email audit yourcompany.com

# Check if an email address has been leaked in public breaches (k-anonymity safe lookup)
anti-email breach user@example.com

# Forensically inspect a raw email file for spoofed sender headers & forged relay hops
anti-email phish suspicious_message.eml

# View Google/Gmail 2FA, Passkey, and account hardening checklist
anti-email hardening
```

### 2. 🛡️ ARP Spoofing & MITM Defense (`anti-arp`)
```bash
# Check current ARP cache and gateway status
anti-arp status

# Lock default gateway MAC permanently (Immunizes host against ARP poisoning / MITM)
sudo anti-arp lock

# Restore dynamic gateway ARP state
sudo anti-arp unlock

# Run continuous real-time background watcher with audible alarms
anti-arp watch
```

### 3. 🌊 TCP SYN Flood & DoS Defense (`anti-syn`)
```bash
# Inspect kernel SYN cookies and active half-open SYN_RECV sockets
anti-syn status

# Enable kernel hardening and firewall rate limiting (50 SYN/sec)
sudo anti-syn enable

# Disable firewall rate-limiting rules
sudo anti-syn disable

# Monitor embryonic connection backlog in real-time
anti-syn monitor
```

### 4. 🌐 DNS Hijack & Poisoning Shield (`anti-dns`)
```bash
# Cross-verify local DNS resolution against encrypted upstreams (1.1.1.1 & 9.9.9.9)
anti-dns check github.com

# Lock /etc/resolv.conf with immutable attribute (+i) to block rogue DHCP overwrites
sudo anti-dns lock

# Unlock /etc/resolv.conf
sudo anti-dns unlock

# Run continuous canary query monitor
anti-dns watch
```

### 5. 🎯 Port Scan Detection & Blocker (`anti-scan`)
```bash
# View active port scan traps and currently quarantined IP addresses
sudo anti-scan status

# Arm port scan traps and dynamic 30-minute auto-quarantine
sudo anti-scan enable

# Disarm firewall traps
sudo anti-scan disable

# Manually release an IP address from quarantine
sudo anti-scan unblock 192.168.1.50
```

### 6. ⚙️ Anti-Reverse Engineering Sentinel (`anti-rev`)
```bash
# Comprehensive anti-debugging and process integrity audit
anti-rev audit

# Continuous watchdog detecting ptrace attachment & memory breakpoint traps
anti-rev watch

# Lock PR_SET_DUMPABLE to prevent memory core dumps
anti-rev lock

# Compute SHA-256 binary self-integrity hash
anti-rev hash
```

---

## 📱 Android Termux Compatibility
This entire suite runs inside standard Android Termux.
1. Run `make install PREFIX=$PREFIX` or `bash install-standalone.sh`.
2. Commands like `anti-net`, `anti-email`, and `anti-rev` run with zero root required.
3. Network layer tools (`anti-arp`, `anti-syn`, `anti-scan`) utilize root permissions (`tsu` or `sudo`) if available on rooted Android devices, or provide passive analysis modes on rootless PRoot.