#!/bin/bash

# 脚本名称: build_and_run_docker.sh
# 功能: 真正的“一键”部署脚本。自动下载所需文件、构建 Docker 镜像并运行测速容器。

# 仓库信息
REPO_OWNER="SolitaryJune"
REPO_NAME="speed_test"
BRANCH="main"
RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

# 文件列表
FILES=("Dockerfile" "speed_test_limited.py" ".dockerignore")
IMAGE_NAME="speed-tester-limited"

# 检查是否安装了 Docker
if ! command -v docker &> /dev/null
then
    echo "错误: Docker 未安装。请先安装 Docker。"
    exit 1
fi

# 1. 下载所需文件
echo "--- 1. 下载所需文件 ---"
for FILE in "${FILES[@]}"; do
    DOWNLOAD_LINK="${RAW_URL}/${FILE}"
    echo "正在下载 ${FILE}..."
    if ! curl -sO "${DOWNLOAD_LINK}"; then
        echo "错误: 下载 ${FILE} 失败。请检查网络连接或仓库路径。"
        exit 1
    fi
done
echo "文件下载完成。"

# 2. 构建 Docker 镜像
echo "--- 2. 开始构建 Docker 镜像: ${IMAGE_NAME} ---"
# 使用 sudo 构建镜像，以确保权限
sudo docker build -t ${IMAGE_NAME} .
if [ $? -ne 0 ]; then
    echo "--- 错误: Docker 镜像构建失败 ---"
    exit 1
fi
echo "--- Docker 镜像构建成功: ${IMAGE_NAME} ---"

# 3. 运行 Docker 容器
echo "--- 3. 运行 Docker 容器: ${IMAGE_NAME} ---"
# 运行容器，并将所有参数传递给 Python 脚本
# 使用 --rm 确保容器运行结束后自动删除
# 传递给脚本的参数从 $1 开始，即脚本名后的所有参数
sudo docker run --rm ${IMAGE_NAME} python3 speed_test_limited.py "$@"
if [ $? -ne 0 ]; then
    echo "--- 错误: Docker 容器运行失败 ---"
    exit 1
fi

# 4. 清理下载的文件
echo "--- 4. 清理下载的临时文件 ---"
for FILE in "${FILES[@]}"; do
    rm -f "${FILE}"
done
echo "清理完成。"

echo "--- 测速完成 ---"
