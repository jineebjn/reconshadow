#!/usr/bin/env bash
#
# ReconShadow - automated subdomain & recon workflow
# Author: Jineeb J N
#
# Rebuilt around the maintained ProjectDiscovery toolchain
# (subfinder, dnsx, httpx, nuclei, naabu) plus gau.
#
set -euo pipefail

# ---------- colours (disabled when not a TTY) ----------
if [[ -t 1 ]]; then
  R=$(tput setaf 1); G=$(tput setaf 2); Y=$(tput setaf 3); B=$(tput setaf 6); BOLD=$(tput bold); RST=$(tput sgr0)
else
  R=""; G=""; Y=""; B=""; BOLD=""; RST=""
fi

info() { printf '%s[*]%s %s\n' "$B" "$RST" "$*"; }
ok()   { printf '%s[+]%s %s\n' "$G" "$RST" "$*"; }
warn() { printf '%s[!]%s %s\n' "$Y" "$RST" "$*"; }
err()  { printf '%s[-]%s %s\n' "$R" "$RST" "$*" >&2; }

banner() {
cat <<'EOF'
██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗
██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║
██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║
██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║
██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝
╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝
                               # By red_shadow_11 #
EOF
}

usage() {
cat <<EOF
ReconShadow - automated recon

Usage: $0 -d <domain> [options]

Options:
  -d, --domain <domain>   Target domain (required; you must be authorised to test it)
  -o, --output <dir>      Output directory (default: recon-<domain>-<timestamp>)
      --ports             Port scan live hosts with naabu (top 100 ports)
      --urls              Collect historical URLs with gau and extract params
      --nuclei            Run nuclei vulnerability templates against live hosts
      --all               Enable --ports, --urls and --nuclei
  -h, --help              Show this help

Subdomain-takeover detection runs automatically when nuclei is installed.
EOF
}

# ---------- argument parsing ----------
DOMAIN=""
OUTDIR=""
DO_PORTS=0
DO_URLS=0
DO_NUCLEI=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--domain) DOMAIN="${2:-}"; shift 2 ;;
    -o|--output) OUTDIR="${2:-}"; shift 2 ;;
    --ports)     DO_PORTS=1; shift ;;
    --urls)      DO_URLS=1; shift ;;
    --nuclei)    DO_NUCLEI=1; shift ;;
    --all)       DO_PORTS=1; DO_URLS=1; DO_NUCLEI=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

banner

if [[ -z "$DOMAIN" ]]; then
  read -r -p "Enter the target domain: " DOMAIN
fi

# Validate: plain domain name only. This value is used in commands and paths.
if ! printf '%s' "$DOMAIN" | grep -qE '^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+(xn--[a-zA-Z0-9-]+|[a-zA-Z]{2,})$'; then
  err "Invalid domain: '$DOMAIN'"
  exit 1
fi

echo
warn "Only scan assets you own or are explicitly authorised to test."
echo

OUTDIR="${OUTDIR:-recon-${DOMAIN}-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUTDIR"
info "Target:  ${BOLD}${DOMAIN}${RST}"
info "Output:  ${BOLD}${OUTDIR}${RST}"
echo

# ---------- helpers ----------
have()  { command -v "$1" >/dev/null 2>&1; }
need()  { if ! have "$1"; then err "Required tool '$1' not found. Run ./install.sh"; exit 1; fi; }
count() { if [[ -f "$1" ]]; then wc -l < "$1" | tr -d ' '; else echo 0; fi; }

need subfinder
need dnsx
need httpx

# ---------- 1. subdomain enumeration ----------
info "Enumerating subdomains (subfinder)..."
subfinder -d "$DOMAIN" -all -silent 2>/dev/null | sort -u > "$OUTDIR/subdomains.txt" || true
ok "$(count "$OUTDIR/subdomains.txt") subdomains"

# ---------- 2. DNS resolution ----------
info "Resolving DNS (dnsx)..."
dnsx -silent -l "$OUTDIR/subdomains.txt" > "$OUTDIR/resolved.txt" 2>/dev/null || true
ok "$(count "$OUTDIR/resolved.txt") resolving"

# Probe resolving hosts if any, else fall back to the full list.
PROBE_INPUT="$OUTDIR/resolved.txt"
[[ -s "$PROBE_INPUT" ]] || PROBE_INPUT="$OUTDIR/subdomains.txt"

