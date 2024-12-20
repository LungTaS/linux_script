REPO_DIR="$HOME/repo"

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
