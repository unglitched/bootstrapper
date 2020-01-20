# Bootstrapper
A personal bootstrap script for my new systems.

## Purpose
This works in tandem with my dotfiles repo when run on a new system. It will detect the current OS and install the relevant packages and applications needed, as well as pull down my dotfiles.

## Usage
On a new system you should wget/curl bootstrap.sh, examine it and customize it if needed, chmod +x it, and run it as sudo.

Or if you're feeling extremely, extremely dangerous go ahead and `sudo su -c "bash <(wget -qO- https://git.io/JvIcy)"`, just promise you'll tell everyone else to never run random scripts from the internet with bash, particularly with sudo...
