#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  ASTERIX OS — anti-synflood                                             ║
# ║  Active TCP SYN Flood & Denial-of-Service (DoS) Shield                  ║
# ║  Kernel SYN Cookies · Embryonic Connection Rate Limiter · Half-Open HUD ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# Usage:
#   anti-synflood status     (check kernel SYN protection & active SYN_RECVs)
#   anti-synflood enable     (apply kernel hardening & iptables rate limit)
#   anti-synflood disable    (remove firewall rate limiting rules)
#   anti-synflood monitor    (live half-open connection flood watcher)

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
    echo -e " ${FG_MAGENTA}${BOLD}[ ASTERIX ANTI-SYN FLOOD & DOS DEFENSE SHIELD ]${R}"
    echo -e " ${FG_GRAY}TCP Stack Hardening · SYN Cookies · Embryonic Rate Limiter${R}"
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
    info "Auditing Kernel TCP SYN Flood Mitigations:\n"

    # 1. tcp_syncookies
    if [ -f /proc/sys/net/ipv4/tcp_syncookies ]; then
        local sc; sc=$(cat /proc/sys/net/ipv4/tcp_syncookies)
        if [ "$sc" -eq 1 ]; then
            ok "net.ipv4.tcp_syncookies = 1       ${FG_GREEN}[ENABLED - Cryptographic Backlog Defense]${R}"
        else
            crit "net.ipv4.tcp_syncookies = $sc       ${FG_RED}[DISABLED - Vulnerable to SYN Floods]${R}"
        fi
    fi

    # 2. tcp_max_syn_backlog
    if [ -f /proc/sys/net/ipv4/tcp_max_syn_backlog ]; then
        local bl; bl=$(cat /proc/sys/net/ipv4/tcp_max_syn_backlog)
        info "net.ipv4.tcp_max_syn_backlog = ${bl}  (Queue capacity for half-open handshakes)"
    fi

    # 3. tcp_synack_retries
    if [ -f /proc/sys/net/ipv4/tcp_synack_retries ]; then
        local ret; ret=$(cat /proc/sys/net/ipv4/tcp_synack_retries)
        info "net.ipv4.tcp_synack_retries = ${ret}   (Drops dead SYN connections faster)"
    fi

    echo ""
    info "Current Live TCP Half-Open Connection Count (SYN_RECV):"
    local syn_recv=0
    if command -v ss &>/dev/null; then
        syn_recv=$(ss -t state syn-recv 2>/dev/null | tail -n +2 | wc -l)
    elif command -v netstat &>/dev/null; then
        syn_recv=$(netstat -tn 2>/dev/null | grep -c "SYN_RECV" || echo 0)
    fi

    if (( syn_recv > 50 )); then
        crit "ACTIVE SYN FLOOD ALERT! ${syn_recv} half-open SYN_RECV sockets pending!"
    else
        ok "SYN Backlog Normal: ${syn_recv} half-open connections."
    fi

    echo ""
    info "Checking Firewall Anti-SYN Rules:"
    if command -v iptables &>/dev/null; then
        if run_cmd iptables -L -n 2>/dev/null | grep -q "SYN_FLOOD_SHIELD"; then
            ok "IPTABLES SYN Flood Shield: ${FG_GREEN}ACTIVE${R}"
        else
            warn "IPTABLES SYN Flood Shield: ${FG_YELLOW}INACTIVE (Run 'anti-synflood enable')${R}"
        fi
    fi
    echo ""
}

