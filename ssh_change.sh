#!/bin/bashset -x
sshd_path="/etc/ssh/sshd_config"
sshd_path_2404="/lib/systemd/system/ssh.socket"

# Check if the script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "\e[31mPlease run the script as root (sudo).\e[0m"
        exit 1
    fi
}

# Detect OS and version
detect_os() {
    os_name=$(lsb_release -is 2>/dev/null || grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    os_version=$(lsb_release -rs 2>/dev/null || grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    echo -e "\e[34mDetected system: ${os_name} ${os_version}\e[0m"
}

manual_port() {

    local current_port=$(get_current_port ${sshd_path})
    echo -e "\e[33mCurrent SSH port: ${current_port}\e[0m"
    read -p "Enter a new port for SSH (1-65535): " new_port

    if ! [[ ${new_port} =~ ^[0-9]+$ ]] || [ ${new_port} -lt 1 ] || [ ${new_port} -gt 65535 ]; then
        echo -e "\e[31mError: Port must be a number between 1 and 65535.\e[0m"
        exit 1
    fi
    echo -e "\e[33mEntered port ${new_port}\e[0m"
    check_port_availability ${new_port}
}

# Get the current SSH port from a config file
get_current_port() {
    local config_file=$1
    if [ -f "${config_file}" ]; then
        grep -Po '(?<=^Port )\d+' "${config_file}" || echo "22"
    else
        echo "22"
    fi
}

# Change the port in the config file
change_port_in_config() {
    local config_file=$1
    local port=$2
    if [ -f "${config_file}" ]; then
        sed -i "s/^#Port 22/Port ${port}/" "${config_file}"
        sed -i "s/^Port [0-9]\+/Port ${port}/" "${config_file}"
        echo -e "\e[32mPort was changed in the file: ${config_file}\e[0m"
        echo -e "\e[32mNew port: ${port}\e[0m"
    fi
}

# Reload the SSH service
reload_ssh_service() {
    if command -v systemctl > /dev/null; then
        systemctl daemon-reload
        systemctl restart ssh || systemctl restart sshd
    else
        service ssh restart || service sshd restart
    fi
    echo -e "\e[32mRestart ssh\e[0m"
}

# Check if the port is available
check_port_availability() {
    if ss -tuln | grep -q ":${new_port}"; then
        echo -e "\e[31mError: Port ${port} is already in use by another process.\e[0m"
        exit 1
    fi
}

# Change the SSH port for Ubuntu 24.04
change_port_ubuntu_2404() {
    local current_port=$(get_current_port ${sshd_path_2404})
    echo -e "\e[33mCurrent SSH port: ${current_port}\e[0m"
    
    sed -i "s/^ListenStream=.*/ListenStream=${new_port}/" ${sshd_path_2404}
    change_port_in_config "${sshd_path}" "${new_port}"
    reload_ssh_service
    
    echo -e "\e[32mSSH port successfully changed to ${new_port}.\e[0m"
}

# Change the SSH port for other systems
change_port_other_systems() {
    local current_port=$(get_current_port ${sshd_path})
    echo -e "\e[33mCurrent SSH port: ${current_port}\e[0m"
     
    change_port_in_config "${sshd_path}" "${new_port}"
    reload_ssh_service
    
    echo -e "\e[32mSSH port successfully changed to ${new_port}.\e[0m"
}

regenerate_key() {
    rm /etc/ssh/ssh_host_*
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
    echo -e "\nHostKey /etc/ssh/ssh_host_ed25519_key\nHostKey /etc/ssh/ssh_host_rsa_key" >> /etc/ssh/sshd_config
    cp /etc/ssh/moduli /etc/ssh/moduli.backup
    awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
    mv /etc/ssh/moduli.safe /etc/ssh/moduli
    echo -e "# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\n KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,gss-curve25519-sha256-,diffie-hellman-group16-sha512,gss-group16-sha512-,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\n\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-gcm@openssh.com,aes128-ctr\n\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\n\nHostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nRequiredRSASize 3072\n\nCASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nGSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-\n\nHostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256\n\nPubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256\n\n" > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf
    echo -e "\e[32mKeys created, modules and security algorithms changed\e[0m"
}

change_sshdconfig() {
    cp ${sshd_path} ${sshd_path}.backup
    wget "https://raw.githubusercontent.com/LungTaS/linux_script/main/sshd_config" -q -O  ${sshd_path}
    echo -e "\e[32mReplaced ${sshd_path}\e[0m"
}

# Main function
main() {
    check_root
    detect_os
    manual_port

    case "${os_name}" in
        Ubuntu)
            if [[ "${os_version}" == "24.04" ]]; then
                change_sshdconfig    
                regenerate_key
                change_port_ubuntu_2404
            else
                change_sshdconfig
                regenerate_key
                change_port_other_systems
            fi
            ;;
        CentOS|Fedora|RHEL|Debian)
            change_sshdconfig
            regenerate_key
            change_port_other_systems
            ;;
        *)
            echo -e "\e[31mOperating system not supported by this script.\e[0m"
            exit 1
            ;;
    esac
}

# Run the main function
main