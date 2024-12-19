#!/bin/bashset -x
REPO_DIR="$HOME/repo"
PACKAGES=(
    "git"
    "curl"
    "zsh"
    "mc"
    "neofetch"
    "batcat"
    "exa"
    "duf"
    "sudo"
    "fail2ban"
    "btop"
    "tldr"
    "ripgrep"
)
# Проверка, запущен ли скрипт от имени root
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease run the script as root (sudo).\e[0m"
    exit 1
fi

# Обновление списка пакетов
apt update
apt upgrade -y
apt autoremove
apt dist-upgrade 
# Функция для установки пакета
install_package() {
    local package=$1
    if ! command -v ${package} &> /dev/null; then
        echo -e "e[32mУстанавливаем пакет: ${package}\e[0m"
        sudo apt install -y ${package}
    else
        echo -e "e[33mПакет ${package} уже установлен, переходим к следующему.\e[0m"
    fi
}

# Установка пакетов
for package in "${PACKAGES[@]}"; do
    install_package ${package}
done

echo -e "\e[32Установка завершена.\e[0m"

echo -e "\e[32mКлонирование репы\e[0m"
git clone https://github.com/LungTaS/linux_script.git temp

if [ ! -d ${REPO_DIR} ]; then
  mkdir ${REPO_DIR}
  echo -e "\e[32mПапка repo создана.\e[0m"
else
  echo -e "\e[33mПапка repo уже существует.\e[0m"
fi
# копирование содержимого временной директории и удаление
cp -rf temp/* ${REPO_DIR}
rm -rf temp
chmod +x -R ${REPO_DIR}
# Переход в repo
cd ${REPO_DIR} || { echo -e "\e[31mНе удалось перейти в каталог ${REPO_DIR}\e[0m"; exit 1; }

# Настройка zsh
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
#mv -rf ${REPO_DIR}/zsh-syntax-highlighting ${HOME}/.oh-my-zsh/plugins
#git clone https://github.com/zsh-users/zsh-autosuggestions
#mv -rf ${REPO_DIR}/zsh-autosuggestions ${HOME}/.oh-my-zsh/custom/plugins

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
