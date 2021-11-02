#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
PATH_BIN="/usr/local/bin"
MINIMUM_HELMFILE_VERSION=v0.141.0



check_helmfile_installed() {
  # If helmfile is not available on the path, get it
  if ! [ -x "$(command -v helmfile)" ]; then
    echo 'helmfile not found, installing'
    install_helmfile
  fi
}


verify_helmfile_version() {

  local helmfile_version
  helmfile_version="v$(helmfile version | grep -Eo "([0-9]{1,}\.)+[0-9]{1,}")"
  if [[ "${MINIMUM_HELMFILE_VERSION}" != $(echo -e "${MINIMUM_HELMFILE_VERSION}\n${helmfile_version}" | sort -s -t. -k 1,1n -k 2,2n -k 3,3n | head -n1) ]]; then
    cat <<EOF
Detected helmfile version: ${helmfile_version}.
Requires ${MINIMUM_HELMFILE_VERSION} or greater.
Please install ${MINIMUM_HELMFILE_VERSION} or later.

EOF
    
    confirm "$@" && echo 'Installing Helmfile' && install_helmfile
  else
    cat <<EOF
Detected helmfile version: ${helmfile_version}.
Requires ${MINIMUM_HELMFILE_VERSION} or greater.
Nothing to do!

EOF
  fi
}

confirm() {
    # call with a prompt string or use a default
    echo "${1:-Do you want to install? [y/N]}"
    read -r -p "" response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            return 2
            ;;
    esac
}

install_helmfile() {
    if [[ "${OSTYPE}" == "linux"* ]]; then
      curl -sLo "helmfile" https://github.com/roboll/helmfile/releases/download/${MINIMUM_HELMFILE_VERSION}/helmfile_linux_amd64
      copy_binary
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      curl -sLo "helmfile" https://github.com/roboll/helmfile/releases/download/${MINIMUM_HELMFILE_VERSION}/helmfile_darwin_amd64
      copy_binary
    else
      set +x
      echo "The installer does not work for your platform: $OSTYPE"
      exit 1
    fi
}

function copy_binary() {
  if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
      if [ ! -d "$HOME/.local/bin" ]; then
        mkdir -p "$HOME/.local/bin"
      fi
      mv helmfile "$HOME/.local/bin/helmfile"
      chmod +x "$HOME/.local/bin/helmfile"
  else
      echo "Installing Helmfile to /usr/local/bin which is write protected"
      echo "If you'd prefer to install Helmfile without sudo permissions, add \$HOME/.local/bin to your \$PATH and rerun the installer"
      sudo mv helmfile /usr/local/bin/helmfile
      chmod +x "/usr/local/bin/helmfile"
  fi
  echo "Installation Finished"
}


check_helmfile_installed "$@"
verify_helmfile_version "$@"