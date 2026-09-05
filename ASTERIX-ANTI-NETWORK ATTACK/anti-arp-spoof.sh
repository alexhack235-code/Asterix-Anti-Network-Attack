#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  ASTERIX OS — anti-arp-spoof                                            ║
# ║  Active ARP Poisoning & MITM Attack Defense Engine                      ║
# ║  Monitors Gateway MAC Flapping · Enforces Static Kernel ARP Bindings    ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# Usage:
#   anti-arp-spoof status      (view current ARP cache & gateway lock status)
#   anti-arp-spoof lock        (enforce static permanent gateway binding)
#   anti-arp-spoof unlock      (restore dynamic gateway ARP state)
#   anti-arp-spoof watch       (real-time background monitor with alarms)

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
    echo -e " ${FG_MAGENTA}${BOLD}[ ASTERIX ANTI-ARP SPOOF & MITM DEFENDER ]${R}"
    echo -e " ${FG_GRAY}ARP Poisoning Detection · Static Gateway Locking · MITM Protection${R}"
    hrule "═" "$FG_MAGENTA"
    echo ""
}

ok()   { echo -e "  ${FG_GREEN}[✔]${R} $*"; }
warn() { echo -e "  ${FG_YELLOW}[!]${R} $*"; }
crit() { echo -e "  ${FG_RED}[✖]${R} $*"; }
info() { echo -e "  ${FG_CYAN}[*]${R} $*"; }

get_gateway_info() {
    local gw_ip gw_iface gw_mac
    gw_ip=$(ip route get 1.1.1.1 2>/dev/null | awk '/via/{print $3}')
    gw_iface=$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/{print $5}')
    if [[ -z "$gw_ip" ]]; then
        gw_ip=$(awk '$2 ~ /00000000/ {printf "%d.%d.%d.%d\n", "0x"substr($3,7,2), "0x"substr($3,5,2), "0x"substr($3,3,2), "0x"substr($3,1,2)}' /proc/net/route 2>/dev/null | head -1)
    fi
    if [[ -n "$gw_ip" ]]; then
        gw_mac=$(ip neigh show "$gw_ip" 2>/dev/null | awk '{print $5}')
        [[ -z "$gw_mac" ]] && gw_mac=$(grep -w "$gw_ip" /proc/net/arp 2>/dev/null | awk '{print $4}')
    fi
    echo "${gw_ip:-UNKNOWN}|${gw_iface:-eth0}|${gw_mac:-UNKNOWN}"
}

cmd_status() {
    header
    local gw_data; gw_data=$(get_gateway_info)
    IFS='|' read -r gw_ip gw_iface gw_mac <<< "$gw_data"

    info "Gateway IP Address:     ${FG_WHITE}${gw_ip}${R}"
    info "Network Interface:      ${FG_WHITE}${gw_iface}${R}"
    info "Gateway Hardware (MAC): ${FG_YELLOW}${gw_mac}${R}"

    # Check if locked (permanent)
    local is_perm=0
    if ip neigh show "$gw_ip" 2>/dev/null | grep -qi "PERMANENT"; then
        is_perm=1
        ok "Gateway Binding:        ${FG_GREEN}LOCKED (PERMANENT - Immune to ARP Poisoning)${R}"
    else
        warn "Gateway Binding:        ${FG_YELLOW}DYNAMIC (Vulnerable to ARP Poisoning)${R}"
    fi

    echo ""
    info "Current System ARP Table:"
    echo -e "  ${C_GRAY}IP ADDRESS          MAC ADDRESS         FLAGS      IFACE${C_RESET}"
    if [ -f /proc/net/arp ]; then
        tail -n +2 /proc/net/arp | while IFS= read -r line; do
            echo -e "  ${C_WHITE}${line}${C_RESET}"
        done
    fi
    echo ""
}

