#!/usr/bin/env bash
#######################
#### Get variables ####
#######################


MODSECURITY_GIT="https://github.com/owasp-modsecurity/ModSecurity.git"
MODSECURITY_NGINX_GIT="https://github.com/SpiderLabs/ModSecurity-nginx.git"
NGINX_VERSION=$(nginx -v 2>&1 | grep -o '[0-9.]*')

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LOG_FILE="${CURRENT_DIR}/.dhl_install_log.txt"

fun_modSecure_remove(){
 echo -e "${COLOR_YELLOW} Remove installation.${COLOR_NC}"
}

fun_modSecure_install(){
   # Remove any old MOd_Sec install. Ensure new install is good.
    fun_modSecure_remove

    apt-get install -y wget tar apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre2-dev libtool libxml2 libxml2-dev libssl-dev libyajl-dev pkgconf zlib1g-dev

    # Clone the ModSecurity repository
    git clone "${MODSECURITY_GIT}"
    cd ModSecurity/
    git submodule init
    git submodule update

    # Build and install  ModSecurity repository
    ./build.sh
    ./configure --with-pcre2
    make no-test
    make no-test install

    cd ../

    # Clone the ModSecurity-nginx repository
    git clone "${MODSECURITY_NGINX_GIT}"

    # Download and extract Nginx source code
    wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    tar zxvf nginx-$NGINX_VERSION.tar.gz && \
    cd nginx-$NGINX_VERSION

    # Configure Nginx with ModSecurity module
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx

    #build the module
    make no-test modules

    cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

    #load_module modules/ngx_http_modsecurity_module.so;

    apt-get autoremove -y
}

fun_checkForInstallErrors() {
    # This function checks for error. Error can be noted in install log if a command run with "fun_priorityCMD" fails.
    # Other erro may occur, but only command run with "fun_priorityCMD" will generate '!FAIL!' message in the log.
    if [[ $(grep -c '!FAIL!' "${LOG_FILE}") -gt 0 ]]; then
        echo -e "${COLOR_RED} Errors during install occured. Please review the log.${COLOR_NC}"
        echo -e "${COLOR_RED} Errors listed below.${COLOR_NC}"
        echo -e "${COLOR_RED}--------------------------------${COLOR_NC}"
        grep '!FAIL!' "${LOG_FILE}"
        echo -e "${COLOR_RED}--------------------------------${COLOR_NC}"
    else
        echo -e "${COLOR_BGREEN} All success.${COLOR_NC}"
    fi
}

func_install(){

    # Add the start time to the install log
      echo "Start Install Time $(date)" | tee -a -i -- "${LOG_FILE}"

      # Install and config Mod_Secure
      fun_modSecure_install


    # Check if there was errors during install.
    fun_checkForInstallErrors

      # Log the installed version
      echo "VERSION:${LOG_FILE}" | tee -a -i -- "${LOG_FILE}"

      # Add the end time to the install log.
      echo "END Install Time $(date)" | tee -a -i -- "${LOG_FILE}"

}

# Check if root privlages are given, if not get root rights.
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

func_install

exit 0
# End Script
