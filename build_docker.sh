#!/bin/bash

# 一键构建Docker镜像脚本
# 作者: Assistant
# 日期: $(date +%Y-%m-%d)

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认参数
IMAGE_NAME="myapp"
TAG="latest"
CONTEXT="."
DOCKERFILE_PATH="Dockerfile"
BUILD_ARGS=""

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  -n, --name NAME       镜像名称 (默认: myapp)"
    echo "  -t, --tag TAG         镜像标签 (默认: latest)"
    echo "  -f, --file PATH       Dockerfile路径 (默认: Dockerfile)"
    echo "  -c, --context PATH    构建上下文路径 (默认: .)"
    echo "  -b, --build-arg ARG   构建参数 (可以多次使用)"
    echo "  -h, --help            显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                           # 使用默认参数构建"
    echo "  $0 -n myapp -t v1.0          # 构建名为myapp:v1.0的镜像"
    echo "  $0 -n myapp -b \"ARG1=value1\" -b \"ARG2=value2\"  # 使用构建参数"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -f|--file)
            DOCKERFILE_PATH="$2"
            shift 2
            ;;
        -c|--context)
            CONTEXT="$2"
            shift 2
            ;;
        -b|--build-arg)
            if [ -z "$BUILD_ARGS" ]; then
                BUILD_ARGS="--build-arg $2"
            else
                BUILD_ARGS="$BUILD_ARGS --build-arg $2"
            fi
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 完整的镜像名称
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"

echo -e "${GREEN}开始构建Docker镜像...${NC}"
echo -e "${YELLOW}镜像名称: ${FULL_IMAGE_NAME}${NC}"
echo -e "${YELLOW}Dockerfile: ${DOCKERFILE_PATH}${NC}"
echo -e "${YELLOW}构建上下文: ${CONTEXT}${NC}"
if [ -n "$BUILD_ARGS" ]; then
    echo -e "${YELLOW}构建参数: $BUILD_ARGS${NC}"
fi

# 检查Dockerfile是否存在
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo -e "${RED}错误: Dockerfile '$DOCKERFILE_PATH' 不存在${NC}"
    exit 1
fi

# 检查构建上下文目录是否存在
if [ ! -d "$CONTEXT" ]; then
    echo -e "${RED}错误: 构建上下文目录 '$CONTEXT' 不存在${NC}"
    exit 1
fi

# 构建Docker镜像
echo -e "${GREEN}执行构建命令...${NC}"
BUILD_CMD="docker build -t ${FULL_IMAGE_NAME} -f ${DOCKERFILE_PATH} ${BUILD_ARGS} ${CONTEXT}"
echo "命令: $BUILD_CMD"
eval $BUILD_CMD

# 检查构建是否成功
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Docker镜像构建成功: ${FULL_IMAGE_NAME}${NC}"
    
    # 显示构建的镜像信息
    echo -e "${GREEN}镜像信息:${NC}"
    docker images | grep "$IMAGE_NAME" | grep "$TAG"
    
    echo -e "${GREEN}构建完成!${NC}"
else
    echo -e "${RED}Docker镜像构建失败${NC}"
    exit 1
fi