#!/bin/bash
#
# This is a setup script for my systems.
#
# TODO: OSX install tasks
# TODO: Add dry run functionality
# TODO: Move open-vm-tools package to an installer that will actually detect if it's a VM...
set -e

if [ "$EUID" -ne 0 ]
  then echo "Please run as root using sudo. User-specific data will be assigned to the user you are sudoing from."
  exit
fi
user_home=$(getent passwd $SUDO_USER | cut -d: -f6)


### User Variables - EDIT THESE! :) ###
# dotfile_repo - Your dotfiles repository, make sure it looks like https://github.com/qrbounty/dotfiles
# deb_apt_pkgs - The base packages you want installed using debian's apt. These will all be installed in one command.
# pip3_pkgs    - The pip3 packages to install for Python 3. These will all be installed in one command.
# deb_custom_pkgs - This is just a nice way to chunk up packages logically, for quicker on/off and testing.

dotfile_repo="https://www.github.com/qrbounty/dotfiles.git"
deb_apt_pkgs="curl git python3 python3-pip suckless-tools tmux vim "
pip3_pkgs="yara"
declare -a deb_custom_pkgs=(
  # Terminal stuff
  "zsh fonts-powerline fonts-font-awesome"

  # Desktop environment
  "xorg i3 i3blocks kitty lightdm rofi feh"
  
  # Reverse engineering
  "binwalk gdb radare2"
  
  # Fuzzing, etc.
  "afl"
  
  # Fonts
  "fonts-hack"
  
  # VMware Tools (TODO: Move me!)
  "open-vm-tools-desktop"
)


### Helpers / Formatters ###
# Sources: 
# https://brettterpstra.com/2015/02/20/shell-trick-printf-rules/
# https://stackoverflow.com/questions/394230/how-to-detect-the-os-from-a-bash-script 
# https://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs
# https://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
rule() { printf -v _hr "%*s" $(tput cols) && echo ${_hr// /${1--}}; }
rulem() { printf -v _hr "%*s" $(tput cols) && echo -en ${_hr// /${2--}} && echo -e "\r\033[2C$1"; }
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
apt_install() {
  echo "Installing $1 package set (contains: $2) ... "
  DEBIAN_FRONTEND=noninteractive apt-get install -qq $2 < /dev/null > /dev/null && echo "Complete!"
}

### Installer Functions ###
pip3_install() { pip3 -q install $pip3_pkgs; < /dev/null > /dev/null && echo "Installed!"; }

debian_install() {
  # Apt stuff, desktop environment
  apt-get update < /dev/null > /dev/null
  apt_install "base" "$deb_apt_pkgs"
  
  for package in "${deb_custom_pkgs[@]}"; do
    apt_install "custom" "$package"
  done
  echo 'exec i3' > $user_home/.xsession
  echo lightdm shared/default-x-display-manager select lightdm | sudo debconf-set-selections -v
  dpkg-reconfigure lightdm
  
  # Zsh install
  rulem "Installing Oh My Zsh"
  /bin/su -c "wget -q https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O - | sh > /dev/null" - $SUDO_USER
  cp $user_home/.oh-my-zsh/templates/zshrc.zsh-template $user_home/.zshrc
  chsh -s /bin/zsh $SUDO_USER
  
  # VS Code install
  rulem "Installing VS Code"
  curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
  sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  apt_install "VS Code Deps" apt-transport-https
  apt-get update < /dev/null > /dev/null
  apt_install "VS Code Core" code
  rm packages.microsoft.gpg
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
}

###  Main  ###
rule "-"
printf "QRBounty's System Bootstrap Script Version 1.2\n"
rule "-"

printf "\n"
rulem "!!!WARNING!!!" "#"
printf "\nWARNING: THIS WILL OVERWRITE LOCAL FILES!\nThis is for FRESHLY INSTALLED systems only!\n\n"
rule "#"

echo "Really continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done


if os darwin; then
  if ! exists brew; then
    echo "Brew installed... This is where I would install other programs, IF I HAD ANY!"
  else
    echo "Installing Brew..."
  fi 
elif linux gnu; then
  if distro "Debian"; then
    rulem "Debian Customization" "~"
    rulem "Installing Debian software" 
    try debian_install
    rulem "Installing pip3 packages" 
    try pip3_install
  fi
  if distro "Kali"; then
    rulem "Kali Customization" "~"
  fi
  if exists git; then
    rulem "Fetching Dotfiles" "~"
    try dotfile_copy
  else
    err "git not detected, cannot gather dotfiles."
  fi
fi

rule "~"
echo "Installation has finished. Restart system?"
rule "~"

select yn in "Yes" "No"; do
    case $yn in
        Yes ) reboot;;
        No ) exit;;
    esac
done
