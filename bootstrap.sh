#!/bin/bash
#
# This is a setup script for my systems.
#
# TODO: Add dry run functionality
# TODO: Replace wget calls with curl
# TODO: Get copy/paste working between host and guest for VMWare installs.

set -e

if [ "$EUID" -ne 0 ]
  then echo "Please run as root using sudo. User-specific data will be assigned to the user you are sudoing from."
  exit
fi
user_home=$(getent passwd $SUDO_USER | cut -d: -f6)

export NEWT_COLORS='
  root=black,black
  roottext=black,black
  window=green,black
  border=green,black
  textbox=green,black
  button=black,green
  label=green,black
  title=green,black
  emptyscale=black,lightgray
  fullscale=black,green
'

### Helpers / Formatters ###
exists() { command -v "$1" >/dev/null 2>&1; }
error() { printf "$@\n" >&2; exit 1; }
try() { "$1" || error "Failure at $1"; }
distro() { [[ $(cat /etc/*-release | grep -w NAME | cut -d= -f2 | tr -d '"') == *$1* ]]; }
config(){ /usr/bin/git --git-dir=$user_home/.cfg/ --work-tree=$user_home $@; }

### Variables (Edit these!) ###
dotfile_repo="https://www.github.com/qrbounty/dotfiles.git"
pip3_pkgs="yara pillow"
declare -a deb_custom_pkgs=(
  "curl locate git python3 python3-pip suckless-tools tmux vim tree" # Dependencies
  "zsh highlight lolcat boxes tldr ripgrep neovim exa ranger"        # 'Essentials'
  "fonts-powerline fonts-hack fonts-font-awesome"                    # Fonts
  "xorg i3 i3blocks kitty lightdm rofi feh"                          # Desktop
  "vlc transmission audacity firefox-esr docker.io"                  # Common Apps
  "binwalk gdb flashrom jsbeautifier afl hashcat zzuf"               # Security
)

declare -a deb_installers=(
  "pip3_install"
  "configure_lightdm"
  "install_zsh"
  "install_vscode"
  "install_bat"
  "random_wallpaper"
  "config_dotfiles"
  "config_docker"
  "install_vimplug" # Relies on dotfiles
)

### Installers ###
apt_install() { debconf-apt-progress -- apt-get install -qq -y -o=Dpkg::Use-Pty=0 $2; }
pip3_install() { pip3 -q install $pip3_pkgs; < /dev/null > /dev/null && echo "Installed!"; }

configure_lightdm(){
  echo lightdm shared/default-x-display-manager select lightdm | sudo debconf-set-selections -v
  # echo "set shared/default-x-display-manager lightdm" | debconf-communicate
  echo "background = #212121" >> /etc/lightdm/lightdm-gtk-greeter.conf
  echo "theme-name = Adwaita-dark" >> /etc/lightdm/lightdm-gtk-greeter.conf
  echo "font-name = Hack" >> /etc/lightdm/lightdm-gtk-greeter.conf
  echo "hide-user-image = true" >> /etc/lightdm/lightdm-gtk-greeter.conf
  #sudo echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
  dpkg-reconfigure lightdm 
}

install_bat(){
  # https://github.com/sharkdp/bat/
  # On version 0.15.4 until it's officially supported in Debian...
  wget -qO /tmp/bat.deb "https://github.com/sharkdp/bat/releases/download/v0.15.4/bat_0.15.4_amd64.deb"
  dpkg -i /tmp/bat.deb
}

install_vimplug(){
  # TODO: Get vim +PlugInstall +qall > /dev/null working with dotfiles
  updatedb > /dev/null
  /bin/su -c "/bin/curl -L --silent \"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim\" --create-dirs -o $user_home/.vim/autoload/plug.vim" - $SUDO_USER
  /bin/su -c "vim -Es -u $user_home/.vimrc -i NONE +PlugInstall +qall" - $SUDO_USER
}

install_vscode(){
  # TODO: Fix. Seems to be a key issue?
  curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
  sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  DEBIAN_FRONTEND=noninteractive apt-get install -qq -o=Dpkg::Use-Pty=0 apt-transport-https < /dev/null > /dev/null
  apt-get update < /dev/null > /dev/null
  DEBIAN_FRONTEND=noninteractive apt-get install -qq -o=Dpkg::Use-Pty=0 code < /dev/null > /dev/null
  rm packages.microsoft.gpg
}

install_zsh(){
  #TODO: Get .zshrc from dotfiles
  /bin/su -c "wget -q https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O - | sh > /dev/null" - $SUDO_USER
  #cp $user_home/.oh-my-zsh/templates/zshrc.zsh-template $user_home/.zshrc
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $user_home/.oh-my-zsh/custom/themes/powerlevel10k
  /bin/su -c "/bin/curl --silent -L \"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf\" --create-dirs -o  $user_home/.fonts/Meslo-Regular.ttf" - $SUDO_USER
  /bin/su -c "/bin/curl --silent -L \"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf\" --create-dirs -o  $user_home/.fonts/Meslo-Bold.ttf" - $SUDO_USER
  /bin/su -c "/bin/curl --silent -L \"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20bold%20Italic.ttf\" --create-dirs -o  $user_home/.fonts/Meslo-Bold-Italic.ttf" - $SUDO_USER
  /bin/su -c "/bin/curl --silent -L \"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf\" --create-dirs -o  $user_home/.fonts/Meslo-Italic.ttf" - $SUDO_USER
  chsh -s /bin/zsh $SUDO_USER
}

random_wallpaper(){
  # Get random wallpaper(s) from Picsum, would be loaded by feh later in i3 cfg.
  height=1050
  width=1680
  for i in {1..5}; do
    /bin/su -c "/bin/curl --silent -L \"https://picsum.photos/$width/$height/\" --create-dirs -o $user_home/Pictures/Wallpapers/starter$i.jpg" - $SUDO_USER
  done
}

config_docker(){
  #TODO: Pretty much all the things
  usermod -aG docker $SUDO_USER
  /bin/su -c "/usr/bin/docker pull caffix/amass" - $SUDO_USER
}

add_user(){
  #TODO: Everything
  echo "None"
}

config_dotfiles(){
  if exists git; then
    echo "Fetching Dotfiles"
    try dotfile_copy
  else
    err "git not detected, cannot gather dotfiles."
  fi
}

dotfile_copy(){
  [ ! -d "$user_home/.cfg" ] && /bin/su -c "mkdir $user_home/.cfg" - $SUDO_USER
  /bin/su -c "/usr/bin/git clone --bare $dotfile_repo $user_home/.cfg" - $SUDO_USER
  [ ! -d "$user_home/.config-backup" ] && /bin/su -c "mkdir -p .config-backup" - $SUDO_USER
  /bin/su -c "/usr/bin/git --git-dir=$user_home/.cfg/ --work-tree=$user_home checkout -f" - $SUDO_USER
  if [ $? = 0 ]; then
    echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    /bin/su -c "/usr/bin/git --git-dir=$user_home/.cfg/ --work-tree=$user_home checkout" - $SUDO_USER 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv $user_home/{} $user_home/.config-backup/{}
  fi;
  /bin/su -c "/usr/bin/git --git-dir=$user_home/.cfg/ --work-tree=$user_home checkout" - $SUDO_USER
  /bin/su -c "/usr/bin/git --git-dir=$user_home/.cfg/ --work-tree=$user_home config status.showUntrackedFiles no" - $SUDO_USER
  echo "Copied these dotfiles from $dotfile_repo :"
  /usr/bin/git --git-dir=$user_home/.cfg/ --work-tree=$user_home ls-files
  chmod +x $user_home/.config/shell/motd.sh
}

debian_install() {
  packages = ""

  debconf-apt-progress -- apt-get update
  debconf-apt-progress -- apt-get upgrade -y
  for package in "${deb_custom_pkgs[@]}"; do
    packages+="${package} "
  done
  apt_install "custom" "$packages"
  
  # Some odds and ends
  if dmidecode -s system-manufacturer = "VMware, Inc."; then
    apt_install "VMware" "open-vm-tools-desktop"
  fi
  echo 'exec i3' > $user_home/.xsession
  clear

  # TODO: Get whiptail to work for these.
  i=1
  echo "=== Customizing Install ==="
  for installer in "${deb_installers[@]}"; do
    echo -e "Stage $i/${#deb_installers[@]}: $installer"
    try $installer
    ((i++))
  done
}



# Main
header="QRBounty's Bootstrap Script 2.0"
logo="ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLAogICAgICAgICAgICAsLS4gICAgICAgXywtLS0uXyBfXyAgLyBcCiAgICAgICAgICAgLyAgKSAgICAuLScgICAgICAgYC4vIC8gICBcCiAgICAgICAgICAoICAoICAgLCcgICAgICAgICAgICBgLyAgICAvfAogICAgICAgICAgIFwgIGAtIiAgICAgICAgICAgICBcJ1wgICAvIHwKICAgICAgICAgICAgYC4gICAgICAgICAgICAgICwgIFwgXCAvICB8CiAgICAgICAgICAgICAvYC4gICAgICAgICAgLCctYC0tLS1ZICAgfAogICAgICAgICAgICAoICAgICAgICAgICAgOyB3YXJleiAgfCAgICcKICAgICAgICAgICAgfCAgLC0uICAgICwtJyAgICAmICAgIHwgIC8KICAgICAgICAgICAgfCAgfCAoICAgfCAgICAgc3R1ZmYgIHwgLwogICAgICAgICAgICApICB8ICBcICBgLl9fX19fX19fX19ffC8KICAgICAgICAgICAgYC0tJyAgIGAtLScKCiAgV0FSTklORyEgVGhpcyBzY3JpcHQgaXMgZm9yIGZyZXNoIHN5c3RlbXMgT05MWSEgIAogICAgICAgICAgICBEbyB5b3Ugd2FudCB0byBjb250aW51ZT8="
if (whiptail --defaultno --title "$header" --yesno "$(echo $logo | base64 -d -)" 21 54); then
  clear
  # OS Install
  if distro "Debian"; then
    try debian_install
  fi
  # End prompt
  if (whiptail --title "$header" --yesno "Installation has finished. Restart?" 20 60); then
    reboot
  else
    exit
  fi
else
  exit
fi
