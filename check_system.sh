#!/bin/bash
# Функция для проверки информации о системе
check_system_info() {
    echo -e "\e[36m=== Проверка информации о системе ===\e[0m"
    
    # Проверка имени дистрибутива
    if [ -f /etc/os-release ]; then
        # Современные дистрибутивы используют /etc/os-release
        DIST_NAME=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        DIST_VERSION=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        DIST_PRETTY_NAME=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        
        echo -e "\e[32mДистрибутив:\e[0m ${DIST_PRETTY_NAME}"
        echo -e "\e[32mИмя дистрибутива:\e[0m ${DIST_NAME}"
        echo -e "\e[32mВерсия дистрибутива:\e[0m ${DIST_VERSION}"
    elif [ -f /etc/redhat-release ]; then
        # Red Hat, CentOS, Fedora (старые версии)
        DIST_INFO=$(cat /etc/redhat-release)
        DIST_NAME=$(echo $DIST_INFO | awk '{print $1}')
        DIST_VERSION=$(echo $DIST_INFO | awk '{print $3}' | cut -d'.' -f1)
        
        echo -e "\e[32mДистрибутив:\e[0m ${DIST_INFO}"
        echo -e "\e[32mИмя дистрибутива:\e[0m ${DIST_NAME}"
        echo -e "\e[32mВерсия дистрибутива:\e[0m ${DIST_VERSION}"
    elif [ -f /etc/debian_version ]; then
        # Debian
        DIST_NAME="debian"
        DIST_VERSION=$(cat /etc/debian_version)
        
        echo -e "\e[32mДистрибутив:\e[0m Debian"
        echo -e "\e[32mИмя дистрибутива:\e[0m ${DIST_NAME}"
        echo -e "\e[32mВерсия дистрибутива:\e[0m ${DIST_VERSION}"
    else
        echo -e "\e[31mНе удалось определить дистрибутив\e[0m"
        DIST_NAME="unknown"
        DIST_VERSION="unknown"
    fi
    
    # Проверка версии ядра
    KERNEL_VERSION=$(uname -r)
    KERNEL_RELEASE=$(uname -v)
    
    echo -e "\e[32mВерсия ядра:\e[0m ${KERNEL_VERSION}"
    echo -e "\e[32mИнформация о сборке ядра:\e[0m ${KERNEL_RELEASE}"
    
    echo -e "\e[36m======================================\e[0m"
    
    # Возвращаем значения для использования в других скриптах
    export DIST_NAME
    export DIST_VERSION
    export KERNEL_VERSION
}

# Запуск проверки
check_system_info
