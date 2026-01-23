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