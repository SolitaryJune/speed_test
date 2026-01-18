#!/bin/bash

# 脚本名称: build_and_run_docker.sh
# 功能: 真正的“一键”部署脚本。自动下载所需文件、构建 Docker 镜像并在后台运行测速容器。

# 仓库信息
REPO_OWNER="SolitaryJune"
REPO_NAME="speed_test"
BRANCH="main"
RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

# 文件列表
FILES=("Dockerfile" "speed_test_limited.py" ".dockerignore")
IMAGE_NAME="speed-tester-limited"
CONTAINER_NAME="speed-tester-instance"

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
# 使用 sudo 构建镜像，-q 减少输出
sudo docker build -q -t ${IMAGE_NAME} .
if [ $? -ne 0 ]; then
    echo "--- 错误: Docker 镜像构建失败 ---"
    exit 1
fi
echo "--- Docker 镜像构建成功: ${IMAGE_NAME} ---"

# 3. 运行 Docker 容器 (后台模式)
echo "--- 3. 在后台启动 Docker 容器: ${CONTAINER_NAME} ---"
# 如果已有同名容器在运行，先停止并删除
sudo docker rm -f ${CONTAINER_NAME} &> /dev/null

# 使用 -d 参数在后台运行
# 使用 --name 方便后续管理
# 使用 --restart always 确保容器崩溃或重启后自动恢复
sudo docker run -d --name ${CONTAINER_NAME} --restart always ${IMAGE_NAME} "$@"

if [ $? -ne 0 ]; then
    echo "--- 错误: Docker 容器启动失败 ---"
    exit 1
fi

echo "--- 容器已在后台启动 ---"
echo "提示: 您可以使用 'sudo docker logs -f ${CONTAINER_NAME}' 查看实时日志。"
echo "提示: 您可以使用 'sudo docker stop ${CONTAINER_NAME}' 停止测速。"

# 4. 清理下载的文件
echo "--- 4. 清理下载的临时文件 ---"
for FILE in "${FILES[@]}"; do
    rm -f "${FILE}"
done
echo "清理完成。"

echo "--- 部署完成，脚本退出 ---"
