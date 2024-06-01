FILE="/etc/docker/daemon.json"
# Переменные для цветов
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Проверка существования файла
if [ -f "$FILE" ];
then
    echo "${RED}${FILE} file exist${NC}"
else
# Создание файла с заданным содержимым
    echo "
{
  \"registry-mirrors\": [
    \"https://mirror.gcr.io\",
    \"https://public.ecr.aws\",
    \"https://quay.io\"
  ]
}" | tee $FILE > /dev/null
    echo "${GREEN}${FILE} file created${NC}"
# Перезагрузка сервиса Docker
systemctl reload docker
fi

DOCKER_STATUS=$(systemctl status docker)
    echo "$DOCKER_STATUS"
