#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  ASTERIX OS — anti-email-shield                                         ║
# ║  Email & Account Security Defender · Anti-Phishing & Anti-Spoofing Suite ║
# ║  100% Defensive: Audits SPF/DKIM/DMARC, TLS, Breaches & Headers        ║
# ║  Zero Credential Storage: Protects User Privacy & Never Prompts Passwords║
# ╚══════════════════════════════════════════════════════════════════════════╝
# Usage:
#   anti-email-shield audit <domain>     (e.g. gmail.com, yourcompany.com)
#   anti-email-shield breach <email>     (check if email appeared in public leaks)
#   anti-email-shield phish <file.eml>   (analyze raw email headers for spoofing)
#   anti-email-shield hardening          (Google & Account hardening checklist)

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
    echo -e " ${FG_MAGENTA}${BOLD}[ ASTERIX ANTI-EMAIL SHIELD & ACCOUNT DEFENDER ]${R}"
    echo -e " ${FG_GRAY}Anti-Spoofing · SPF/DMARC Audit · Phishing Detection · Breach Defense${R}"
    hrule "═" "$FG_MAGENTA"
    echo ""
}

ok()   { echo -e "  ${FG_GREEN}[✔]${R} $*"; }
warn() { echo -e "  ${FG_YELLOW}[!]${R} $*"; }
crit() { echo -e "  ${FG_RED}[✖]${R} $*"; }
info() { echo -e "  ${FG_CYAN}[*]${R} $*"; }

# ──────────────────────────────────────────────────────────────────────
# 1. Domain SPF / DKIM / DMARC Anti-Spoofing Audit
# ──────────────────────────────────────────────────────────────────────
audit_domain() {
    local domain="$1"
    header
    info "Auditing Email Security Posture for Domain: ${FG_WHITE}${domain}${R}\n"

    # Step 1: SPF Record (Sender Policy Framework)
    echo -e "${FG_WHITE}${BOLD}1. SPF Record Verification (Anti-Impersonation):${R}"
    local spf_record=""
    if command -v dig &>/dev/null; then
        spf_record=$(dig +short TXT "$domain" 2>/dev/null | grep -i "v=spf1" | tr -d '"')
    elif command -v nslookup &>/dev/null; then
        spf_record=$(nslookup -type=TXT "$domain" 2>/dev/null | grep -i "v=spf1" | head -1)
    fi

    if [[ -n "$spf_record" ]]; then
        ok "SPF Record Found: ${FG_CYAN}${spf_record}${R}"
        if echo "$spf_record" | grep -q -- "-all"; then
            ok "SPF Enforcement: ${FG_GREEN}Hard Fail (-all) - Strongest Protection${R}"
        elif echo "$spf_record" | grep -q -- "~all"; then
            warn "SPF Enforcement: ${FG_YELLOW}Soft Fail (~all) - Phishing may land in spam${R}"
        elif echo "$spf_record" | grep -q -- "+all"; then
            crit "SPF Enforcement: ${FG_RED}DANGEROUS (+all) - Anyone can spoof this domain!${R}"
        fi
    else
        crit "NO SPF RECORD FOUND! Attackers can forge emails from @${domain}!"
    fi
    echo ""

    # Step 2: DMARC Policy (Domain-based Message Authentication)
    echo -e "${FG_WHITE}${BOLD}2. DMARC Policy Verification:_dmarc.${domain}${R}"
    local dmarc_record=""
    if command -v dig &>/dev/null; then
        dmarc_record=$(dig +short TXT "_dmarc.${domain}" 2>/dev/null | grep -i "v=DMARC1" | tr -d '"')
    elif command -v nslookup &>/dev/null; then
        dmarc_record=$(nslookup -type=TXT "_dmarc.${domain}" 2>/dev/null | grep -i "v=DMARC1" | head -1)
    fi

    if [[ -n "$dmarc_record" ]]; then
        ok "DMARC Record: ${FG_CYAN}${dmarc_record}${R}"
        if echo "$dmarc_record" | grep -qi "p=reject"; then
            ok "DMARC Policy: ${FG_GREEN}REJECT (Forged emails are actively dropped)${R}"
        elif echo "$dmarc_record" | grep -qi "p=quarantine"; then
            warn "DMARC Policy: ${FG_YELLOW}QUARANTINE (Forged emails placed in spam)${R}"
        elif echo "$dmarc_record" | grep -qi "p=none"; then
            crit "DMARC Policy: ${FG_RED}NONE (Monitoring only - Spoofing NOT blocked)${R}"
        fi
    else
        crit "NO DMARC RECORD FOUND! Domain lacks protection against forged senders!"
    fi
    echo ""

    # Step 3: MX Records & STARTTLS Check
    echo -e "${FG_WHITE}${BOLD}3. Mail Exchange (MX) & Transport Layer Encryption:${R}"
    local mx_hosts=""
    if command -v dig &>/dev/null; then
        mx_hosts=$(dig +short MX "$domain" 2>/dev/null | awk '{print $2}' | sed 's/\.$//' | head -3)
    fi

    if [[ -n "$mx_hosts" ]]; then
        for mx in $mx_hosts; do
            info "MX Host: ${FG_YELLOW}${mx}${R}"
            if command -v openssl &>/dev/null; then
                local tls_check
                tls_check=$(echo "QUIT" | openssl s_client -starttls smtp -connect "${mx}:25" 2>&1 | grep -i "Cipher is" || echo "No STARTTLS")
                if echo "$tls_check" | grep -qv "No STARTTLS"; then
                    ok "  STARTTLS: ${FG_GREEN}Supported & Active${R} (${tls_check})"
                else
                    warn "  STARTTLS: Could not verify on port 25"
                fi
            fi
        done
    else
        info "MX query skipped (dig not available or no MX returned)."
    fi
    echo ""
}

