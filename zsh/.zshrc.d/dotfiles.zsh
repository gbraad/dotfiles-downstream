#!/bin/zsh

install() {
  # Personal dotfiles
  git clone https://github.com/gbraad/dotfiles.git ~/.dotfiles
  cd ~/.dotfiles
  git submodule update --init --progress

  # stow the configurations
  stow powerline
  stow zsh
  stow tmux
  stow vim
  #stow git
  stow i3

  # stow wsl specific stuff
  if grep -qi Microsoft /proc/version; then
    stow wsl
  fi

  # stow cygwin specific stuff
  if [ "$OSTYPE" = "cygwin" ]
  then
    stow cygwin
  fi
}

# Temporary including the old installation method
oldinstall() {
  APTPKGS="git zsh stow"
  RPMPKGS="git-core zsh stow"

  # Crude multi-os installation option
  if [ -x "/usr/bin/apt-get" ]
  then
    sudo apt-get install -y $APTPKGS
  elif [ -x "/usr/bin/dnf" ]
  then
    sudo dnf install -y $RPMPKGS
    
    # allow first-time system install
    export SYSTEM_INSTALL=1
  elif [ -x "/usr/bin/yum" ]
  then
    sudo yum install -y $RPMPKGS
  fi

  # Add missing directory layout
  if [ ! -d "~/.config" ]
  then
    mkdir -p ~/.config
  fi

  mkdir -p ~/.local/bin
  mkdir -p ~/.local/lib/python2.7/site-packages/

  install
}

if [[ "$0" == *install.sh* ]]; then
    echo "Performing install"
    oldinstall
    exit 0
fi

CONFIG="${HOME}/.dot"
alias dotini="git config -f $CONFIG"

dotfiles() {
  if [ $# -lt 1 ]; then
    echo "Usage: $0 <command> [args...]"
    return 1
  fi

  local COMMAND=$1

  case "$COMMAND" in
    "up" | "update")
      cd ~/.dotfiles
      git pull
      cd -
      ;;
    "in" | "install")
      install
      ;;
    *)
      echo "Unknown command: $0 $COMMAND"
      ;;
  esac
}

if [[ $(dotini --get "dotfiles.aliases") == true ]]; then
  alias dot="dotfiles"
  alias dotup="dot up"
fi

if [[ $(dotini --get "dotfiles.autoupdate") == true ]]; then
  dotfiles up
fi