# ---------- 3. live hosts ----------
info "Probing live hosts (httpx)..."
httpx -silent -json \
  -status-code -title -tech-detect -ip -cname -cdn -asn -location -content-length \
  -rl 150 -retries 2 \
  -l "$PROBE_INPUT" > "$OUTDIR/live.json" 2>/dev/null || true
if have jq; then
  jq -r '.url // .input // empty' "$OUTDIR/live.json" 2>/dev/null | sort -u > "$OUTDIR/live.txt" || true
else
  warn "jq not found - live.txt (plain URL list) not generated; see live.json"
fi
ok "$(count "$OUTDIR/live.txt") live hosts"

# ---------- 4. subdomain takeover (nuclei) ----------
if have nuclei; then
  info "Checking subdomain takeover (nuclei)..."
  # Run against the full list: dangling names that do not resolve are
  # exactly the takeover candidates.
  nuclei -silent -tags takeover -l "$OUTDIR/subdomains.txt" -o "$OUTDIR/takeover.txt" 2>/dev/null || true
  ok "$(count "$OUTDIR/takeover.txt") takeover finding(s)"
else
  warn "nuclei not found - skipping takeover detection"
fi

# ---------- 5. port scan (optional) ----------
if [[ "$DO_PORTS" -eq 1 ]]; then
  if have naabu; then
    info "Scanning top 100 ports (naabu)..."
    naabu -silent -top-ports 100 -l "$PROBE_INPUT" -o "$OUTDIR/ports.txt" 2>/dev/null || true
    ok "$(count "$OUTDIR/ports.txt") open port record(s)"
  else
    warn "naabu not found - skipping port scan"
  fi
fi

# ---------- 6. historical URLs (optional) ----------
if [[ "$DO_URLS" -eq 1 ]]; then
  if have gau; then
    info "Collecting historical URLs (gau)..."
    printf '%s\n' "$DOMAIN" | gau --subs 2>/dev/null | sort -u > "$OUTDIR/urls.txt" || true
    grep -oE '[?&][a-zA-Z0-9_]+=' "$OUTDIR/urls.txt" 2>/dev/null \
      | sed -E 's/^[?&]//; s/=$//' | sort -u > "$OUTDIR/params.txt" || true
    ok "$(count "$OUTDIR/urls.txt") URL(s), $(count "$OUTDIR/params.txt") param(s)"
  else
    warn "gau not found - skipping URL collection"
  fi
fi

# ---------- 7. nuclei vulnerability scan (optional) ----------
if [[ "$DO_NUCLEI" -eq 1 ]]; then
  if have nuclei; then
    info "Running nuclei templates on live hosts..."
    NUCLEI_INPUT="$OUTDIR/live.txt"
    [[ -s "$NUCLEI_INPUT" ]] || NUCLEI_INPUT="$PROBE_INPUT"
    nuclei -silent -l "$NUCLEI_INPUT" -o "$OUTDIR/nuclei.txt" 2>/dev/null || true
    ok "$(count "$OUTDIR/nuclei.txt") nuclei finding(s)"
  else
    warn "nuclei not found - skipping vulnerability scan"
  fi
fi

# ---------- summary ----------
{
  echo "ReconShadow summary"
  echo "Domain : $DOMAIN"
  echo "Date   : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Subdomains : $(count "$OUTDIR/subdomains.txt")"
  echo "Resolving  : $(count "$OUTDIR/resolved.txt")"
  echo "Live       : $(count "$OUTDIR/live.txt")"
  [[ -f "$OUTDIR/takeover.txt" ]] && echo "Takeover   : $(count "$OUTDIR/takeover.txt")"
  [[ -f "$OUTDIR/ports.txt" ]]    && echo "Open ports : $(count "$OUTDIR/ports.txt")"
  [[ -f "$OUTDIR/urls.txt" ]]     && echo "URLs       : $(count "$OUTDIR/urls.txt")"
  [[ -f "$OUTDIR/nuclei.txt" ]]   && echo "Nuclei     : $(count "$OUTDIR/nuclei.txt")"
} > "$OUTDIR/summary.txt"

echo
cat "$OUTDIR/summary.txt"
echo
ok "Recon complete. Results saved in ${BOLD}${OUTDIR}${RST}"
