#!/bin/bash
set -e
sudo chmod 777 /mnt
# 定义基础镜像和容器名称
BASE_IMAGE="alpine:3.17"
CONTAINER_NAME="swoole-cli-main317"
WORK_DIR="/mnt/${CONTAINER_NAME}"
PHP_VER="$1"
SWOOLE_VER="$2"
echo "✅ 收到参数:"
echo "   PHP Version: $PHP_VER"
echo "   Swoole Version: $SWOOLE_VER"
# 检查并克隆仓库
if [ ! -d "$WORK_DIR" ]; then
  echo "克隆 swoole-cli 仓库到 $WORK_DIR..."
  git clone --recursive https://github.com/swoole/swoole-cli.git $WORK_DIR
else
  sudo rm -rf $WORK_DIR
  git clone --recursive https://github.com/swoole/swoole-cli.git $WORK_DIR
fi
PHP_CONF_FILE="sapi/PHP-VERSION.conf"
SWOOLE_CONF_FILE="sapi/SWOOLE-VERSION.conf"
# 进入工作目录并初始化环境
cd $WORK_DIR

echo "📝 正在写入 $PHP_CONF_FILE..."
echo -n "$PHP_VER" > "$PHP_CONF_FILE"

echo "📝 正在写入 $SWOOLE_CONF_FILE..."
echo -n "$SWOOLE_VER" > "$SWOOLE_CONF_FILE"

bash setup-php-runtime.sh
composer install
php prepare.php
php prepare.php +inotify +mongodb +xlswriter

# 定义在容器内执行的命令
CONTAINER_COMMANDS="
ls -l &&
cd /work &&
export PATH=\$PATH:/work/bin/runtime &&
sh sapi/quickstart/linux/alpine-init.sh &&
./make.sh all-library &&
./make.sh config &&
./make.sh build &&
./make.sh archive
exit
"
# 检查容器是否存在
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "容器 $CONTAINER_NAME 已存在，直接进入执行命令..."
    
    # ⬇️ 解决方案 1: 移除 -it
    docker exec $CONTAINER_NAME /bin/sh -c "($CONTAINER_COMMANDS) 2>&1 | tee /work/compile.log"
else
    echo "容器 $CONTAINER_NAME 不存在，创建新容器并执行命令..."
    docker pull $BASE_IMAGE
    
    # ⬇️ 解决方案 2: 移除 -it，并使用 tail -f /dev/null 保持容器存活
    echo "启动新容器..."
    docker run -d --name $CONTAINER_NAME -v $WORK_DIR:/work $BASE_IMAGE tail -f /dev/null
    
    echo "在新容器中执行命令..."
    # ⬇️ 解决方案 1: 移除 -it
    docker exec $CONTAINER_NAME /bin/sh -c "($CONTAINER_COMMANDS) 2>&1 | tee /work/compile.log"
fi
