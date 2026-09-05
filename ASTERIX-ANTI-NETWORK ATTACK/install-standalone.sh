#!/usr/bin/env bash
# =====================================================================
# ASTERIX Anti-Network Attack — Standalone Installer
# Works on ANY Linux Distribution: Debian, Ubuntu, Kali, Arch, Fedora,
# CentOS, Alpine, and Android Termux. Zero Asterix OS dependency!
# =====================================================================

set -e

C_RESET='\033[0m'
C_BOLD='\033[1m'
C_GREEN='\033[38;5;46m'
C_CYAN='\033[38;5;51m'
C_YELLOW='\033[38;5;220m'
C_RED='\033[38;5;196m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect install target directory
if [ -n "$PREFIX" ] && [ -d "$PREFIX/bin" ]; then
    # Android Termux
    INSTALL_DIR="$PREFIX/bin"
    SUDO=""
elif [ "$(id -u)" -eq 0 ]; then
    # Running as root
    INSTALL_DIR="/usr/local/bin"
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    # Non-root with sudo
    INSTALL_DIR="/usr/local/bin"
    SUDO="sudo"
else
    # Non-root fallback
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    SUDO=""
fi

echo -e "${C_CYAN}${C_BOLD}"
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║  ASTERIX ANTI-NETWORK ATTACK — STANDALONE INSTALLER                  ║"
echo "║  Deployable on Ubuntu, Debian, Kali, Arch, Fedora, Termux & more     ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo -e "${C_RESET}"

echo -e "${C_CYAN}[*] Target Installation Directory:${C_RESET} ${C_YELLOW}${INSTALL_DIR}${C_RESET}\n"

# Step 1: Compile anti-reverse-sentinel (Rust)
echo -e "${C_CYAN}[1/3] Building anti-reverse-sentinel...${C_RESET}"
SENTINEL_BIN=""
if [ -d "${SCRIPT_DIR}/anti-reverse-sentinel" ]; then
    cd "${SCRIPT_DIR}/anti-reverse-sentinel"
    if command -v cargo >/dev/null 2>&1; then
        cargo build --release
        SENTINEL_BIN="${SCRIPT_DIR}/anti-reverse-sentinel/target/release/anti-reverse-sentinel"
    elif command -v rustc >/dev/null 2>&1; then
        rustc -O src/main.rs -o anti-reverse-sentinel
        SENTINEL_BIN="${SCRIPT_DIR}/anti-reverse-sentinel/anti-reverse-sentinel"
    else
        echo -e "${C_YELLOW}[!] rustc/cargo not found. Skipping binary build; bash fallback will be used.${C_RESET}"
    fi
    cd "${SCRIPT_DIR}"
fi

# Step 2: Install bash modules and create short aliases
echo -e "${C_CYAN}[2/3] Installing standalone tools into ${INSTALL_DIR}...${C_RESET}"

SCRIPTS=(
    "anti-net-shield.sh:anti-net"
    "anti-email-shield.sh:anti-email"
    "anti-arp-spoof.sh:anti-arp"
    "anti-synflood.sh:anti-syn"
    "anti-dns-hijack.sh:anti-dns"
    "anti-portscan.sh:anti-scan"
)

for pair in "${SCRIPTS[@]}"; do
    IFS=':' read -r src alias_name <<< "$pair"
    if [ -f "${SCRIPT_DIR}/${src}" ]; then
        $SUDO cp "${SCRIPT_DIR}/${src}" "${INSTALL_DIR}/${src}"
        $SUDO chmod 755 "${INSTALL_DIR}/${src}"
        # Create friendly alias link (e.g. anti-net, anti-email, anti-arp)
        $SUDO ln -sf "${INSTALL_DIR}/${src}" "${INSTALL_DIR}/${alias_name}"
        echo -e "${C_GREEN}  [✔] Installed:${C_RESET} ${src} -> ${C_YELLOW}${alias_name}${C_RESET}"
    fi
done

if [ -n "$SENTINEL_BIN" ] && [ -f "$SENTINEL_BIN" ]; then
    $SUDO cp "$SENTINEL_BIN" "${INSTALL_DIR}/anti-reverse-sentinel"
    $SUDO chmod 755 "${INSTALL_DIR}/anti-reverse-sentinel"
    $SUDO ln -sf "${INSTALL_DIR}/anti-reverse-sentinel" "${INSTALL_DIR}/anti-rev"
    echo -e "${C_GREEN}  [✔] Installed:${C_RESET} anti-reverse-sentinel -> ${C_YELLOW}anti-rev${C_RESET}"
fi

# Step 3: Check recommended dependencies
echo -e "\n${C_CYAN}[3/3] Checking optional recommended system utilities...${C_RESET}"
DEPS=("iptables" "ip" "ss" "dig" "curl" "openssl")
for dep in "${DEPS[@]}"; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo -e "  ${C_GREEN}[✔]${C_RESET} ${dep} available"
    else
        echo -e "  ${C_YELLOW}[!]${C_RESET} ${dep} missing (optional - some features may use fallbacks)"
    fi
done

echo -e "\n${C_GREEN}${C_BOLD}══════════════════════════════════════════════════════════════════════${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}[✔] STANDALONE INSTALLATION COMPLETE!${C_RESET}"
echo -e "${C_CYAN}You can now run these tools directly from ANY terminal:${C_RESET}"
echo -e "  ${C_YELLOW}anti-net${C_RESET}     - Master interactive defense dashboard"
echo -e "  ${C_YELLOW}anti-email${C_RESET}   - Email & account security auditor (SPF/DMARC/breaches)"
echo -e "  ${C_YELLOW}anti-arp${C_RESET}     - ARP poisoning detection & permanent gateway locking"
echo -e "  ${C_YELLOW}anti-syn${C_RESET}     - TCP SYN flood defense & rate limiting"
echo -e "  ${C_YELLOW}anti-dns${C_RESET}     - DNS poisoning detection & immutable resolver lock"
echo -e "  ${C_YELLOW}anti-scan${C_RESET}    - Port scan detection & dynamic 30-min auto-quarantine"
echo -e "  ${C_YELLOW}anti-rev${C_RESET}     - Anti-reverse engineering & anti-debugging sentinel"
echo -e "${C_GREEN}${C_BOLD}══════════════════════════════════════════════════════════════════════${C_RESET}\n"