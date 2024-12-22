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

# install zsh
check_zsh() {
    local package="zsh"
    if ! command -v ${package} &> /dev/null; then
        echo -e "\e[32mНе установлен ${package}, устанавливаем\e[0m"
        apt install -y ${package}
    else
        echo -e "\e[33mПакет ${package} уже установлен.\e[0m"
    fi
}
check_zsh
# Настройка oh-my-zsh
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git 
mv ${HOME}/zsh-syntax-highlighting ${HOME}/.oh-my-zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions
mv ${HOME}/zsh-autosuggestions ${HOME}/.oh-my-zsh/custom/plugins

# Путь к файлу .zshrc
ZSHRC_FILE="$HOME/.zshrc"

# Проверяем, существует ли файл
if [[ -f "$ZSHRC_FILE" ]]; then
    # Используем sed для замены ZSH_THEME
    sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="bira"/' "$ZSHRC_FILE"
    sed -i 's/^plugins=(.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC_FILE"
    echo -e "\e[32mТема ZSH изменена на 'bira'. Добавлены плагины. Резервная копия .zshrc сохранена как .zshrc.bak.\e[0m"
else
    echo -e "\e[31mФайл $ZSHRC_FILE не найден.\e[0m"
fi
