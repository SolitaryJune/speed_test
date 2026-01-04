#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 确保所有必需的文件存在
ensure_files() {
    print_info "检查并创建必需的文件..."

    # 创建 speedtest.py 如果不存在
    if [ ! -f "speedtest.py" ]; then
        print_info "创建 speedtest.py..."
        cat > speedtest.py << 'EOF'
#!/usr/bin/env python3
"""
网络速度测试脚本
"""

import time
import random
import argparse
import sys


def speed_test(duration=10, limit=100.00):
    """
    模拟网络速度测试
    :param duration: 测试持续时间（秒）
    :param limit: 限速值（Mbps）
    """
    print(f"开始网络速度测试，限速: {limit} Mbps")
    print(f"测试持续时间: {duration} 秒")
    
    total_data = 0
    start_time = time.time()
    
    for i in range(duration):
        # 模拟数据传输
        data_chunk = random.uniform(0, min(15, limit/8))  # 转换为MB/s并限制每次传输
        total_data += data_chunk
        elapsed = time.time() - start_time
        
        # 计算当前速度
        current_speed = (data_chunk * 8)  # 转换回Mbps
        
        print(f"时间: {elapsed:.2f}s, 速度: {current_speed:.2f} Mbps")
        time.sleep(1)
    
    total_time = time.time() - start_time
    avg_speed = (total_data * 8) / total_time  # 转换为Mbps
    
    print(f"\n测试完成!")
    print(f"总传输数据: {total_data:.2f} MB")
    print(f"平均速度: {avg_speed:.2f} Mbps")
    print(f"最高速度: {limit:.2f} Mbps (限速)")


def main():
    parser = argparse.ArgumentParser(description="网络速度测试工具")
    parser.add_argument("-d", "--duration", type=int, default=10, help="测试持续时间（秒），默认为10")
    parser.add_argument("-l", "--limit", type=float, default=100.00, help="限速值（Mbps），默认为100.00")
    
    args = parser.parse_args()
    
    if args.limit <= 0:
        print("错误: 限速值必须大于0")
        sys.exit(1)
        
    speed_test(args.duration, args.limit)


if __name__ == "__main__":
    main()
EOF
    fi

    # 创建 requirements.txt 如果不存在
    if [ ! -f "requirements.txt" ]; then
        print_info "创建 requirements.txt..."
        cat > requirements.txt << 'EOF'
# 根据应用需求添加Python包
requests
numpy
EOF
    fi

    # 创建 Dockerfile 如果不存在
    if [ ! -f "Dockerfile" ]; then
        print_info "创建轻量化的 Dockerfile..."
        cat > Dockerfile << 'EOF'
# 使用更轻量的alpine基础镜像
FROM python:3.9-alpine

# 设置工作目录
WORKDIR /app

# 安装依赖包
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 只复制必要的Python文件，而不是整个目录
COPY speedtest.py .

# 运行应用
CMD ["python", "speedtest.py"]
EOF
    fi
}

# 默认值
IMAGE_NAME="speed-tester"
CONTAINER_NAME="speed-tester-container"
TAG="latest"
DOCKERFILE_PATH="."
UPDATE_DOCKER=false
REMOVE_OLD=false

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -n, --name NAME          Docker镜像名称 (默认: myapp)"
    echo "  -c, --container NAME     容器名称 (默认: myapp-container)"
    echo "  -t, --tag TAG            镜像标签 (默认: latest)"
    echo "  -f, --file PATH          Dockerfile路径 (默认: .)"
    echo "  -u, --update-docker      更新Docker (如果已安装则更新，否则安装)"
    echo "  -r, --remove-old         构建前移除旧容器和镜像"
    echo "  -h, --help               显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0"
    echo "  $0 -n myapp -t v1.0"
    echo "  $0 -u -r"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -c|--container)
            CONTAINER_NAME="$2"
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
        -u|--update-docker)
            UPDATE_DOCKER=true
            shift
            ;;
        -r|--remove-old)
            REMOVE_OLD=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 未知选项 $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 打印带颜色的信息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以root权限运行（如果需要）
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_warn "当前不是root用户，尝试使用sudo执行Docker命令"
    fi
}

# 更新或安装Docker
update_docker() {
    if [ "$UPDATE_DOCKER" = true ]; then
        print_info "开始更新/安装Docker..."
        
        # 检测操作系统
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            print_info "检测到Ubuntu/Debian系统"
            sudo apt-get update
            sudo apt-get remove docker docker-engine docker.io containerd runc || true
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            print_info "检测到CentOS/RHEL系统"
            sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
        elif command -v dnf &> /dev/null; then
            # Fedora
            print_info "检测到Fedora系统"
            sudo dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
        else
            print_error "不支持的操作系统，无法自动安装Docker"
            exit 1
        fi
        
        print_info "Docker更新/安装完成"
    fi
}

# 移除旧的容器和镜像
remove_old() {
    if [ "$REMOVE_OLD" = true ]; then
        print_info "移除旧的容器和镜像..."
        
        # 停止并移除旧容器
        if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
            print_info "停止并移除旧容器: $CONTAINER_NAME"
            docker stop $CONTAINER_NAME
            docker rm $CONTAINER_NAME
        fi
        
        # 移除旧镜像
        if [ "$(docker images -q $IMAGE_NAME:$TAG)" ]; then
            print_info "移除旧镜像: $IMAGE_NAME:$TAG"
            docker rmi $IMAGE_NAME:$TAG
        fi
    fi
}

# 构建Docker镜像
build_image() {
    print_info "开始构建Docker镜像: $IMAGE_NAME:$TAG"
    
    if [ ! -f "$DOCKERFILE_PATH/Dockerfile" ] && [ ! -f "$DOCKERFILE_PATH" ]; then
        print_error "Dockerfile不存在: $DOCKERFILE_PATH"
        exit 1
    fi
    
    if [ -f "$DOCKERFILE_PATH/Dockerfile" ]; then
        docker build -t $IMAGE_NAME:$TAG $DOCKERFILE_PATH
    else
        docker build -t $IMAGE_NAME:$TAG -f $DOCKERFILE_PATH .
    fi
    
    if [ $? -eq 0 ]; then
        print_info "Docker镜像构建成功: $IMAGE_NAME:$TAG"
    else
        print_error "Docker镜像构建失败"
        exit 1
    fi
}

# 运行Docker容器
run_container() {
    print_info "启动Docker容器: $CONTAINER_NAME"
    
    # 检查容器是否已存在
    if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
        print_info "容器已存在，停止并移除旧容器"
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    fi
    
    # 运行新容器
    docker run -d --name $CONTAINER_NAME --restart=always $IMAGE_NAME:$TAG
    
    if [ $? -eq 0 ]; then
        print_info "Docker容器启动成功: $CONTAINER_NAME"
        print_info "容器将在系统启动时自动运行"
    else
        print_error "Docker容器启动失败"
        exit 1
    fi
}

# 主函数
main() {
    print_info "开始一键构建、更新、安装和运行Docker"
    check_root
    update_docker
    ensure_files
    remove_old
    build_image
    run_container
    print_info "所有操作完成！Docker容器已启动并设置为开机自启"
    print_info "容器名称: $CONTAINER_NAME"
    print_info "镜像名称: $IMAGE_NAME:$TAG"
}

# 执行主函数
main