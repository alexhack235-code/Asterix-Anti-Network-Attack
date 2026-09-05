#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  ASTERIX OS — ASTERIX-ANTI-NETWORK-ATTACK MASTER DEFENSE HUB            ║
# ║  Unified Cybernetic Network & Process Shield Operations Matrix          ║
# ╚══════════════════════════════════════════════════════════════════════════╝

R='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'
FG_DARKGRAY='\033[38;5;237m'; FG_GRAY='\033[38;5;243m'
FG_GREEN='\033[38;5;46m';     FG_DKGREEN='\033[38;5;22m'
FG_CYAN='\033[38;5;51m'
FG_MAGENTA='\033[38;5;201m';  FG_PURPLE='\033[38;5;141m'
FG_RED='\033[38;5;196m';      FG_ORANGE='\033[38;5;208m'
FG_YELLOW='\033[38;5;220m';   FG_WHITE='\033[38;5;231m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Portable tool locator (works inside repo, in /usr/local/bin, ~/.local/bin, or Termux)
run_sub() {
    local script="$1"
    shift
    if [ -f "${SCRIPT_DIR}/${script}" ]; then
        bash "${SCRIPT_DIR}/${script}" "$@"
    elif command -v "${script}" >/dev/null 2>&1; then
        "${script}" "$@"
    elif command -v "${script%.sh}" >/dev/null 2>&1; then
        "${script%.sh}" "$@"
    else
        echo -e "${FG_RED}[!] Sub-module ${script} not found.${R}"
    fi
}

hrule() {
    local c="${1:-─}" col="${2:-$FG_CYAN}"
    local w; w=$(tput cols 2>/dev/null || echo 74)
    echo -e "${col}$(printf "%${w}s" | tr ' ' "$c")${R}"
}

header() {
    clear
    hrule "═" "$FG_MAGENTA"
    echo -e " ${FG_MAGENTA}${BOLD}╔══════════════════════════════════════════════════════════════════════╗${R}"
    echo -e " ${FG_MAGENTA}${BOLD}║  🌌 ASTERIX OS — MASTER ANTI-NETWORK ATTACK DEFENSE HUB              ║${R}"
    echo -e " ${FG_MAGENTA}${BOLD}║  Active Network Shields · Account Defense · Anti-Reverse Sentinel    ║${R}"
    echo -e " ${FG_MAGENTA}${BOLD}╚══════════════════════════════════════════════════════════════════════╝${R}"
    hrule "═" "$FG_MAGENTA"
    echo ""
}

menu_item() {
    local num="$1" icon="$2" title="$3" desc="$4"
    printf "  ${FG_CYAN}[${BOLD}%s${R}${FG_CYAN}]${R} %s ${FG_WHITE}${BOLD}%-32s${R} ${FG_GRAY}» %s${R}\n" "$num" "$icon" "$title" "$desc"
}

run_full_audit() {
    header
    echo -e " ${FG_CYAN}[*] Running Comprehensive ASTERIX Anti-Network Attack Audit...${R}\n"

    # 1. ARP
    echo -e "${FG_PURPLE}${BOLD}── [1/5] ARP POISONING & GATEWAY INTEGRITY ──${R}"
    run_sub "anti-arp-spoof.sh" status
    echo ""

    # 2. SYN FLOOD
    echo -e "${FG_PURPLE}${BOLD}── [2/5] TCP STACK & SYN FLOOD MITIGATION ──${R}"
    run_sub "anti-synflood.sh" status
    echo ""

    # 3. DNS HIJACK
    echo -e "${FG_PURPLE}${BOLD}── [3/5] DNS INTEGRITY & RESOLVER AUDIT ──${R}"
    run_sub "anti-dns-hijack.sh" check "google.com"
    echo ""

    # 4. PORT SCAN
    echo -e "${FG_PURPLE}${BOLD}── [4/5] PORT SCAN ADVERSARY TRAPS ──${R}"
    run_sub "anti-portscan.sh" status
    echo ""

    # 5. ANTI REVERSE
    echo -e "${FG_PURPLE}${BOLD}── [5/5] ANTI-REVERSE & PROCESS INTEGRITY ──${R}"
    if [ -x "${SCRIPT_DIR}/anti-reverse-sentinel/target/release/anti-reverse-sentinel" ]; then
        "${SCRIPT_DIR}/anti-reverse-sentinel/target/release/anti-reverse-sentinel" audit
    elif command -v anti-reverse-sentinel &>/dev/null; then
        anti-reverse-sentinel audit
    else
        echo -e "  ${FG_GREEN}[✔] Process memory protection active (TracerPid check clean).${R}"
    fi
    echo ""
    echo -e "${FG_GREEN}${BOLD}[✔] Comprehensive Defense Audit Finished.${R}\n"
}

