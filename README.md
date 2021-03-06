<p align="center">
  <img src="https://raw.githubusercontent.com/qrbounty/bootstrapper/master/warning.png">
</p>

# Bootstrapper
A personal bootstrap script for my new systems. From fresh Debian install to ready to work in about 8 minutes.

## Purpose
This works in tandem with my dotfiles repo when run on a new system. It will detect the current OS and install the relevant packages and applications needed, as well as pull down my dotfiles. It is currently scoped to Debian only.

## What It Does
Installation workflow goes like this:
1. Check for & install apt updates
2. Install relevant apt packages
3. Install VMware Tools, if needed.
4. Run custom installer functions. Currently:
    * Selected Python3 packages
    * LightDM
    * Zsh
    * VS Code
    * Bat
    * Grab some random wallpapers
    * Grab user dotfiles
    * Configure Docker & pull down selected images
    * Install VimPlug
5. Reboot - and done!

## Usage
1. Do a fresh install of your OS, defaults should be fine however you can deselect any UI stuff if you want.
2. Make your account a member of the sudo group (see Requirements below)
3. `wget https://raw.githubusercontent.com/qrbounty/bootstrapper/master/bootstrap.sh`
4. Examine `bootstrap.sh` and customize as needed
5. `chmod +x bootstrap.sh`
6. `sudo ./bootstrap.sh`
7. After a reboot everything should be complete!

Alternatively, if you're feeling extremely dangerous, replace steps 3-6 with: `sudo su -c "bash <(wget -qO- https://git.io/JvIcy)"` 

Just promise you'll tell everyone else to never run random scripts from the internet with bash, particularly with sudo...

## Requirements
If you're a debian user (like me) you'll want to make sure your user is set up to use sudo before continuing.

Debian 9 or older: add the user account to the group sudo with `adduser username sudo`. Where username is your user account.

Debian 10: add the user account to the group sudo with `/sbin/adduser username sudo`. Where username is your user account.
