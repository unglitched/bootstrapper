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

### User Variables - EDIT THESE! :) ###
# dotfile_repo - Your dotfiles repository, make sure it looks like https://github.com/qrbounty/dotfiles
# deb_apt_pkgs - The base packages you want installed using debian's apt. These will all be installed in one command.
# pip3_pkgs    - The pip3 packages to install for Python 3. These will all be installed in one command.
# deb_custom_pkgs - This is just a nice way to chunk up packages logically, for quicker on/off and testing.

dotfile_repo="https://www.github.com/qrbounty/dotfiles.git"
pip3_pkgs="yara pillow"
declare -a deb_custom_pkgs=(
  # Dependencies
  "curl locate git python3 python3-pip suckless-tools tmux vim tree whiptail"
  # 'Essentials'
  "zsh highlight lolcat boxes tldr ripgrep neovim exa ranger fonts-powerline fonts-hack fonts-font-awesome"
  # Desktop environment and apps
  "xorg i3 i3blocks kitty lightdm rofi feh vlc transmission audacity firefox-esr docker.io"
  # Security
  "binwalk gdb flashrom jsbeautifier afl hashcat zzuf"
)

declare -a deb_installers=(
  "configure_lightdm"
  "install_zsh"
  "install_vscode"
  "install_bat"
  "install_vimplug"
  "install_p10kfonts"
  "pip3_install"
  "random_wallpaper"
)
### Helpers / Formatters ###
# Sources: 
# https://brettterpstra.com/2015/02/20/shell-trick-printf-rules/
# https://stackoverflow.com/questions/394230/how-to-detect-the-os-from-a-bash-script 
# https://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs
# https://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
exists() { command -v "$1" >/dev/null 2>&1; }
error() { printf "$@\n" >&2; exit 1; }
try() { "$1" || error "Failure at $1"; }
os() { [[ $OSTYPE == *$1* ]]; }
distro() { [[ $(cat /etc/*-release | grep -w NAME | cut -d= -f2 | tr -d '"') == *$1* ]]; }
linux() { 
  case "$OSTYPE" in
    *linux*|*cygwin*) sys="gnu";;
    *bsd*|*darwin*) sys="bsd";;
  esac
  [[ "${sys}" == "$1" ]];
}

apt_install() { debconf-apt-progress -- apt-get install -qq -y -o=Dpkg::Use-Pty=0 $2; }
pip3_install() { pip3 -q install $pip3_pkgs; < /dev/null > /dev/null && echo "Installed!"; }

debian_install() {
  # Apt stuff, desktop environment
  debconf-apt-progress -- apt-get update
  debconf-apt-progress -- apt-get upgrade -y
  
  for package in "${deb_custom_pkgs[@]}"; do
    apt_install "custom" "$package"
  done
  
  if dmidecode -s system-manufacturer = "VMware, Inc."; then
    apt_install "VMware" "open-vm-tools-desktop"
  fi
  
  echo 'exec i3' > $user_home/.xsession
  i=0
  for installer in "${deb_installers[@]}"; do
    try $installer
    echo $(expr i \* 100 / ${#deb_installers[@]})
  done | whiptail --gauge "Running $installer..." 6 50 0
}

random_wallpaper(){
  # Get a random wallpaper from Picsum, would be loaded by feh later in i3 cfg.
  height=1050
  width=1680
  /bin/su -c "/bin/curl -L \"https://picsum.photos/$width/$height/\" --create-dirs -o $user_home/Pictures/Wallpapers/starter.jpg" - $SUDO_USER
}

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

install_p10kfonts(){
  /bin/su -c "/bin/curl -L \"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf\" --create-dirs -o  $user_home/.fonts/Meslo-Regular.ttf" - $SUDO_USER
  /bin/su -c "/bin/curl -L \"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf\" --create-dirs -o  $user_home/.fonts/Meslo-Bold.ttf" - $SUDO_USER
  /bin/su -c "/bin/curl -L \"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20bold%20Italic.ttf\" --create-dirs -o  $user_home/.fonts/Meslo-Bold-Italic.ttf" - $SUDO_USER
  /bin/su -c "/bin/curl -L \"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf\" --create-dirs -o  $user_home/.fonts/Meslo-Italic.ttf" - $SUDO_USER
}

install_vimplug(){
  updatedb > /dev/null
  /bin/su -c "/bin/curl -L \"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim\" --create-dirs -o  $user_home/.vim/autoload/plug.vim" - $SUDO_USER
  /bin/su -c "vim -es -u $user_home/.vimrc -i NONE -c \"PlugInstall\" -c \"qa\""
  # TODO: Get vim +PlugInstall +qall > /dev/null working with dotfiles
}

install_vscode(){
  curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
  sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  apt_install "VS Code Deps" apt-transport-https
  apt-get update < /dev/null > /dev/null
  apt_install "VS Code Core" code
  rm packages.microsoft.gpg
}

install_zsh(){
  /bin/su -c "wget -q https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O - | sh > /dev/null" - $SUDO_USER
  cp $user_home/.oh-my-zsh/templates/zshrc.zsh-template $user_home/.zshrc
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $user_home/.oh-my-zsh/custom/themes/powerlevel10k
  # TODO: Meslo font for p10k. See https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k
  chsh -s /bin/zsh $SUDO_USER
}

### Dotfile Fetch/Setup ###
# TODO: Make this cleaner.
config(){ /usr/bin/git --git-dir=$user_home/.cfg/ --work-tree=$user_home $@; }
dotfile_copy(){
  [ ! -d "$user_home/.cfg" ] && /bin/su -c "mkdir $user_home/.cfg" - $SUDO_USER
  /bin/su -c "git clone --bare $dotfile_repo $user_home/.cfg" - $SUDO_USER
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

# Main
warning="WARNING! WARNING! WARNING!\n\nThis is for a FRESHLY INSTALLED system only!\nAre you sure you want to run this?\n\nWARNING! WARNING! WARNING!"
if (whiptail --title "QRBounty's Bootstrap Script 1.5" --yesno "$warning" 15 50); then
  clear
  if linux gnu; then
    if distro "Debian"; then
      try debian_install
    fi
    if exists git; then
      echo "Fetching Dotfiles"
      try dotfile_copy
    else
      err "git not detected, cannot gather dotfiles."
    fi
    if (whiptail --title "QRBounty's Bootstrap Script 1.5" --yesno "Installation has finished. Restart?" 20 60); then
      reboot
    else:
      exit
    fi
  else:
    echo "No supported OS found"
  fi
else
  exit
fi