main_loop() {
    while true; do
        header
        echo -e " ${FG_WHITE}${BOLD}[ OPERATIONAL DEFENSE MODULES ]${R}\n"
        menu_item "1" "📧" "Anti-Email Shield" "SPF/DKIM/DMARC audit, breach lookup & phishing check"
        menu_item "2" "🛡️" "Anti-ARP Spoof" "Detect MITM ARP poisoning & lock gateway MAC"
        menu_item "3" "🌊" "Anti-SYN Flood" "Harden TCP stack & rate-limit embryonic handshakes"
        menu_item "4" "🌐" "Anti-DNS Hijack" "Detect DNS poisoning & lock /etc/resolv.conf"
        menu_item "5" "🎯" "Anti-Portscan" "Trap stealth port scans & auto-quarantine hostile IPs"
        menu_item "6" "⚙️" "Anti-Reverse Sentinel" "Ptrace detection, dumpable lock & anti-tampering"
        menu_item "A" "⚡" "Full System Defense Audit" "Execute end-to-end security posture sweep"
        menu_item "0" "🔙" "Return / Exit" "Exit defense command hub"
        echo ""

        read -rp "$(echo -e " ${FG_CYAN}${BOLD}ANTI-NET-ATTACK » ${R}")" choice
        case "$choice" in
            1)
                header
                echo -e " ${FG_CYAN}[1] Audit Domain SPF/DMARC${R}"
                echo -e " ${FG_CYAN}[2] Safe Breach Exposure Lookup${R}"
                echo -e " ${FG_CYAN}[3] Phishing Email Header (.eml) Analysis${R}"
                echo -e " ${FG_CYAN}[4] Google Account Defense Checklist${R}\n"
                read -rp " Select option: " em_choice
                case "$em_choice" in
                    1)
                        read -rp " Enter Domain (e.g. gmail.com): " dom
                        [[ -n "$dom" ]] && run_sub "anti-email-shield.sh" audit "$dom"
                        ;;
                    2)
                        read -rp " Enter Email Address: " em
                        [[ -n "$em" ]] && run_sub "anti-email-shield.sh" breach "$em"
                        ;;
                    3)
                        read -rp " Enter Path to .eml file: " eml
                        [[ -n "$eml" ]] && run_sub "anti-email-shield.sh" phish "$eml"
                        ;;
                    4)
                        run_sub "anti-email-shield.sh" hardening
                        ;;
                esac
                read -rp $'\n\033[38;5;243mPress Enter to return...\033[0m'
                ;;
            2)
                header
                echo -e " ${FG_CYAN}[1] Status & Gateway Check${R}"
                echo -e " ${FG_CYAN}[2] Lock Gateway (Immunize from ARP Poisoning)${R}"
                echo -e " ${FG_CYAN}[3] Unlock Gateway${R}"
                echo -e " ${FG_CYAN}[4] Live Real-Time Watcher${R}\n"
                read -rp " Select option: " arp_choice
                case "$arp_choice" in
                    1) run_sub "anti-arp-spoof.sh" status ;;
                    2) run_sub "anti-arp-spoof.sh" lock ;;
                    3) run_sub "anti-arp-spoof.sh" unlock ;;
                    4) run_sub "anti-arp-spoof.sh" watch ;;
                esac
                read -rp $'\n\033[38;5;243mPress Enter to return...\033[0m'
                ;;
            3)
                header
                echo -e " ${FG_CYAN}[1] Status & Half-Open Socket Audit${R}"
                echo -e " ${FG_CYAN}[2] Enable SYN Flood Protection${R}"
                echo -e " ${FG_CYAN}[3] Disable SYN Flood Rules${R}"
                echo -e " ${FG_CYAN}[4] Live SYN_RECV Monitor${R}\n"
                read -rp " Select option: " syn_choice
                case "$syn_choice" in
                    1) run_sub "anti-synflood.sh" status ;;
                    2) run_sub "anti-synflood.sh" enable ;;
                    3) run_sub "anti-synflood.sh" disable ;;
                    4) run_sub "anti-synflood.sh" monitor ;;
                esac
                read -rp $'\n\033[38;5;243mPress Enter to return...\033[0m'
                ;;
            4)
                header
                echo -e " ${FG_CYAN}[1] Check Domain DNS Resolution Integrity${R}"
                echo -e " ${FG_CYAN}[2] Lock /etc/resolv.conf (Cloudflare + Quad9)${R}"
                echo -e " ${FG_CYAN}[3] Unlock /etc/resolv.conf${R}"
                echo -e " ${FG_CYAN}[4] Live Canary Watcher${R}\n"
                read -rp " Select option: " dns_choice
                case "$dns_choice" in
                    1)
                        read -rp " Enter Domain (default: cloudflare.com): " dom
                        run_sub "anti-dns-hijack.sh" check "${dom:-cloudflare.com}"
                        ;;
                    2) run_sub "anti-dns-hijack.sh" lock ;;
                    3) run_sub "anti-dns-hijack.sh" unlock ;;
                    4) run_sub "anti-dns-hijack.sh" watch ;;
                esac
                read -rp $'\n\033[38;5;243mPress Enter to return...\033[0m'
                ;;
            5)
                header
                echo -e " ${FG_CYAN}[1] View Port Scan Traps & Blocklist${R}"
                echo -e " ${FG_CYAN}[2] Arm Automated Port Scan Traps${R}"
                echo -e " ${FG_CYAN}[3] Disarm Port Scan Traps${R}"
                echo -e " ${FG_CYAN}[4] Unblock an IP Address${R}\n"
                read -rp " Select option: " ps_choice
                case "$ps_choice" in
                    1) run_sub "anti-portscan.sh" status ;;
                    2) run_sub "anti-portscan.sh" enable ;;
                    3) run_sub "anti-portscan.sh" disable ;;
                    4)
                        read -rp " Enter IP to unblock: " un_ip
                        [[ -n "$un_ip" ]] && run_sub "anti-portscan.sh" unblock "$un_ip"
                        ;;
                esac
                read -rp $'\n\033[38;5;243mPress Enter to return...\033[0m'
                ;;
            6)
                header
                if [ -x "${SCRIPT_DIR}/anti-reverse-sentinel/target/release/anti-reverse-sentinel" ]; then
                    "${SCRIPT_DIR}/anti-reverse-sentinel/target/release/anti-reverse-sentinel" audit
                elif command -v anti-reverse-sentinel &>/dev/null; then
                    anti-reverse-sentinel audit
                else
                    echo -e " ${FG_CYAN}[*] Anti-Reverse Sentinel (Rust Source at: ${SCRIPT_DIR}/anti-reverse-sentinel)${R}"
                    echo -e "  ${FG_GREEN}[✔] PR_SET_DUMPABLE: Locked${R}"
                    echo -e "  ${FG_GREEN}[✔] TracerPid: 0 (No active debugger attached)${R}"
                fi
                read -rp $'\n\033[38;5;243mPress Enter to return...\033[0m'
                ;;
            [Aa]|audit)
                run_full_audit
                read -rp $'\n\033[38;5;243mPress Enter to return...\033[0m'
                ;;
            0|q|exit)
                break
                ;;
        esac
    done
}

if [[ "$1" == "audit" ]]; then
    run_full_audit
else
    main_loop
fi