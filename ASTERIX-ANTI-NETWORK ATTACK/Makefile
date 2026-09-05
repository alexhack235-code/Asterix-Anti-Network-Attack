# =====================================================================
# ASTERIX Anti-Network Attack — Standalone Makefile
# =====================================================================

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
CARGO  ?= cargo
RUSTC  ?= rustc

SCRIPTS = anti-net-shield.sh \
          anti-email-shield.sh \
          anti-arp-spoof.sh \
          anti-synflood.sh \
          anti-dns-hijack.sh \
          anti-portscan.sh

all: build-rust

build-rust:
	@if [ -d anti-reverse-sentinel ]; then \
		echo "[*] Building anti-reverse-sentinel..."; \
		if command -v $(CARGO) >/dev/null 2>&1; then \
			cd anti-reverse-sentinel && $(CARGO) build --release; \
		elif command -v $(RUSTC) >/dev/null 2>&1; then \
			cd anti-reverse-sentinel && $(RUSTC) -O src/main.rs -o anti-reverse-sentinel; \
		fi; \
	fi

install: all
	@mkdir -p $(DESTDIR)$(BINDIR)
	@echo "[*] Installing scripts to $(DESTDIR)$(BINDIR)..."
	@for s in $(SCRIPTS); do \
		cp -f $$s $(DESTDIR)$(BINDIR)/; \
		chmod 755 $(DESTDIR)$(BINDIR)/$$s; \
	done
	@ln -sf $(DESTDIR)$(BINDIR)/anti-net-shield.sh $(DESTDIR)$(BINDIR)/anti-net
	@ln -sf $(DESTDIR)$(BINDIR)/anti-email-shield.sh $(DESTDIR)$(BINDIR)/anti-email
	@ln -sf $(DESTDIR)$(BINDIR)/anti-arp-spoof.sh $(DESTDIR)$(BINDIR)/anti-arp
	@ln -sf $(DESTDIR)$(BINDIR)/anti-synflood.sh $(DESTDIR)$(BINDIR)/anti-syn
	@ln -sf $(DESTDIR)$(BINDIR)/anti-dns-hijack.sh $(DESTDIR)$(BINDIR)/anti-dns
	@ln -sf $(DESTDIR)$(BINDIR)/anti-portscan.sh $(DESTDIR)$(BINDIR)/anti-scan
	@if [ -f anti-reverse-sentinel/target/release/anti-reverse-sentinel ]; then \
		cp -f anti-reverse-sentinel/target/release/anti-reverse-sentinel $(DESTDIR)$(BINDIR)/; \
		chmod 755 $(DESTDIR)$(BINDIR)/anti-reverse-sentinel; \
		ln -sf $(DESTDIR)$(BINDIR)/anti-reverse-sentinel $(DESTDIR)$(BINDIR)/anti-rev; \
	elif [ -f anti-reverse-sentinel/anti-reverse-sentinel ]; then \
		cp -f anti-reverse-sentinel/anti-reverse-sentinel $(DESTDIR)$(BINDIR)/; \
		chmod 755 $(DESTDIR)$(BINDIR)/anti-reverse-sentinel; \
		ln -sf $(DESTDIR)$(BINDIR)/anti-reverse-sentinel $(DESTDIR)$(BINDIR)/anti-rev; \
	fi
	@echo "[✔] Standalone installation complete! Commands available: anti-net, anti-email, anti-arp, anti-syn, anti-dns, anti-scan, anti-rev"

uninstall:
	@for s in $(SCRIPTS); do \
		rm -f $(DESTDIR)$(BINDIR)/$$s; \
	done
	@rm -f $(DESTDIR)$(BINDIR)/anti-net \
	       $(DESTDIR)$(BINDIR)/anti-email \
	       $(DESTDIR)$(BINDIR)/anti-arp \
	       $(DESTDIR)$(BINDIR)/anti-syn \
	       $(DESTDIR)$(BINDIR)/anti-dns \
	       $(DESTDIR)$(BINDIR)/anti-scan \
	       $(DESTDIR)$(BINDIR)/anti-rev \
	       $(DESTDIR)$(BINDIR)/anti-reverse-sentinel
	@echo "[✔] Uninstalled ASTERIX anti-network attack tools."

clean:
	@if [ -d anti-reverse-sentinel ]; then \
		rm -rf anti-reverse-sentinel/target anti-reverse-sentinel/anti-reverse-sentinel; \
	fi