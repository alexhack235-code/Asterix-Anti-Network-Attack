#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  ASTERIX OS — anti-portscan                                             ║
# ║  Automated Port Scan Detection & Reconnaissance Adversary Blocker       ║
# ║  Stealth Sweep Traps · Dynamic IP Quarantine Blocklist · iptables Recent║
# ╚══════════════════════════════════════════════════════════════════════════╝
# Usage:
#   anti-portscan status         (view blocked scanning hosts & trap status)
#   anti-portscan enable         (arm port scan detection & auto-blocker)
#   anti-portscan disable        (deactivate port scan blocker)
#   anti-portscan unblock <ip>   (release an IP from quarantine)

R='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'
FG_DARKGRAY='\033[38;5;237m'; FG_GRAY='\033[38;5;243m'
FG_GREEN='\033[38;5;46m';     FG_DKGREEN='\033[38;5;22m'
FG_CYAN='\033[38;5;51m'
FG_MAGENTA='\033[38;5;201m';  FG_PURPLE='\033[38;5;141m'
FG_RED='\033[38;5;196m';      FG_ORANGE='\033[38;5;208m'
FG_YELLOW='\033[38;5;220m';   FG_WHITE='\033[38;5;231m'

hrule() {
    local c="${1:-─}" col="${2:-$FG_CYAN}"
    local w; w=$(tput cols 2>/dev/null || echo 72)
    echo -e "${col}$(printf "%${w}s" | tr ' ' "$c")${R}"
}

header() {
    clear
    hrule "═" "$FG_MAGENTA"
    echo -e " ${FG_MAGENTA}${BOLD}[ ASTERIX ANTI-PORTSCAN & RECONNAISSANCE DEFENDER ]${R}"
    echo -e " ${FG_GRAY}Scan Sweep Detection · Dynamic IP Quarantine · Automated Drop${R}"
    hrule "═" "$FG_MAGENTA"
    echo ""
}

ok()   { echo -e "  ${FG_GREEN}[✔]${R} $*"; }
warn() { echo -e "  ${FG_YELLOW}[!]${R} $*"; }
crit() { echo -e "  ${FG_RED}[✖]${R} $*"; }
info() { echo -e "  ${FG_CYAN}[*]${R} $*"; }

run_cmd() {
    if [ "$(id -u)" -ne 0 ] && command -v sudo &>/dev/null; then
        sudo "$@"
    else
        "$@"
    fi
}

cmd_status() {
    header
    info "Port Scan Defense Status:"

    local active=0
    if command -v iptables &>/dev/null; then
        if run_cmd iptables -L -n 2>/dev/null | grep -q "PORTSCAN_BLOCK"; then
            active=1
            ok "Firewall Port Scan Traps: ${FG_GREEN}ARMED & ACTIVE${R}"
        else
            warn "Firewall Port Scan Traps: ${FG_YELLOW}DISARMED (Run 'anti-portscan enable')${R}"
        fi
    fi

    echo ""
    info "Currently Quarantined Scanning IP Addresses:"
    if [ -f /proc/net/xt_recent/PORTSCAN ]; then
        local count; count=$(wc -l < /proc/net/xt_recent/PORTSCAN 2>/dev/null || echo 0)
        if (( count > 0 )); then
            crit "Adversary IPs currently locked in quarantine: ${count}"
            awk '{print "    " $1}' /proc/net/xt_recent/PORTSCAN | head -15
        else
            ok "Quarantine list is empty. No active hostile sweeps recorded."
        fi
    else
        ok "No active quarantine list file."
    fi
    echo ""
}

cmd_enable() {
    header
    info "Arming automated port scan traps and dynamic IP quarantine..."

    if ! command -v iptables &>/dev/null; then
        crit "iptables utility not found on host."
        return 1
    fi

    # Create PORTSCAN_BLOCK chain
    run_cmd iptables -N PORTSCAN_BLOCK 2>/dev/null || true
    run_cmd iptables -F PORTSCAN_BLOCK 2>/dev/null || true

    # Rule 1: If IP is already in PORTSCAN blocklist, drop it immediately
    run_cmd iptables -A PORTSCAN_BLOCK -m recent --name PORTSCAN --rcheck --seconds 1800 -j DROP

    # Rule 2: Trap stealth scans (FIN, NULL, XMAS) and add to blocklist
    run_cmd iptables -A PORTSCAN_BLOCK -p tcp --tcp-flags ALL NONE -m recent --name PORTSCAN --set -j DROP
    run_cmd iptables -A PORTSCAN_BLOCK -p tcp --tcp-flags ALL ALL -m recent --name PORTSCAN --set -j DROP
    run_cmd iptables -A PORTSCAN_BLOCK -p tcp --tcp-flags ALL FIN,URG,PSH -m recent --name PORTSCAN --set -j DROP
    run_cmd iptables -A PORTSCAN_BLOCK -p tcp --tcp-flags SYN,RST SYN,RST -m recent --name PORTSCAN --set -j DROP

    # Rule 3: Trap probes on decoy port 31337
    run_cmd iptables -A PORTSCAN_BLOCK -p tcp --dport 31337 -m recent --name PORTSCAN --set -j DROP

    # Hook chain into INPUT
    run_cmd iptables -D INPUT -j PORTSCAN_BLOCK 2>/dev/null || true
    run_cmd iptables -I INPUT 1 -j PORTSCAN_BLOCK 2>/dev/null || true

    ok "Port scan defense armed!"
    ok "Stealth scans (NULL, XMAS, FIN) and decoy probes will trigger an immediate 30-minute IP ban."
    echo ""
}

cmd_disable() {
    header
    info "Disarming port scan detection rules..."
    if command -v iptables &>/dev/null; then
        run_cmd iptables -D INPUT -j PORTSCAN_BLOCK 2>/dev/null || true
        run_cmd iptables -F PORTSCAN_BLOCK 2>/dev/null || true
        run_cmd iptables -X PORTSCAN_BLOCK 2>/dev/null || true
        ok "PORTSCAN_BLOCK chain detached and flushed."
    fi
    echo ""
}

cmd_unblock() {
    local target_ip="$1"
    if [[ -z "$target_ip" ]]; then
        echo "Usage: anti-portscan unblock <ip_address>"
        return 1
    fi
    header
    info "Releasing ${target_ip} from quarantine..."
    if [ -f /proc/net/xt_recent/PORTSCAN ]; then
        run_cmd bash -c "echo -${target_ip} > /proc/net/xt_recent/PORTSCAN" 2>/dev/null || true
        ok "Removed ${target_ip} from PORTSCAN blocklist."
    else
        info "Quarantine list not found or already cleared."
    fi
    echo ""
}

CMD="${1:-}"
ARG="${2:-}"

case "$CMD" in
    status)  cmd_status ;;
    enable)  cmd_enable ;;
    disable) cmd_disable ;;
    unblock) cmd_unblock "$ARG" ;;
    help|--help|-h|"")
        header
        echo -e " ${FG_WHITE}USAGE:${R}"
        echo -e "   ${FG_CYAN}anti-portscan status${R}        View blocked scanning IPs & trap configuration"
        echo -e "   ${FG_CYAN}anti-portscan enable${R}        Arm firewall traps & dynamic 30-min auto-quarantine"
        echo -e "   ${FG_CYAN}anti-portscan disable${R}       Disarm port scan traps"
        echo -e "   ${FG_CYAN}anti-portscan unblock <ip>${R}   Release an IP address from quarantine"
        echo ""
        ;;
    *)
        echo -e "${FG_RED}[!] Unknown command: $CMD${R}  (use: anti-portscan help)"
        exit 1
        ;;
esac