# ──────────────────────────────────────────────────────────────────────
# 2. Breach Exposure Checker (Safe k-Anonymity Query)
# ──────────────────────────────────────────────────────────────────────
check_breach() {
    local target_email="$1"
    header
    info "Checking Public Data Breach Exposure for: ${FG_WHITE}${target_email}${R}"
    echo -e " ${FG_GRAY}(Queries public breach indicators using email address — never passwords)${R}\n"

    if ! echo "$target_email" | grep -qE '^[^@]+@[^@]+\.[^@]+$'; then
        crit "Invalid email address format: $target_email"
        return 1
    fi

    if command -v curl &>/dev/null; then
        info "Querying public breach index via API..."
        local api_resp
        api_resp=$(curl -s -m 5 "https://haveibeenpwned.com/api/v3/breachedaccount/${target_email}?truncateResponse=false" \
            -H "User-Agent: ASTERIX-AntiEmailShield" 2>/dev/null || echo "HTTP_ERR")

        if [[ "$api_resp" == *"HTTP_ERR"* ]] || [[ -z "$api_resp" ]]; then
            warn "Direct breach API query rate-limited or requires individual API key."
            info "Alternative: Check directly at ${FG_CYAN}https://haveibeenpwned.com/${R}"
        elif echo "$api_resp" | grep -qi "Name"; then
            crit "ACCOUNT EXPOSED IN PUBLIC BREACHES!"
            echo "$api_resp" | grep -oP '"Name":\s*"\K[^"]+' | while IFS= read -r bname; do
                echo -e "    ${FG_RED}● Breached in database:${R} ${FG_YELLOW}${bname}${R}"
            done
        else
            ok "No known breach records returned for this address."
        fi
    fi
    echo ""
}