cmd_enable() {
    header
    info "Activating Kernel TCP Hardening & SYN Cookie Defense..."

    # Sysctl kernel adjustments
    run_cmd sysctl -w net.ipv4.tcp_syncookies=1 2>/dev/null || true
    run_cmd sysctl -w net.ipv4.tcp_max_syn_backlog=4096 2>/dev/null || true
    run_cmd sysctl -w net.ipv4.tcp_synack_retries=2 2>/dev/null || true
    run_cmd sysctl -w net.ipv4.tcp_rfc1337=1 2>/dev/null || true
    run_cmd sysctl -w net.ipv4.tcp_fin_timeout=15 2>/dev/null || true

    ok "Kernel sysctls configured for SYN flood resilience."

    # Firewall rate-limiting rules
    if command -v iptables &>/dev/null; then
        info "Injecting iptables rate limiting chain..."
        # Create chain if not present
        run_cmd iptables -N SYN_FLOOD_SHIELD 2>/dev/null || true
        run_cmd iptables -F SYN_FLOOD_SHIELD 2>/dev/null || true

        # Limit incoming SYN handshakes to 50/sec with burst 100
        run_cmd iptables -A SYN_FLOOD_SHIELD -m limit --limit 50/s --limit-burst 100 -j RETURN
        run_cmd iptables -A SYN_FLOOD_SHIELD -j DROP

        # Hook into INPUT chain for TCP SYN
        run_cmd iptables -D INPUT -p tcp --syn -j SYN_FLOOD_SHIELD 2>/dev/null || true
        run_cmd iptables -I INPUT 1 -p tcp --syn -j SYN_FLOOD_SHIELD 2>/dev/null || true

        # Drop invalid TCP flags
        run_cmd iptables -I INPUT 2 -p tcp --tcp-flags ALL NONE -j DROP 2>/dev/null || true
        run_cmd iptables -I INPUT 3 -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP 2>/dev/null || true

        ok "Iptables rate limiter hooked: 50 SYN/sec limit with 100 burst threshold."
    fi

    echo ""
    ok "ANTI-SYN FLOOD DEFENSE FULLY ENGAGED!"
    echo ""
}

cmd_disable() {
    header
    info "Deactivating firewall anti-SYN rules..."

    if command -v iptables &>/dev/null; then
        run_cmd iptables -D INPUT -p tcp --syn -j SYN_FLOOD_SHIELD 2>/dev/null || true
        run_cmd iptables -F SYN_FLOOD_SHIELD 2>/dev/null || true
        run_cmd iptables -X SYN_FLOOD_SHIELD 2>/dev/null || true
        ok "Iptables SYN_FLOOD_SHIELD chain flushed and detached."
    fi
    echo ""
}

cmd_monitor() {
    header
    info "Starting Live TCP SYN_RECV Monitor (Press Ctrl+C to exit)..."
    echo ""

    local sweep=0
    while true; do
        sweep=$(( sweep + 1 ))
        local syn_recv=0
        if command -v ss &>/dev/null; then
            syn_recv=$(ss -t state syn-recv 2>/dev/null | tail -n +2 | wc -l)
        fi

        local col="$FG_GREEN"
        local status="NORMAL"
        if (( syn_recv > 50 )); then
            col="$FG_RED"
            status="CRITICAL FLOOD DETECTED"
            echo -e "\a"
        elif (( syn_recv > 20 )); then
            col="$FG_YELLOW"
            status="ELEVATED EMBRYONIC BACKLOG"
        fi

        printf "\r  ${FG_CYAN}[TICK #%d]${R} ${FG_WHITE}SYN_RECV Backlog:${R} ${col}%3d sockets${R} | ${FG_WHITE}Status:${R} ${col}%s${R}   " \
            "$sweep" "$syn_recv" "$status"
        sleep 1
    done
}

CMD="${1:-}"
case "$CMD" in
    status)  cmd_status ;;
    enable)  cmd_enable ;;
    disable) cmd_disable ;;
    monitor) cmd_monitor ;;
    help|--help|-h|"")
        header
        echo -e " ${FG_WHITE}USAGE:${R}"
        echo -e "   ${FG_CYAN}anti-synflood status${R}   Audit kernel SYN cookies & live half-open sockets"
        echo -e "   ${FG_CYAN}anti-synflood enable${R}   Harden TCP stack & hook iptables rate limiter"
        echo -e "   ${FG_CYAN}anti-synflood disable${R}  Unhook firewall rate limiting rules"
        echo -e "   ${FG_CYAN}anti-synflood monitor${R}  Real-time live half-open socket flood monitor"
        echo ""
        ;;
    *)
        echo -e "${FG_RED}[!] Unknown command: $CMD${R}  (use: anti-synflood help)"
        exit 1
        ;;
esac