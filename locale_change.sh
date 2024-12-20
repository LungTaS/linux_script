#!/bin/bash

set_locale() {
    # Проверяем, есть ли раскомментированная локаль en_US.UTF-8 в /etc/locale.gen
    if ! grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen; then
        echo "\e[31mЛокаль en_US.UTF-8 не найдена в /etc/locale.gen. Добавляем и раскомментируем...\e[0m"
        echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen > /dev/null
    else
        # Проверяем, закомментирована ли локаль
        if grep -q "^#en_US.UTF-8 UTF-8" /etc/locale.gen; then
            echo "\e[31mЛокаль en_US.UTF-8 закомментирована. Раскомментируем...\e[0m"
            sudo sed -i 's/^#$en_US.UTF-8 UTF-8$/\1/' /etc/locale.gen
        fi
    fi

    # Генерируем локаль
    echo "\e[33mГенерируем локаль en_US.UTF-8...\e[0m"
    sudo locale-gen en_US.UTF-8

    # Устанавливаем локаль
    echo "\e[33mУстанавливаем локаль en_US.UTF-8...\e[0m"
    sudo localectl set-locale LANG=en_US.UTF-8

    echo "\e[32mЛокаль успешно установлена на en_US.UTF-8.\e[0m"
}

# Получаем текущую локаль
current_locale=$(locale | grep LANG | cut -d= -f2 | tr -d '"')

# Проверяем, соответствует ли текущая локаль en_US.UTF-8
if [ "$current_locale" != "en_US.UTF-8" ]; then
    echo "\e[32mТекущая локаль: $current_locale\e[0m"
    set_locale
else
    echo "\e[32mТекущая локаль уже установлена на en_US.UTF-8.\e[0m"
fi