# 🧱 Base System

## Fundament

**Tools, Libs, ssh, Cuda, Docker, Git, SearXng**


### ⚠️ Package Manager Policy:

* apt/nala  -> System packages, dev tools, CLI utilities
* flatpak   -> Desktop applications (sandboxed)
* brew      -> Fill gaps (yazi, llmfit, etc.)
* snap      -> Only when truly required (e.g., some proprietary apps)
* Note: Avoid mixing snap and flatpak for the same application to prevent conflicts


### 1. 🚀 System Update, Repos & Basis-Tools

```shell
# home, sweet home
mkdir -p ~/labor/tmp ~/gits

# use nala instead of apt
sudo apt update && sudo apt upgrade && sudo apt install nala
sudo nala fetch  # select fastest mirrors for your region

# critical prerequisites (and none-critical)
sudo nala update && sudo nala install -y \
  curl wget ca-certificates gpg gnupg software-properties-common apt-transport-https \
  build-essential make git gh openssh-server fail2ban pkg-config cmake util-linux-extra\
  sqlite3 libsqlite3-dev libssl-dev libxml2-dev libxmlsec1-dev libmagic-dev guake snapd\
  libmagickwand-dev libffi-dev liblzma-dev libreadline-dev zlib1g-dev zsh btop mtr 7zip\
  libbz2-dev libncurses-dev xz-utils tk-dev python3-openssl net-tools fastfetch htop\
  iotop nvtop tree tmux ripgrep fzf zoxide fd-find gnome-shell-extension-manager shfmt\
  flatpak gnome-software-plugin-flatpak gnome-browser-connector stacer portaudio19-dev\
  libasound2-dev libjack-jackd2-dev libsndfile1-dev espeak-ng-data ffmpeg poppler-utils\
  libgtk-3-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev\
  libx264-dev libjpeg-dev libpng-dev libtiff-dev gstreamer1.0-plugins-base jq tealdeer\
  gstreamer1.0-plugins-good imagemagick direnv shellcheck aria2 python3-venv python3-pip\
  unattended-upgrades

# unattended-upgrades for automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades

# alias-link fd for fdfind (conditional - only if fd not already available)
command -v fd &>/dev/null || sudo ln -sf "$(which fdfind)" /usr/local/bin/fd

# snap
sudo systemctl enable --now snapd.socket
sudo snap refresh

# Homebrew & yazi, lazyjournal, lazydocker
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install yazi font-symbols-only-nerd-font lazyjournal lazydocker

# optional gnome extensions
gsettings set org.gnome.shell disable-extension-version-validation true # for new ubuntu's
# xdg-open https://extensions.gnome.org/extension/1653/tweaks-in-system-menu/
# xdg-open https://extensions.gnome.org/extension/4548/tactile/
# xdg-open https://extensions.gnome.org/extension/1319/gsconnect/

# optional embellishments
# Damask wallpaper (nasa api-key: https://api.nasa.gov/)
# xdg-open https://flathub.org/de/apps/app.drey.Damask

# Fallout theme for grub (download first, review, then execute - don't pipe directly to bash)
# sudo nano /etc/default/grub -> GRUB_TIMEOUT_STYLE=menu, GRUB_TIMEOUT=5, GRUB_GFXMODE=1920x1080,auto
wget https://github.com/shvchk/fallout-grub-theme/raw/master/install.sh -O /tmp/fallout-grub-install.sh
bash /tmp/fallout-grub-install.sh
```

### 2. 🔒 SSH, UFW & Co.