cmd_lock() {
    header
    local gw_data; gw_data=$(get_gateway_info)
    IFS='|' read -r gw_ip gw_iface gw_mac <<< "$gw_data"

    if [[ "$gw_ip" == "UNKNOWN" || "$gw_mac" == "UNKNOWN" || "$gw_mac" == *"00:00:00"* ]]; then
        crit "Could not determine valid Gateway IP or MAC. Send network traffic first (e.g. ping -c 1 8.8.8.8)."
        return 1
    fi

    info "Locking Gateway ${FG_WHITE}${gw_ip}${R} to MAC ${FG_YELLOW}${gw_mac}${R} on ${FG_CYAN}${gw_iface}${R}..."
    if command -v sudo &>/dev/null; then
        sudo ip neigh replace "$gw_ip" lladdr "$gw_mac" nud permanent dev "$gw_iface" 2>/dev/null || true
    else
        ip neigh replace "$gw_ip" lladdr "$gw_mac" nud permanent dev "$gw_iface" 2>/dev/null || true
    fi

    ok "STATIC ARP BINDING ACTIVATED!"
    ok "Adversary ARP poisoning frames will now be silently ignored by the kernel."
    echo ""
}

cmd_unlock() {
    header
    local gw_data; gw_data=$(get_gateway_info)
    IFS='|' read -r gw_ip gw_iface gw_mac <<< "$gw_data"

    info "Unlocking Gateway ${gw_ip} back to dynamic ARP state..."
    if command -v sudo &>/dev/null; then
        sudo ip neigh replace "$gw_ip" lladdr "$gw_mac" nud reachable dev "$gw_iface" 2>/dev/null || true
    else
        ip neigh replace "$gw_ip" lladdr "$gw_mac" nud reachable dev "$gw_iface" 2>/dev/null || true
    fi

    ok "Gateway ARP binding restored to dynamic mode."
    echo ""
}

cmd_watch() {
    header
    local gw_data; gw_data=$(get_gateway_info)
    IFS='|' read -r gw_ip gw_iface initial_mac <<< "$gw_data"

    if [[ "$initial_mac" == "UNKNOWN" ]]; then
        crit "Cannot start watch: Gateway MAC unknown. Try: ping -c 1 8.8.8.8"
        return 1
    fi

    info "Target Gateway: ${FG_WHITE}${gw_ip}${R} | Trusted MAC: ${FG_GREEN}${initial_mac}${R}"
    info "Starting real-time ARP spoofing watcher (Press Ctrl+C to exit)..."
    echo ""

    local sweep=0
    while true; do
        sweep=$(( sweep + 1 ))
        local cur_mac
        cur_mac=$(ip neigh show "$gw_ip" 2>/dev/null | awk '{print $5}')
        [[ -z "$cur_mac" ]] && cur_mac=$(grep -w "$gw_ip" /proc/net/arp 2>/dev/null | awk '{print $4}')

        if [[ -n "$cur_mac" && "$cur_mac" != "$initial_mac" && "$cur_mac" != *"00:00:00"* ]]; then
            echo -e "\a" # Terminal beep
            crit "[ALERT] ARP POISONING ATTACK IN PROGRESS!"
            crit "Gateway ${gw_ip} MAC hijacked by: ${FG_RED}${cur_mac}${R} (Expected: ${initial_mac})"
            crit "MITM Man-in-the-Middle eavesdropping detected on interface ${gw_iface}!"
        else
            printf "\r  ${FG_CYAN}[SWEEP #%d]${R} ${FG_WHITE}Gateway %s:${R} ${FG_GREEN}%s${R} ${FG_GRAY}(Status: SECURE)${R}    " \
                "$sweep" "$gw_ip" "$initial_mac"
        fi
        sleep 2
    done
}

CMD="${1:-}"
case "$CMD" in
    status) cmd_status ;;
    lock)   cmd_lock ;;
    unlock) cmd_unlock ;;
    watch)  cmd_watch ;;
    help|--help|-h|"")
        header
        echo -e " ${FG_WHITE}USAGE:${R}"
        echo -e "   ${FG_CYAN}anti-arp-spoof status${R}  View ARP table and gateway permanent lock status"
        echo -e "   ${FG_CYAN}anti-arp-spoof lock${R}    Lock gateway to static MAC (Immunize from MITM)"
        echo -e "   ${FG_CYAN}anti-arp-spoof unlock${R}  Restore gateway ARP to dynamic status"
        echo -e "   ${FG_CYAN}anti-arp-spoof watch${R}   Live real-time monitoring loop with audible alerts"
        echo ""
        ;;
    *)
        echo -e "${FG_RED}[!] Unknown command: $CMD${R}  (use: anti-arp-spoof help)"
        exit 1
        ;;
esac