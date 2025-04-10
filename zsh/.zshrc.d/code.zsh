#!/bin/zsh

# Allow code to run unnagged in WSL
export DONT_PROMPT_WSL_INSTALL=1

CONFIG="${HOME}/.config/dotfiles/code"
alias codeini="git config -f $CONFIG"

_codepath=$(codeini --get code.path || echo "${HOME}/.local/bin")
eval _codepath=$(echo ${_codepath})

_installcodiumserverdownload() {
    local install_location="$1"
  
    API_URL="https://api.github.com/repos/VSCodium/vscodium/releases/latest"
    response=$(curl -s "$API_URL")
    download_url=$(echo "$response" | grep -oP '(?<="browser_download_url": ")[^"]*vscodium-reh-web-linux-x64[^"]*.tar.gz(?!.*sha)')
    version=$(echo "$download_url" | grep -oP '(?<=/download/)[^/]+')

    if [[ -z "$download_url" ]]; then
        echo "Download URL not found"
        return
    fi

    temp_file=$(mktemp)
    curl -L -o "$temp_file" "$download_url"
  
    install_dir="$install_location/$version"
    mkdir -p "$install_dir"
    tar -xzf "$temp_file" -C "$install_dir"
    ln -sfn "$install_dir" "$install_location/latest"
    rm "$temp_file"
}

_installcodiumserversystem() {
    install_location=/opt/codium
    _installcodiumserverdownload $install_location
    sudo ln -sfn "$install_location/latest/bin/codium-server" "/usr/bin/codium-server"
}

_installcodiumserveruser() {
    install_location=${HOME}/.codium
    _installcodiumserverdownload $install_location
    ln -sfn "$install_location/latest/bin/codium-server" "${HOME}/.local/bin/codium-server"
}

alias install-codiumserver-user="_installcodiumserveruser"
alias install-codiumserver-system="_installcodiumserversystem"

_codeexists() {
    if [ -f "${_codepath}/code" ]; then
        return 0  # File exists, return true (0)
    else
        return 1  # File does not exist, return false (1)
    fi
}

_installcode() {
    # does not handle architecture yet
    arch=$(uname -m)
    case "$arch" in
      x86_64)
        download_target="x64"
        ;;
      i386 | i686)
        download_target="x86"
        ;;
      armv7l)
        download_target="arm32"
        ;;
      aarch64)
        download_target="arm64"
        ;;
      *)
        echo "Unsupported architecture: $arch"
        return 1
        ;;
    esac

    echo "Installing code-cli for: ${download_target}"
    tempfile=$(mktemp)
    curl -fsSL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-${download_target}" -o ${tempfile}
    tar -zxvf ${tempfile} -C ${_codepath} > /dev/null 2>&1
    rm -f ${tempfile}
}

_installcodesystemduser() {
    mkdir -p ~/.config/systemd/user/
    #https://github.com/gbraad-vscode/code-systemd/blob/main/README.md
    curl -fsSL  https://raw.githubusercontent.com/gbraad-vscode/codecli-systemd/refs/heads/main/user/code-serveweb.service \
        -o ~/.config/systemd/user/code-serveweb.service
    curl -fsSL  https://raw.githubusercontent.com/gbraad-vscode/codecli-systemd/refs/heads/main/user/code-tunnel.service   \
        -o ~/.config/systemd/user/code-tunnel.service
    systemctl --user daemon-reload
}

_startcodetunnel() {
    if ! _codeexists; then
        _installcode
    fi

    if [ -z "${HOSTNAME}" ]; then
        echo "HOSTNAME not set"
	return 1
    fi

    screen ${_codepath}/code tunnel --accept-server-license-terms --name ${HOSTNAME}
}

_startcodeserveweb() {
    if ! _codeexists; then
        _installcode
    fi
    local host=$(codeini --get code.host || echo "0.0.0.0")
    local port=$(codeini --get code.port || echo "8000")

    screen ${_codepath}/code serve-web --without-connection-token --host ${host} --port ${port}
}

alias install-code="_installcode"
alias install-code-systemd-user="_installcodesystemduser"
alias start-code-tunnel="_startcodetunnel"
alias start-code-serveweb="_startcodeserveweb"

_installcodeifmissing() {
    if ! _codeexists; then
        _installcode
    fi
}

if [[ $(codeini --get "code.autoinstall") == true ]]; then
  _installcodeifmissing
fi