```shell
# ssh
# on new device enable ssh
sudo systemctl enable --now ssh
#sudo systemctl start ssh
sudo ufw allow ssh
sudo ufw --force enable
# and copy id to auto-connect-host
ssh-keygen -t ed25519
ssh-copy-id user@host # -p 8022 for termux

# Too many authentication failures
ssh-copy-id -o "IdentitiesOnly=yes" -i ~/.ssh/id_ed25519.pub user@host

# old device
# delete legacy (optional)
ssh-keygen -R '[usedip]:8022'    # if you want use an other known-hosts-file
ssh-keygen -R '[hostname]:8022'  # -f "/home/$USER/.ssh/known_hosts"

# set computer name
# config in fritz.box ip + hostname (NEW-NAME)
sudo hostnamectl set-hostname NEW-NAME
sudo nano /etc/hosts # 127.0.1.1 NEW-NAME

# SSH Hardening (edit /etc/ssh/sshd_config)
cat <<EOF | sudo tee /etc/ssh/sshd_config.d/99-custom-hardening.conf > /dev/null
PasswordAuthentication no
PermitRootLogin no
AllowUsers $USER
EOF
sudo systemctl restart sshd

# fail2ban configuration
cat <<EOF | sudo tee /etc/fail2ban/jail.local > /dev/null
[sshd]
enabled = true
port = ssh
maxretry = 5
bantime = 3600
EOF
sudo systemctl restart fail2ban
```

### 3. 🚀 Docker & CUDA Toolkit

<font size='+4'><b>🤮</b></font> Never install <font color=red>**docker-desktop**</font> under linux -> <font color=red>**no cuda**</font>

