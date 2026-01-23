

#!/bin/bashset -x
PACKAGES=(
    "git"
    "curl"
    "zsh"
    "mc"
    "neofetch"
    "bat"
    "exa"
    "duf"
    "sudo"
    "fail2ban"
    "btop"
    "tldr"
    "ripgrep"
    "ufw"
    
)
# Проверка, запущен ли скрипт от имени root
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease run the script as root (sudo).\e[0m"
    exit 1
fi

# Обновление списка пакетов
apt update
apt upgrade -y
apt autoremove -y
apt dist-upgrade -y

# Функция для установки пакета
install_package() {
    local package=$1
    if ! command -v ${package} &> /dev/null; then
        echo -e "\e[32mУстанавливаем пакет: ${package}\e[0m"
        apt install -y ${package}
    else
        echo -e "\e[33mПакет ${package} уже установлен, переходим к следующему.\e[0m"
    fi
}

# Установка пакетов
for package in "${PACKAGES[@]}"; do
    install_package ${package}
done

echo -e "\e[32Установка завершена.\e[0m"
