# Pi Extensions

Custom extensions and skills for the [pi coding agent](https://github.com/mariozechner/pi-coding-agent).

## Quick Install

Install everything with a single command:

```bash
curl -LsSf https://raw.githubusercontent.com/tomcreutz/pi_extensions/main/install.sh | bash
```

This will:
- Install system dependencies (Node.js, bubblewrap, socat, ripgrep)
- Install the pi coding agent
- Install this extensions package
- Configure pi to use the extensions

### Supported Systems
- **Ubuntu** / Debian
- **Arch Linux** / CachyOS

## Manual Installation

### Prerequisites

Install the required dependencies for your system:

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install nodejs npm bubblewrap socat ripgrep
```

**Arch Linux/CachyOS:**
```bash
sudo pacman -S nodejs npm bubblewrap socat ripgrep
```

### Install pi and extensions

```bash
# Install pi coding agent globally
npm install -g @mariozechner/pi-coding-agent

# Install this extensions package using pi
pi install git+https://github.com/tomcreutz/pi_extensions.git
```

Packages installed via `pi install` are automatically configured.

## Extensions

### 🔍 Brave Search
Web search integration using the Brave Search API.

**Requirements:** Set `BRAVE_API_KEY` environment variable.

See [brave-search/README.md](extensions/brave-search/README.md) for details.

### 🛡️ Guardrails
Safety guardrails for AI operations with configurable rules.

See [guardrails/README.md](extensions/guardrails/README.md) for details.

### 📦 Sandbox
Secure sandboxed execution environment using Anthropic's sandbox runtime.

### 📋 Plan Mode
Structured planning mode for complex tasks.

## Uninstall

```bash
curl -LsSf https://raw.githubusercontent.com/tomcreutz/pi_extensions/main/uninstall.sh | bash
```

Or manually:

```bash
pi uninstall @tomcreutz/pi_extensions
npm uninstall -g @mariozechner/pi-coding-agent
```

## Development

Clone and install locally:

```bash
git clone https://github.com/tomcreutz/pi_extensions.git
cd pi_extensions
npm install

# Link for development
npm link
```

## License

MIT
