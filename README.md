# Bootstrapper
A personal bootstrap script for my new systems.

## Purpose
This works in tandem with my dotfiles repo when run on a new system. It will detect the current OS and install the relevant packages and applications needed, as well as pull down my dotfiles.

## Usage
1. Do a fresh install of your OS (Debian thus far), defaults should be fine however you can deselect any UI stuff if you want.
2. Make your account a member of the sudo group (see Requirements below)
3. `wget https://raw.githubusercontent.com/qrbounty/bootstrapper/master/bootstrap.sh`
4. Examine `bootstrap.sh` and customize as needed
5. `chmod +x bootstrap.sh`
6. `sudo ./bootstrap.sh`
7. After a reboot everything should be complete!

Alternatively, if you're feeling extremely dangerous: `sudo su -c "bash <(wget -qO- https://git.io/JvIcy)"` Just promise you'll tell everyone else to never run random scripts from the internet with bash, particularly with sudo...

## Requirements
If you're a debian user (like me) you'll want to make sure your user is set up to use sudo before continuing.

Debian 9 or older: add the user account to the group sudo with `adduser username sudo`. Where username is your user account.

Debian 10: add the user account to the group sudo with `/sbin/adduser username sudo`. Where username is your user account.
