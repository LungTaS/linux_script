#!/bin/bash
set -euo pipefail

# ------------------------------
# Переменные
# ------------------------------
SSH_PORT=2222
SWAPFILE="/swapfile"
DASHBOARD_FILE="/etc/update-motd.d/99-dashboard"
SSHD_CONFIG_DIR="/etc/ssh/sshd_config.d"

export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
  echo "Запустите скрипт от root."
  exit 1
fi

# ------------------------------
# 1. Обновление и базовые пакеты
# ------------------------------
apt update
apt upgrade -y
apt install -y curl wget ufw fail2ban vnstat net-tools htop unzip jq vim gnupg

# ------------------------------
# 2. Swap (1 ГБ — оптимально для 1 ГБ RAM и 10 ГБ диска)
# ------------------------------
if [ ! -f "$SWAPFILE" ]; then
  # fallocate может не работать на некоторых ФС (ZFS, некоторые конфигурации XFS)
  fallocate -l 1G "$SWAPFILE" 2>/dev/null || dd if=/dev/zero of="$SWAPFILE" bs=1M count=1024
  chmod 600 "$SWAPFILE"
  mkswap "$SWAPFILE"
  swapon "$SWAPFILE"
  echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
fi

# ------------------------------
# 3. Базовое упрочнение sysctl
# ------------------------------
cat > /etc/sysctl.d/99-hardening.conf <<'EOF'
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.all.accept_source_route=0
kernel.randomize_va_space=2
# Для серверов с малым объёмом RAM: использовать swap только в крайнем случае
vm.swappiness=10
EOF
sysctl --system

# ------------------------------
# 3.5. Проверка наличия SSH-ключей перед отключением паролей
# ------------------------------
if ! grep -rqsE '^(ssh-|ecdsa-|sk-)' /home/*/.ssh/authorized_keys /root/.ssh/authorized_keys 2>/dev/null; then
  echo "=========================================="
  echo "ВНИМАНИЕ: authorized_keys не найдены!"
  echo "Отключение PasswordAuthentication заблокирует вам доступ к серверу."
  echo ""
  echo "Действия:"
  echo "1. Добавьте свой публичный ключ в ~/.ssh/authorized_keys"
  echo "2. Перезапустите скрипт"
  echo "=========================================="
  exit 1
fi

# ------------------------------
# 4. SSH Hardening
# ------------------------------
mkdir -p "$SSHD_CONFIG_DIR"

# 4.1. Основные директивы безопасности
cat > "${SSHD_CONFIG_DIR}/99-custom.conf" <<EOF
Port ${SSH_PORT}
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
# Раскомментируйте и укажите своих пользователей:
# AllowUsers deploy admin
EOF

# 4.2. Полный список алгоритмов SSH Audit для Ubuntu 24.04 LTS
cat > "${SSHD_CONFIG_DIR}/ssh-audit_hardening.conf" <<'EOF'
# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com
# hardening guide.
KexAlgorithms sntrup761x25519-sha512@openssh.com,gss-curve25519-sha256-,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256,gss-group16-sha512-,diffie-hellman-group16-sha512

Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-gcm@openssh.com,aes128-ctr

MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com

RequiredRSASize 3072

HostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256

CASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256

GSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-

HostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256

PubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
EOF

chmod 644 "${SSHD_CONFIG_DIR}/99-custom.conf" "${SSHD_CONFIG_DIR}/ssh-audit_hardening.conf"

# 4.3. Перегенерация host-ключей и удаление слабых DH-модулей
rm -f /etc/ssh/ssh_host_*
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe && mv /etc/ssh/moduli.safe /etc/ssh/moduli

# 4.4. Смена порта в ssh.socket (Ubuntu 24.04)
mkdir -p /etc/systemd/system/ssh.socket.d
cat > /etc/systemd/system/ssh.socket.d/10-port.conf <<EOF
[Socket]
ListenStream=
ListenStream=${SSH_PORT}
EOF
systemctl daemon-reload

# 4.5. Проверка конфигурации и перезапуск SSH
sshd -t
systemctl restart ssh.socket 2>/dev/null || true
systemctl restart ssh || systemctl restart sshd

# ------------------------------
# 5. Fail2Ban (чтение из journalctl)
# ------------------------------
# 5.1. Устанавливаем python3-systemd (ОБЯЗАТЕЛЬНО для backend = systemd)
apt install -y python3-systemd

# 5.2. Настраиваем джейл sshd с backend = systemd
cat > /etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled = true
backend = systemd
port = ${SSH_PORT}
maxretry = 3
bantime = 1h
findtime = 10m
EOF

# 5.3. Перезапускаем и проверяем
# (Ручное изменение journalmatch удалено: в Ubuntu 24.04 дефолтный фильтр уже корректно работает с systemd)
systemctl enable --now fail2ban
systemctl restart fail2ban

# ------------------------------
# 6. UFW
# ------------------------------
ufw default deny incoming
ufw default allow outgoing
ufw allow "${SSH_PORT}"/tcp
ufw --force enable

# ------------------------------
# 7. vnstat
# ------------------------------
systemctl enable --now vnstat

# ------------------------------
# 8. MOTD dashboard
# ------------------------------
# Используем неэкранированный EOF, чтобы подставить ${SSH_PORT},
# но экранируем $(), чтобы команды выполнялись при входе пользователя, а не сейчас.
cat > "$DASHBOARD_FILE" <<EOF
#!/bin/sh
printf "\nWelcome to %s\n" "\$(hostname -f)"
printf " Uptime: %s\n" "\$(uptime -p)"
printf " IPv4: %s\n" "\$(hostname -I | awk '{print \$1}')"
printf " SSH port: ${SSH_PORT}\n"
EOF
chmod +x "$DASHBOARD_FILE"

echo "Готово. Проверьте подключение на порт ${SSH_PORT} в новой сессии, не закрывая текущую."
