#!/usr/bin/env bash

#######################
#### Global Variables ####
#######################
readonly MODSECURITY_GIT="https://github.com/owasp-modsecurity/ModSecurity.git"
readonly MODSECURITY_NGINX_GIT="https://github.com/SpiderLabs/ModSecurity-nginx.git"
readonly NGINX_VERSION=$(nginx -v 2>&1 | grep -o '[0-9.]*')
readonly CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
readonly LOG_FILE="${CURRENT_DIR}/.dhl_install_log.txt"

# Color codes for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_NC='\033[0m' # No Color
readonly COLOR_BGREEN='\033[1;32m'

# Installation paths
readonly NGINX_MODULE_PATH="/etc/nginx/modules"
readonly MODSEC_INSTALL_PATH="/usr/local/modsecurity"
readonly DEPENDENCIES=(
    wget
    tar
    apt-utils
    autoconf
    automake
    build-essential
    git
    libcurl4-openssl-dev
    libgeoip-dev
    liblmdb-dev
    libpcre2-dev
    libtool
    libxml2
    libxml2-dev
    libssl-dev
    libyajl-dev
    pkgconf
    zlib1g-dev
)

#######################
#### Helper Functions ####
#######################
log_message() {
    local message="$1"
    local type="${2:-INFO}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$type] $message" | tee -a "$LOG_FILE"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_message "Command '$1' not found. Please install it first." "ERROR"
        return 1
    fi
}

#######################
#### Main Functions ####
#######################
fun_modSecure_remove() {
    log_message "Starting ModSecurity removal" "INFO"
    
    # Stop nginx
    systemctl stop nginx

    # Remove ModSecurity files
    rm -rf /usr/local/modsecurity/
    rm -rf "${CURRENT_DIR}/ModSecurity"
    rm -rf "${CURRENT_DIR}/ModSecurity-nginx"
    rm -f "${NGINX_MODULE_PATH}/ngx_http_modsecurity_module.so"
    rm -f "${CURRENT_DIR}/nginx-${NGINX_VERSION}.tar.gz"
    rm -rf "${CURRENT_DIR}/nginx-${NGINX_VERSION}"

    # Remove ModSecurity configuration
    sed -i '/load_module.*ngx_http_modsecurity_module.so/d' /etc/nginx/nginx.conf
    sed -i '/modsecurity on/d' /etc/nginx/nginx.conf
    sed -i '/modsecurity_rules_file/d' /etc/nginx/nginx.conf

    # Restart nginx
    systemctl restart nginx

    log_message "ModSecurity has been removed successfully" "SUCCESS"
}

fun_modSecure_install() {
    log_message "Starting ModSecurity installation" "INFO"

    # Check for required commands
    check_command nginx || return 1
    check_command git || return 1

    # Create necessary directories
    mkdir -p "${NGINX_MODULE_PATH}"
    mkdir -p "${MODSEC_INSTALL_PATH}"

    # Install dependencies
    log_message "Installing dependencies" "INFO"
    apt-get update
    apt-get install -y "${DEPENDENCIES[@]}"

    # Clone and build ModSecurity
    log_message "Building ModSecurity" "INFO"
    git clone --depth 1 "${MODSECURITY_GIT}"
    cd ModSecurity/ || exit 1
    git submodule init
    git submodule update
    ./build.sh
    ./configure --with-pcre2
    make -j"$(nproc)" no-test
    make install
    cd ../ || exit 1

    # Clone and build ModSecurity-nginx connector
    log_message "Building ModSecurity-nginx connector" "INFO"
    git clone --depth 1 "${MODSECURITY_NGINX_GIT}"
    wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
    tar xzf "nginx-${NGINX_VERSION}.tar.gz"
    cd "nginx-${NGINX_VERSION}" || exit 1
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx
    make -j"$(nproc)" modules
    cp objs/ngx_http_modsecurity_module.so "${NGINX_MODULE_PATH}/"
    cd ../ || exit 1

    # Clean up
    apt-get autoremove -y
    apt-get clean

    log_message "ModSecurity installation completed" "SUCCESS"
}

fun_checkForInstallErrors() {
    if grep -q '!FAIL!' "${LOG_FILE}"; then
        log_message "Installation errors detected:" "ERROR"
        grep '!FAIL!' "${LOG_FILE}" | while read -r line; do
            echo -e "${COLOR_RED}$line${COLOR_NC}"
        done
        return 1
    fi
    log_message "Installation completed successfully" "SUCCESS"
    return 0
}

#######################
#### Main Execution ####
#######################
main() {
    # Check for root privileges
    if [[ $EUID -ne 0 ]]; then
        log_message "This script must be run as root" "ERROR"
        exit 1
    }

    # Process command line arguments
    case "$1" in
        --install)
            log_message "Starting installation process" "INFO"
            fun_modSecure_install
            fun_checkForInstallErrors
            ;;
        --remove)
            log_message "Starting removal process" "INFO"
            fun_modSecure_remove
            ;;
        *)
            echo "Usage: $0 [--install|--remove]"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
