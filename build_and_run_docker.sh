#!/bin/bash

# 脚本名称: build_and_run_docker.sh
# 功能: 一键构建并运行 speed-tester-limited Docker 容器

# 检查是否安装了 Docker
if ! command -v docker &> /dev/null
then
    echo "错误: Docker 未安装。请先安装 Docker。"
    exit 1
fi

# 检查是否在正确的目录下
if [ ! -f "Dockerfile" ] || [ ! -f "speed_test_limited.py" ]; then
    echo "错误: 找不到 Dockerfile 或 speed_test_limited.py。"
    echo "请确保您在 speed_test 仓库的根目录下运行此脚本。"
    exit 1
fi

IMAGE_NAME="speed-tester-limited"

# 1. 构建 Docker 镜像
echo "--- 开始构建 Docker 镜像: $IMAGE_NAME ---"
# 使用 sudo 构建镜像，以确保权限
sudo docker build -t $IMAGE_NAME .
if [ $? -ne 0 ]; then
    echo "--- 错误: Docker 镜像构建失败 ---"
    exit 1
fi
echo "--- Docker 镜像构建成功: $IMAGE_NAME ---"

# 2. 运行 Docker 容器
echo "--- 运行 Docker 容器: $IMAGE_NAME ---"
# 运行容器，并将所有参数传递给 Python 脚本
# 使用 --rm 确保容器运行结束后自动删除
# 传递给脚本的参数从 $1 开始，即脚本名后的所有参数
sudo docker run --rm $IMAGE_NAME "$@"
if [ $? -ne 0 ]; then
    echo "--- 错误: Docker 容器运行失败 ---"
    exit 1
fi

echo "--- 测速完成 ---"
