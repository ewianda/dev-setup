# Development Environment Dotfiles

This repository contains a reproducible setup for terminal tooling and editor configuration.  
It is designed to be idempotent, portable, and safe to run on fresh machines as well as
existing systems.

## What's Included

- A `bootstrap.sh` script that:
  - Detects the host package manager (APT, Homebrew, DNF, or Pacman) and installs required tooling.
  - Symlinks dotfiles using [GNU Stow](https://www.gnu.org/software/stow/) with automatic backups for conflicting files.
  - Sets up Vim, fzf, tmux, ShellCheck, Go (optional), and Node.js via nvm (optional).
  - Installs Vim plugins via `vim-plug` and common CoC extensions.
- Dotfiles organised under `dotfiles/` to keep configuration modular and easy to extend.
- A Dockerfile and Make targets for testing the bootstrap process in a disposable container.

## Repository Layout

```
.
├── bootstrap.sh          # Entry point for provisioning a machine
├── dotfiles/             # Modular dotfiles organised per application
│   ├── bash/.bashrc
│   ├── git/.config/git/config
│   └── vim/.config/vim/vimrc
├── Dockerfile            # Minimal image for exercising the bootstrap script
├── Makefile              # Helper targets (linting, dockerised testing, bootstrap)
└── README.md
```

To add new configuration simply create another folder inside `dotfiles/` (e.g. `dotfiles/tmux`) and
populate it with the files or directories you want linked into `$HOME`.

## Prerequisites

- macOS, Ubuntu/Debian, Fedora, or Arch Linux with one of the supported package managers.
- `sudo` access if packages need to be installed.
- Git 2.x or higher.

The script will install missing dependencies such as GNU Stow automatically.  You can control tool
versions through environment variables:

```bash
GO_VERSION=1.22.5 NODE_VERSION=20 ./bootstrap.sh
```

## Usage

```bash
# Clone the repo into a stable location
git clone https://github.com/your-user/dev-setup.git ~/.dotfiles
cd ~/.dotfiles

# Provision your environment
./bootstrap.sh
```

### Optional Flags

- `--skip-go` – do not install Go.
- `--skip-node` – do not install Node.js via nvm.
- `--skip-vim-plugins` – link Vim configuration but do not install plugins.

You can re-run the script at any time; it safely restows dotfiles and only installs missing packages.
Existing conflicting files are backed up with a timestamp suffix before new symlinks are created.

## Testing Changes

The project ships with a lightweight container workflow:

```bash
# Lint the bootstrap script
make lint

# Build the docker test image
make docker-build

# Run the bootstrap script inside the container without installing heavy dependencies
make test
```

The `test` target mounts the repository into the container and runs the bootstrap script with heavy
optional installs disabled.  Use `make docker-shell` for an interactive environment that mirrors a
fresh Ubuntu machine.

## Updating Dotfiles

After editing files under `dotfiles/`, restow them manually if required:

```bash
stow --dir dotfiles --target "$HOME" --restow bash
```

All dotfiles live inside this repository, keeping the machine configuration auditable and versioned.
