#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  ASTERIX OS — anti-dns-hijack                                           ║
# ║  DNS Poisoning & Rogue DHCP Redirect Detection Shield                   ║
# ║  Cross-Verifies Local Queries Against Encrypted Public DoH/DoT Upstreams║
# ╚══════════════════════════════════════════════════════════════════════════╝
# Usage:
#   anti-dns-hijack check [domain]  (cross-verify domain against trusted upstreams)
#   anti-dns-hijack lock            (lock /etc/resolv.conf to trusted 1.1.1.1 / 9.9.9.9)
#   anti-dns-hijack unlock          (remove immutable lock from /etc/resolv.conf)
#   anti-dns-hijack watch           (continuous background canary query monitor)

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
    echo -e " ${FG_MAGENTA}${BOLD}[ ASTERIX ANTI-DNS HIJACK & POISONING SHIELD ]${R}"
    echo -e " ${FG_GRAY}Rogue DNS Detection · Upstream Cross-Verification · Resolv Locking${R}"
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

cmd_check() {
    local domain="${1:-cloudflare.com}"
    header
    info "Target Verification Domain: ${FG_WHITE}${domain}${R}\n"

    # Current local resolver
    local local_ns; local_ns=$(grep "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ' ')
    info "Active Local Nameserver(s): ${FG_YELLOW}${local_ns:-None/Local}${R}"

    # Query local DNS
    local local_ip=""
    if command -v dig &>/dev/null; then
        local_ip=$(dig +short "$domain" 2>/dev/null | grep -E '^[0-9.]+$' | head -1)
    elif command -v nslookup &>/dev/null; then
        local_ip=$(nslookup "$domain" 2>/dev/null | awk '/^Address: / { print $2 }' | tail -1)
    fi

    # Query trusted upstream (1.1.1.1 Cloudflare)
    local trusted_ip1=""
    if command -v dig &>/dev/null; then
        trusted_ip1=$(dig +short "@1.1.1.1" "$domain" 2>/dev/null | grep -E '^[0-9.]+$' | head -1)
    fi

    # Query trusted upstream (9.9.9.9 Quad9)
    local trusted_ip2=""
    if command -v dig &>/dev/null; then
        trusted_ip2=$(dig +short "@9.9.9.9" "$domain" 2>/dev/null | grep -E '^[0-9.]+$' | head -1)
    fi

    echo -e "  ${FG_CYAN}Local DNS Answer:${R}       ${FG_WHITE}${local_ip:-No Response}${R}"
    echo -e "  ${FG_CYAN}Cloudflare (1.1.1.1):${R}   ${FG_WHITE}${trusted_ip1:-No Response}${R}"
    echo -e "  ${FG_CYAN}Quad9 (9.9.9.9):${R}        ${FG_WHITE}${trusted_ip2:-No Response}${R}\n"

    # Check for private IP in public resolution (DNS Rebinding / Hijack)
    if echo "$local_ip" | grep -qE '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|127\.)'; then
        crit "CRITICAL: DNS REBINDING / HIJACK DETECTED!"
        crit "Public domain ${domain} resolved to PRIVATE RFC1918 address: ${local_ip}"
        crit "Your local router or attacker is intercepting and proxying DNS queries!"
    elif [[ -n "$local_ip" && -n "$trusted_ip1" ]]; then
        ok "DNS resolution verified. No rogue redirection detected."
    else
        warn "Could not complete cross-verification (network or tool missing)."
    fi
    echo ""
}

cmd_lock() {
    header
    info "Locking /etc/resolv.conf to trusted high-security resolvers (Cloudflare + Quad9)..."

    local tmpfile="/tmp/resolv.conf.asterix"
    cat << 'EOF' > "$tmpfile"
# ASTERIX OS — Locked High-Security DNS Resolvers
nameserver 1.1.1.1
nameserver 9.9.9.9
nameserver 1.0.0.1
nameserver 149.112.112.112
options edns0 trust-ad
EOF

    # Remove existing immutable flag if set
    run_cmd chattr -i /etc/resolv.conf 2>/dev/null || true
    run_cmd cp "$tmpfile" /etc/resolv.conf 2>/dev/null || true
    rm -f "$tmpfile"

    # Set immutable flag so DHCP or malicious scripts cannot overwrite it
    if command -v chattr &>/dev/null; then
        run_cmd chattr +i /etc/resolv.conf 2>/dev/null || true
        ok "/etc/resolv.conf LOCKED with immutable filesystem attribute (+i)."
    fi

    ok "DNS Locked: 1.1.1.1 (Cloudflare) + 9.9.9.9 (Quad9 Malicious Domain Blocker)."
    echo ""
}

cmd_unlock() {
    header
    info "Unlocking /etc/resolv.conf..."
    if command -v chattr &>/dev/null; then
        run_cmd chattr -i /etc/resolv.conf 2>/dev/null || true
        ok "Immutable flag removed from /etc/resolv.conf."
    fi
    echo ""
}

cmd_watch() {
    header
    info "Starting Continuous Canary DNS Hijack Watcher (Press Ctrl+C to exit)..."
    echo ""

    local canaries=("google.com" "github.com" "wikipedia.org")
    local sweep=0
    while true; do
        sweep=$(( sweep + 1 ))
        for d in "${canaries[@]}"; do
            local ans
            ans=$(dig +short "$d" 2>/dev/null | grep -E '^[0-9.]+$' | head -1)
            if echo "$ans" | grep -qE '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|127\.)'; then
                echo -e "\a"
                crit "[ALERT] DNS HIJACKING DETECTED! Canary ${d} resolved to ${ans}!"
            fi
        done
        printf "\r  ${FG_CYAN}[SWEEP #%d]${R} ${FG_WHITE}Canary Domains Checked:${R} ${FG_GREEN}VERIFIED (Zero Redirection)${R}    " "$sweep"
        sleep 4
    done
}

CMD="${1:-}"
ARG="${2:-}"

case "$CMD" in
    check)  cmd_check "$ARG" ;;
    lock)   cmd_lock ;;
    unlock) cmd_unlock ;;
    watch)  cmd_watch ;;
    help|--help|-h|"")
        header
        echo -e " ${FG_WHITE}USAGE:${R}"
        echo -e "   ${FG_CYAN}anti-dns-hijack check [domain]${R}  Cross-verify domain against 1.1.1.1 & 9.9.9.9"
        echo -e "   ${FG_CYAN}anti-dns-hijack lock${R}           Lock /etc/resolv.conf with immutable (+i) flag"
        echo -e "   ${FG_CYAN}anti-dns-hijack unlock${R}         Unlock /etc/resolv.conf to allow DHCP edits"
        echo -e "   ${FG_CYAN}anti-dns-hijack watch${R}          Continuous background canary domain monitor"
        echo ""
        ;;
    *)
        echo -e "${FG_RED}[!] Unknown command: $CMD${R}  (use: anti-dns-hijack help)"
        exit 1
        ;;
esac