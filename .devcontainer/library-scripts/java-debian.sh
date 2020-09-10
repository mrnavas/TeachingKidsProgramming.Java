JAVA_VERSION=${1:-"lts"}
export SDKMAN_DIR=${2:-"/usr/local/sdkman"}
USERNAME=${3:-"vscode"}
UPDATE_RC=${4:-"true"}

set -e

if [ "${JAVA_VERSION}" = "lts" ]; then
    JAVA_VERSION=""
fi

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run a root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

function updaterc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
        echo -e "$1" | tee -a /etc/bash.bashrc >> /etc/zsh/zshrc
    fi
}

export DEBIAN_FRONTEND=noninteractive

if ! dpkg -s curl ca-certificates zip unzip sed > /dev/null 2>&1; then
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ | wc -l)" = "0" ]; then
        apt-get update
    fi
    apt-get -y install --no-install-recommends curl ca-certificates zip unzip sed
fi

if [ ! -d "${SDKMAN_DIR}" ]; then
    curl -sSL "https://get.sdkman.io?rcupdate=false" | bash
    chown -R "${USERNAME}" "${SDKMAN_DIR}"
    updaterc "export SDKMAN_DIR=${SDKMAN_DIR}\nsource \${SDKMAN_DIR}/bin/sdkman-init.sh"
fi

if [ "${JAVA_VERSION}" != "none" ]; then
    su ${USERNAME} -c "source ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk install java ${JAVA_VERSION} && sdk flush archives && sdk flush temp"
fi

echo "Done!"