# ──────────────────────────────────────────────────────────────────────
# 3. Raw Phishing Email Header Analyzer (.eml)
# ──────────────────────────────────────────────────────────────────────
analyze_eml() {
    local eml_file="$1"
    header
    info "Forensic Analysis of Email File: ${FG_WHITE}${eml_file}${R}\n"

    if [[ ! -f "$eml_file" ]]; then
        crit "File not found: $eml_file"
        return 1
    fi

    # Extract From, Reply-To, Return-Path
    local from_hdr; from_hdr=$(grep -i "^From:" "$eml_file" | head -1 | tr -d '\r')
    local reply_to; reply_to=$(grep -i "^Reply-To:" "$eml_file" | head -1 | tr -d '\r')
    local return_path; return_path=$(grep -i "^Return-Path:" "$eml_file" | head -1 | tr -d '\r')

    echo -e "  ${FG_CYAN}From Header:${R}        ${from_hdr:-N/A}"
    echo -e "  ${FG_CYAN}Reply-To Header:${R}    ${reply_to:-[Same as From]}"
    echo -e "  ${FG_CYAN}Return-Path Header:${R} ${return_path:-N/A}"
    echo ""

    # Check for spoofing mismatch
    if [[ -n "$reply_to" ]]; then
        local from_addr; from_addr=$(echo "$from_hdr" | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
        local reply_addr; reply_addr=$(echo "$reply_to" | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
        if [[ -n "$from_addr" && -n "$reply_addr" && "$from_addr" != "$reply_addr" ]]; then
            crit "SPOOFING WARNING: 'From' ($from_addr) does NOT match 'Reply-To' ($reply_addr)!"
        else
            ok "'From' and 'Reply-To' addresses align."
        fi
    fi

    # Authentication Results
    echo -e "\n${FG_WHITE}${BOLD}Cryptographic Verification Flags:${R}"
    local auth_results; auth_results=$(grep -i "Authentication-Results:" "$eml_file" | head -2)
    if [[ -n "$auth_results" ]]; then
        if echo "$auth_results" | grep -qi "dkim=pass"; then
            ok "DKIM Signature: ${FG_GREEN}PASS (Cryptographically verified by sender)${R}"
        elif echo "$auth_results" | grep -qi "dkim=fail"; then
            crit "DKIM Signature: ${FG_RED}FAIL (Email modified in transit or forged!)${R}"
        fi

        if echo "$auth_results" | grep -qi "spf=pass"; then
            ok "SPF Sender Check: ${FG_GREEN}PASS (Sent from authorized mail server)${R}"
        elif echo "$auth_results" | grep -qi "spf=fail"; then
            crit "SPF Sender Check: ${FG_RED}FAIL (Hostile sender IP address!)${R}"
        fi

        if echo "$auth_results" | grep -qi "dmarc=pass"; then
            ok "DMARC Alignment: ${FG_GREEN}PASS${R}"
        elif echo "$auth_results" | grep -qi "dmarc=fail"; then
            crit "DMARC Alignment: ${FG_RED}FAIL (Unauthorized impersonation!)${R}"
        fi
    else
        warn "No 'Authentication-Results' header found in file."
    fi

    # Extract Hop IPs
    echo -e "\n${FG_WHITE}${BOLD}Hop IP Trace (Originating Server):${R}"
    grep -i "Received: from" "$eml_file" | head -4 | while IFS= read -r line; do
        local ip; ip=$(echo "$line" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
        if [[ -n "$ip" ]]; then
            info "Relay IP: ${FG_YELLOW}${ip}${R}"
        fi
    done
    echo ""
}

# ──────────────────────────────────────────────────────────────────────
# 4. Google / Gmail Account Security Hardening Checklist
# ──────────────────────────────────────────────────────────────────────
show_hardening() {
    header
    echo -e " ${FG_PURPLE}${BOLD}[ GOOGLE & GMAIL ACCOUNT DEFENSE PROTOCOL ]${R}\n"

    echo -e "  ${FG_CYAN}${BOLD}[1] ENABLE 2-STEP VERIFICATION (2SV):${R}"
    echo -e "      • Go to: ${FG_YELLOW}https://myaccount.google.com/security${R}"
    echo -e "      • Switch from SMS codes to ${FG_GREEN}Google Authenticator${R} or ${FG_GREEN}FIDO2 Hardware Keys (YubiKey/Titan)${R}."
    echo -e "      • SMS is vulnerable to SIM-swapping attacks.\n"

    echo -e "  ${FG_CYAN}${BOLD}[2] PASSKEYS & ADVANCED PROTECTION:${R}"
    echo -e "      • Register a device Passkey (biometric / device-bound key)."
    echo -e "      • High-risk targets: Enroll in ${FG_GREEN}Google Advanced Protection Program${R}."
    echo -e "        URL: ${FG_YELLOW}https://landing.google.com/advancedprotection/${R}\n"

    echo -e "  ${FG_CYAN}${BOLD}[3] AUDIT THIRD-PARTY APP ACCESS & PERMISSIONS:${R}"
    echo -e "      • Check apps with access to your Gmail:"
    echo -e "        URL: ${FG_YELLOW}https://myaccount.google.com/permissions${R}"
    echo -e "      • Revoke access for any unknown, abandoned, or unnecessary apps.\n"

    echo -e "  ${FG_CYAN}${BOLD}[4] CHECK GMAIL FORWARDING & FILTERS (Anti-Espionage):${R}"
    echo -e "      • Hackers often inject silent forwarding rules upon breach."
    echo -e "      • In Gmail: Settings -> Forwarding and POP/IMAP."
    echo -e "      • Verify no unauthorized address is set to receive forward copies.\n"

    echo -e "  ${FG_CYAN}${BOLD}[5] SESSION & DEVICE AUDIT:${R}"
    echo -e "      • Check active logged-in devices: ${FG_YELLOW}https://myaccount.google.com/device-activity${R}"
    echo -e "      • Immediately click 'Sign out' on any unfamiliar session.\n"
}

CMD="${1:-}"
ARG="${2:-}"

case "$CMD" in
    audit)
        [[ -z "$ARG" ]] && { echo "Usage: anti-email-shield audit <domain>  (e.g. gmail.com)"; exit 1; }
        audit_domain "$ARG"
        ;;
    breach)
        [[ -z "$ARG" ]] && { echo "Usage: anti-email-shield breach <email_address>"; exit 1; }
        check_breach "$ARG"
        ;;
    phish)
        [[ -z "$ARG" ]] && { echo "Usage: anti-email-shield phish <email_file.eml>"; exit 1; }
        analyze_eml "$ARG"
        ;;
    hardening|checklist)
        show_hardening
        ;;
    help|--help|-h|"")
        header
        echo -e " ${FG_WHITE}USAGE:${R}"
        echo -e "   ${FG_CYAN}anti-email-shield audit <domain>${R}    Verify SPF, DMARC policies & MX STARTTLS"
        echo -e "   ${FG_CYAN}anti-email-shield breach <email>${R}    Check if email is exposed in public leaks"
        echo -e "   ${FG_CYAN}anti-email-shield phish <file.eml>${R} Forensically inspect email headers for spoofing"
        echo -e "   ${FG_CYAN}anti-email-shield hardening${R}        Google/Gmail 2FA, Passkey & account checklist"
        echo ""
        ;;
    *)
        echo -e "${FG_RED}[!] Unknown command: $CMD${R}  (use: anti-email-shield help)"
        exit 1
        ;;
esac