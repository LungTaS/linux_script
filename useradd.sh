# Check if the script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "\e[31mPlease run the script as root (sudo).\e[0m"
        exit 1
    fi
}

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