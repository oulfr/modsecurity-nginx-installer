# ModSecurity with Nginx Installation Script

This script automates the installation of [ModSecurity](https://github.com/SpiderLabs/ModSecurity) and the ModSecurity Nginx Connector. It also builds the dynamic Nginx module for ModSecurity and provides instructions for integrating ModSecurity with Nginx.

## Features

- Downloads and installs ModSecurity and its dependencies
- Clones the ModSecurity and ModSecurity Nginx Connector repositories
- Builds and installs the ModSecurity module for Nginx
- Provides a sample Nginx configuration to enable ModSecurity

## Prerequisites

- A server running a Debian-based Linux distribution
- `nginx` already installed on the system
- Sudo/root privileges

## Installation Steps

1. Clone this repository or download the script file:
```bash
git clone https://github.com/your-repo/modsecurity-nginx-installer.git
cd modsecurity-nginx-installer
```

2. Make the script executable:
```bash
chmod +x install_modsecurity_nginx.sh
```

3. Run the script as root or with sudo:
```bash
sudo ./install_modsecurity_nginx.sh
```

4. Follow the on-screen instructions. The script will:
   - Install the required dependencies
   - Build and install ModSecurity
   - Build and integrate the ModSecurity Nginx module

## Nginx Configuration

### Load the ModSecurity Module
Add the following line to the top of your nginx.conf file:
```nginx
load_module modules/ngx_http_modsecurity_module.so;
```

### Example nginx.conf:
```nginx
user                 www-data;
worker_processes     auto;
worker_rlimit_nofile 65535;
error_log            /var/log/nginx/error.log;
pid                  /run/nginx.pid;

include              /etc/nginx/conf.d/main/*.conf;
include              /etc/nginx/modules-enabled/*.conf;

# Worker configuration
events {
    worker_connections 1024;
    use                epoll;
    multi_accept       on;
}

http {
    # Enable ModSecurity
    modsecurity on;
    modsecurity_rules_file /etc/nginx/conf/modsecurity.conf;

    # Additional HTTP configuration here
}
```

### Apply Changes
Reload Nginx to apply the changes:
```bash
sudo systemctl reload nginx
```

## Logs and Troubleshooting

- Installation logs are saved in .dhl_install_log.txt in the same directory as the script
- If errors occur during installation, review the log file for details
- Check if ModSecurity is enabled:
```bash
nginx -V 2>&1 | grep -o ngx_http_modsecurity_module
```

## Dependencies

- wget
- tar
- autoconf
- automake
- build-essential
- git
- Additional libraries required to build ModSecurity and Nginx modules

## Additional Notes

- Ensure that the nginx.conf file references the correct ModSecurity configuration file (/etc/nginx/conf/modsecurity.conf)
- To uninstall the script's changes, clean up installed files and remove the dynamic module from the Nginx configuration

## License

This script is distributed under the MIT License. Contributions and issues are welcome!
