#!/bin/bashset -x
REPO_DIR="$HOME/repo"
# Проверка, запущен ли скрипт от имени root
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease run the script as root (sudo).\e[0m"
    exit 1
fi

# Ставим git
# Обновление списка пакетов
apt update
apt upgrade -y
apt autoremove
apt dist-upgrade 
# Установка sudo
apt install -y git zsh mc neofetch bat exa duf fd sudo fail2ban

echo -e "\e[31mКлонирование репы\e[0m"
git clone https://github.com/LungTaS/linux_script.git temp

if [ ! -d ${REPO_DIR} ]; then
  mkdir ${REPO_DIR}
  echo "Папка repo создана."
else
  echo "Папка repo уже существует."
fi
# копирование содержимого временной директории и удаление
cp -rf temp/* ${REPO_DIR}
rm -rf temp
chmod +x -R ${REPO_DIR}
# Переход в repo
cd ${REPO_DIR} || { echo "Не удалось перейти в каталог $REPO_DIR"; exit 1; }

# Настройка zsh
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
mv zsh-syntax-highlighting ~/.oh-my-zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions
mv zsh-autosuggestions ~/.oh-my-zsh/custom/plugins

# Путь к файлу .zshrc
ZSHRC_FILE="$HOME/.zshrc"

# Проверяем, существует ли файл
if [[ -f "$ZSHRC_FILE" ]]; then
    # Используем sed для замены ZSH_THEME
    sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="bira"/' "$ZSHRC_FILE"
    sed -i 's/^plugins=(.*/(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC_FILE"
    echo "Тема ZSH изменена на 'bira'. Добавлены плагины. Резервная копия .zshrc сохранена как .zshrc.bak."
else
    echo "Файл $ZSHRC_FILE не найден."
fi

#plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
# Запрос имени нового пользователя
read -p "Enter the username for the new user: " username

# Создание нового пользователя с домашней директорией
useradd -m -s /bin/bash ${username}

# Проверка, успешно ли был создан пользователь
if [ $? -ne 0 ]; then
    echo -e "\e[31mFailed to create user ${username}.\e[0m"
    exit 1
fi

# Установка пароля для нового пользователя
passwd "$username"

# Добавление пользователя в группу sudo
usermod -aG sudo ${username}

# Проверка, успешно ли пользователь был добавлен в группу sudo
if [ $? -eq 0 ]; then
    echo -e "\e[32mUser ${username} has been created and added to the sudo group.\e[0m"
else
    echo -e "\e[31mFailed to add user ${username} to the sudo group.\e[0m"
    exit 1
fi

# Создание каталога .ssh
mkdir -p /home/${username}/.ssh

# Установка прав на каталог .ssh
chmod 700 /home/${username}/.ssh

# Создание файла authorized_keys
touch /home/${username}/.ssh/authorized_keys

# Установка прав на файл authorized_keys
chmod 600 /home/${username}/.ssh/authorized_keys

# Установка владельца для каталога и файла
chown -R ${username}:${username} /home/${username}/.ssh

echo -e "\e[32mDirectory and authorized_keys file created successfully with the correct permissions.\e[0m"

echo -e "\e[32mНастройка ssh\e[0m"
./ssh_change.sh
echo -e "\e[32mНастройка ssh произведены\e[0m"