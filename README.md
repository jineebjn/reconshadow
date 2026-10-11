# ReconShadow

Automated subdomain and reconnaissance workflow for bug bounty and authorised
penetration testing. ReconShadow chains the maintained
[ProjectDiscovery](https://github.com/projectdiscovery) toolchain into a single
script that enumerates subdomains, resolves them, probes live hosts, and checks
for subdomain takeover — with optional port scanning, historical-URL collection
and vulnerability scanning.

> ⚠️ **Authorised use only.** Only scan domains you own or have explicit written
> permission to test. You are responsible for how you use this tool.

## Features

- **Subdomain enumeration** — `subfinder` across all no-key passive sources.
- **DNS resolution** — `dnsx` keeps only names that resolve, so probing does less work.
- **Live-host probing** — `httpx` records status code, title, technology, IP, CNAME, CDN and ASN as JSON.
- **Subdomain takeover** — `nuclei` takeover templates (runs automatically when nuclei is installed).
- **Port scan** *(optional)* — `naabu` top-100 ports on live hosts.
- **Historical URLs** *(optional)* — `gau`, with parameter extraction.
- **Vulnerability scan** *(optional)* — `nuclei` templates against live hosts.
- Clean, timestamped output directory and a `summary.txt`.

## Install

```bash
git clone https://github.com/jineebjn/reconshadow.git
cd reconshadow
chmod +x install.sh reconshadow.sh
./install.sh
```

The installer sets up Go (via apt if needed), `jq`, and the tools listed below.
If the tools are not on your `PATH` afterwards, add the Go bin directory:

```bash
export PATH="$PATH:$(go env GOPATH)/bin"
```

## Usage

```bash
./reconshadow.sh -d example.com
```

Options:

| Flag | Description |
| --- | --- |
| `-d, --domain <domain>` | Target domain (required) |
| `-o, --output <dir>` | Output directory (default: `recon-<domain>-<timestamp>`) |
| `--ports` | Port scan live hosts with `naabu` (top 100) |
| `--urls` | Collect historical URLs with `gau` and extract params |
| `--nuclei` | Run `nuclei` templates against live hosts |
| `--all` | Enable `--ports`, `--urls` and `--nuclei` |
| `-h, --help` | Show help |

Examples:

```bash
# Default: subdomains, resolution, live hosts, takeover
./reconshadow.sh -d example.com

# Everything, into a named folder
./reconshadow.sh -d example.com -o out/example --all
```

## Output

```
recon-example.com-<timestamp>/
├── subdomains.txt   # all discovered subdomains
├── resolved.txt     # subdomains that resolve in DNS
├── live.json        # httpx results (status, title, tech, ip, cname, cdn, asn)
├── live.txt         # plain list of live URLs (requires jq)
├── takeover.txt     # nuclei takeover findings
├── ports.txt        # open ports (with --ports)
├── urls.txt         # historical URLs (with --urls)
├── params.txt       # extracted parameters (with --urls)
├── nuclei.txt       # vulnerability findings (with --nuclei)
└── summary.txt      # counts for the run
```

The `live.json` format is the same one consumed by the
[Recon Report Viewer](https://tools.jineebjn.com/recon/).

## Tools used

[subfinder](https://github.com/projectdiscovery/subfinder) ·
[dnsx](https://github.com/projectdiscovery/dnsx) ·
[httpx](https://github.com/projectdiscovery/httpx) ·
[nuclei](https://github.com/projectdiscovery/nuclei) ·
[naabu](https://github.com/projectdiscovery/naabu) ·
[gau](https://github.com/lc/gau)

## Author

Jineeb J N — [jineebjn.com](https://jineebjn.com)
