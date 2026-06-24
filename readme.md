# My Dotfiles

A collection of configuration files for my Arch Linux setup, managed with GNU Stow.

## 💻 Tech Stack
* **OS:** Arch Linux
* **Window Manager:** i3-wm
* **Terminal:** Alacritty
* **Editor:** Neovim
* **Status Bar:** Polybar
* **Compositor:** Picom
* **Colors/Theming:** Matugen
* **Package Management:** pacman + yay

---

## 🚀 Installation

On a completely fresh installation of Arch Linux, you only need `git` installed to get started.

### 1. Clone the repository
Clone this repository into your home directory (usually `~/.dotfiles`):
```bash
git clone [https://github.com/YOUR_GITHUB_USERNAME/dotfiles.git](https://github.com/YOUR_GITHUB_USERNAME/dotfiles.git) ~/.dotfiles
cd ~/.dotfiles
```

### 2. Run the Setup Script
The setup script will install core prerequisites (including `stow` and `yay`), set up necessary base directories, install a Nerd Font, and configure your basic Git credentials.
```bash
chmod +x setup.sh
./setup.sh
```

### 3. Install Apps & Map Dotfiles
The install script will use `yay` to download any missing packages (like Neovim, i3, Polybar) and then use GNU Stow to symlink the configurations to their correct locations in your home directory.
```bash
./install.sh
```
*Note: The script includes a post-install hook that will automatically reload i3, Polybar, and Picom if they are currently running, giving you instant feedback.*

---

## 📂 Repository Structure

This repository uses [GNU Stow](https://www.gnu.org/software/stow/) to manage symlinks. Each folder in the root directory represents an application. The contents of that folder mimic the structure of your home directory.

For example, the `nvim` folder contains `.config/nvim/`. When you run `stow nvim`, Stow creates a symlink from `~/.config/nvim` pointing directly to `~/.dotfiles/nvim/.config/nvim`.

```text
.dotfiles/
├── alacritty/      # Contains .config/alacritty/
├── i3/             # Contains .config/i3/
├── matugen/        # Contains .config/matugen/
├── nvim/           # Contains .config/nvim/
├── picom/          # Contains .config/picom/
├── polybar/        # Contains .config/polybar/
├── scripts/        # Contains .local/bin/ or custom scripts
├── install.sh      # Main installation and stowing script
├── setup.sh        # Prerequisite bootstrap script
└── README.md
```

## 🛠️ Adding a New App

If you want to add a new application to your dotfiles in the future:
1. Create a new folder in the root of this repo (e.g., `rofi/`).
2. Replicate the target file path inside that folder (e.g., `rofi/.config/rofi/config.rasi`).
3. Add the app to the `apps` array inside `install.sh`.
4. Run `./install.sh` again to install and link it!