* [Docker](https://docs.docker.com/engine/install/ubuntu/)
```shell
# First remove all docker-like
sudo nala remove docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc
# Add Docker's official GPG key:
sudo nala update
sudo nala install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo nala update
# Install docker
sudo nala install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Create group and add user (logout/login or reboot required for group membership to take effect)
sudo usermod -aG docker $USER
# Check
docker run --rm hello-world
```

* **⚠️ Docker + UFW Configuration**:<br>
> - Docker manipulates iptables directly and bypasses UFW rules.<br>
> - Container ports published with `-p` may be reachable from outside, even with UFW enabled.<br>
> - Consider using network restrictions or Docker's own firewall integration if security is critical.
```shell
# install ufw-docker and patch / restart
sudo wget -O /usr/local/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker
sudo chmod +x /usr/local/bin/ufw-docker && sudo ufw-docker install
sudo systemctl restart ufw
```

* [CUDA Toolkit](https://developer.nvidia.com/cuda-toolkit-archive)
```shell
# Local CUDA Toolkit
#
# install your nvidia-driver via ubuntu or
# go to the CUDA toolkit archive and download the right version
# eg: my driver ...580 needs the 13.0 version, so i download 13.0.2
# then run the installer
# Note: The application determines the required CUDA version; the NVIDIA driver
# must meet the minimum compatibility requirement. Check NVIDIA's CUDA
# compatibility documentation for details.

# Docker CUDA Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo nala update && sudo nala install -y nvidia-container-toolkit

# Configure NVIDIA container runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# check
sudo docker run --rm --gpus all ubuntu nvidia-smi
```

### 4. 🚀 Github & SearXng

* Github:
```shell
sudo nala install gh && gh auth login

# eg: prompt: Make me a global Gitignore, focusing on Python. -> .gitignore_global
# insert special folders from your agents (.kilo, .claude, .opencode etc) or what you want.
# use the noreply email (https://github.com/settings/emails)
git config --global core.excludesfile ~/.gitignore_global
git config --global user.name "name"
git config --global user.email "email"
```

* SearXng:
```shell
# Create directories for configuration and persistent data
mkdir -p ~/.searxng/config/ ~/.searxng/data/

# Run the container
docker run --name searxng -d --restart always -p 8808:8080 \
    -v "$HOME/.searxng/config/:/etc/searxng/" -v "$HOME/.searxng/data/:/var/cache/searxng/" \
    docker.io/searxng/searxng:latest
```
> ⚠️ To use searxng in a MCP server, the entry '-json' must be added under search->formats in config/settings.yml.
```shell
  formats:
    - html
    - json
```

### 5. 🧿 ZSH & Antidote
```shell
# switch the shell (do not exit bash)
chsh -s $(which zsh)

# Fonts
mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
fc-cache -fv && cd ~

# optional guake:
# 1. Set shell to 'which zsh'; 2. select 'Run command as a login shell'
# 3. unset 'Use system fixed width font'; 4. Set font to MesloLGS NF Regular

# antidote plugin manager
git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote

# plugins selection
cat << 'EOF' > ~/.zsh_plugins.txt
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-completions
romkatv/powerlevel10k
EOF

# integrate in zsh
cat << 'EOF' >> ~/.zshrc
# Antidote init
source ~/.antidote/antidote.zsh
# Plugins load and compile
antidote load
EOF

# restart terminal (or guake)
```

* Optional: create the folders (`mkdir -p ~/.shlib/exports ~/.shlib/shlibs`) and insert in .zshrc (.bashrc)
```shell
# Import all files in the exports directory as environment variables with its content as the value
export SHLIB_EXPORTS_DIR="$HOME/.shlib/exports"
for f in "$SHLIB_EXPORTS_DIR"/*; do [ -f "$f" ] && export "$(basename "$f")"="$(cat "$f")"; done

# Import functions from scripts in the shlibs directory
export SHLIB_LIB_DIR="$HOME/.shlib/shlibs"
[ -d "$SHLIB_LIB_DIR" ] && for s in "$SHLIB_LIB_DIR"/*; do [ -f "$s" ] && source "$s"; done
```


## Ecosystems

### Python (simple)
```shell
# Level 0
# Python, pipx
sudo nala update && sudo nala install python3 pipx
# UV
curl -LsSf https://astral.sh/uv/install.sh | sh
# Base equipment
uv tool install ruff; uv tool install mypy; uv tool install bump-my-version; uv tool install rust-just

# Level 1
# Mamba
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh

# insert in .bashrc/.zshrc:
# don't touch mamba stuff
export UV_PYTHON_PREFERENCE=only-managed
# direnv hook (MUST BE AT THE END)
eval "$(direnv hook zsh)" # eval "$(direnv hook bash)"
```

### Node
* **Node = Version Manager + Package Manager**
* Oldschool: **nvm** + **npm**
* State of the Art: **fnm** + **pnpm** (or **bun**)<br>
The Fast Node Manager (fnm) **replaces the slower nvm** and provides and manages the **different node versions**.

```shell
# replace the rc file with yours (.bashrc/.zshrc)
curl -fsSL https://fnm.vercel.app/install | bash && source ~/.zshrc && fnm install --lts

# install version:
fnm install 22
# location versions:
ls /home/frank/.local/share/fnm/node-versions/
# node-binary (replace version):
ls -l /home/frank/.local/share/fnm/node-versions/v22.22.1/installation/bin/node

# Enable Corepack (provides pnpm)
corepack enable
corepack prepare pnpm@latest --activate

# setup bashrc
pnpm setup

# allow requirements-builds
pnpm approve-builds -g

# eg: Installing kilocode-cli with pnpm
# pnpm add -g @kilocode/cli # old: npm install -g @kilocode/cli

# useful
pnpm list -g --depth=0      # installed packages
pnpm add -g [pkg]           # Permanently installs a tool globally.
pnpm dlx [pkg]              # Runs a tool without installing it (like npx).
pnpm x [cmd]                # Runs a tool that is in the local package.json.
pnpm store status           # Storage space check
pnpm store prune            # Cleans up the hard drive (shared store).

# in .bashrc
# in the fnm part change: eval "$(fnm env --shell bash)" -> eval "$(fnm env --use-on-cd --shell bash)"
export FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  # Auto-Switch Node Version based on .nvmrc / .node-version
  eval "$(fnm env --use-on-cd --shell bash)"
fi
# leave the pnpm part unchanged

# exclusive goodies
# agents
pnpm add -g @kilocode/cli

# pm2: install / create sudo-command (pm2-service)
pnpm add -g pm2 && pm2 startup # execute generated command

```

