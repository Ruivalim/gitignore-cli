# Gitignore CLI

A command-line tool to download .gitignore files from the github/gitignore repository.

## Installation

### Install from script

```bash
curl -sSL https://raw.githubusercontent.com/ruivalim/gitignore-cli/main/install.sh | bash
```

### Install from source

```bash
git clone https://github.com/ruivalim/gitignore-cli.git
cd gitignore-cli
cargo install --path .
```

## Commands

Download a specific template:
```bash
gitignore Python
gitignore Rust
gitignore Node
```

List all available templates:
```bash
gitignore ls
```

Interactive selection (requires fzf):
```bash
gitignore
```

Show help:
```bash
gitignore --help
```

## Requirements

- curl, tar (for installation)
- fzf (optional, for interactive mode)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Submit a pull request

## Acknowledgments

- [github/gitignore](https://github.com/github/gitignore) for providing the gitignore templates
- [fzf](https://github.com/junegunn/fzf) for the interactive selection interface