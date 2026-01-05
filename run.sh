#!/bin/bash

# 脚本名称: run.sh
# 功能: 一键构建并运行 speed-tester-limited Docker 容器

# 检查是否安装了 Docker
if ! command -v docker &> /dev/null
then
    echo "错误: Docker 未安装。请先安装 Docker。"
    exit 1
fi

# 检查是否有足够的参数
if [ "$#" -lt 1 ]; then
    echo "用法: $0 <命令> [参数...]"
    echo "命令: build, run"
    echo "示例: $0 build"
    echo "示例: $0 run --threads 8 --duration 60 --speed-limit 50"
    exit 1
fi

COMMAND=$1
shift # 移除第一个参数 (命令)

IMAGE_NAME="speed-tester-limited"

case "$COMMAND" in
    build)
        echo "--- 开始构建 Docker 镜像: $IMAGE_NAME ---"
        # 使用 sudo 构建镜像，以确保权限
        sudo docker build -t $IMAGE_NAME .
        if [ $? -eq 0 ]; then
            echo "--- Docker 镜像构建成功: $IMAGE_NAME ---"
        else
            echo "--- 错误: Docker 镜像构建失败 ---"
            exit 1
        fi
        ;;

    run)
        echo "--- 运行 Docker 容器: $IMAGE_NAME ---"
        # 运行容器，并将所有剩余参数传递给 Python 脚本
        # 使用 --rm 确保容器运行结束后自动删除
        sudo docker run --rm $IMAGE_NAME "$@"
        if [ $? -ne 0 ]; then
            echo "--- 错误: Docker 容器运行失败 ---"
            exit 1
        fi
        ;;

    *)
        echo "错误: 无效命令 '$COMMAND'。请使用 'build' 或 'run'。"
        exit 1
        ;;
esac
