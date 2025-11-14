#!/bin/bash
set -e

# 定义基础镜像和容器名称
BASE_IMAGE="alpine:3.17"
CONTAINER_NAME="swoole-cli-main317"
WORK_DIR="/mnt/${CONTAINER_NAME}"

# 检查并克隆仓库
if [ ! -d "$WORK_DIR" ]; then
  echo "克隆 swoole-cli 仓库到 $WORK_DIR..."
  git clone --recursive https://github.com/swoole/swoole-cli.git $WORK_DIR
else
  sudo rm -rf $WORK_DIR
  git clone --recursive https://github.com/swoole/swoole-cli.git $WORK_DIR
fi

# 进入工作目录并初始化环境
cd $WORK_DIR
bash setup-php-runtime.sh
composer install
php prepare.php
php prepare.php +inotify +mongodb +xlswriter

# 定义在容器内执行的命令
CONTAINER_COMMANDS="
cd /work &&
sh setup-php-runtime.sh &&
export PATH=\$PATH:/work/bin/runtime &&
sh sapi/quickstart/linux/alpine-init.sh &&
php prepare.php &&
php prepare.php +inotify +mongodb +xlswriter &&
./make.sh all-library &&
./make.sh config &&
./make.sh build &&
./make.sh archive
exit
"
# 检查容器是否存在
if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
  echo "容器 ${CONTAINER_NAME} 已存在，直接进入执行命令..."
  docker exec -it $CONTAINER_NAME /bin/sh -c "$CONTAINER_COMMANDS"
else
  echo "容器 ${CONTAINER_NAME} 不存在，创建新容器并执行命令..."
  docker pull $BASE_IMAGE
  docker run -dit --name $CONTAINER_NAME -v $WORK_DIR:/work $BASE_IMAGE /bin/sh
  docker exec -it $CONTAINER_NAME /bin/sh -c "$CONTAINER_COMMANDS"
fi
