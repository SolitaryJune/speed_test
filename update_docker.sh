#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    else
        SUDO="sudo"
        if ! command -v sudo &> /dev/null; then
            log_error "sudo command not found. Please install sudo or run as root."
            exit 1
        fi
    fi
}

# 检查操作系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        log_error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi
}

# 安装Docker
install_docker() {
    log_info "Installing Docker..."
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            $SUDO apt-get update
            $SUDO apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            $SUDO apt-get update
            $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        *"CentOS"*|*"Red Hat"*|*"Fedora"*)
            $SUDO dnf -y install dnf-plugins-core
            $SUDO dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $SUDO dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        *"openSUSE"*)
            $SUDO zypper install -y docker docker-compose
            ;;
        *)
            log_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    # 启动并启用Docker服务
    $SUDO systemctl start docker
    $SUDO systemctl enable docker
    
    # 将当前用户添加到docker组（如果存在）
    if id -u &>/dev/null; then
        $SUDO usermod -aG docker $USER
    fi
}

# 更新Docker
update_docker() {
    log_info "Updating Docker..."
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            $SUDO apt-get update
            $SUDO apt-get install --only-upgrade docker-ce docker-ce-cli containerd.io
            ;;
        *"CentOS"*|*"Red Hat"*|*"Fedora"*)
            $SUDO dnf update -y docker-ce docker-ce-cli containerd.io
            ;;
        *"openSUSE"*)
            $SUDO zypper update -y docker
            ;;
        *)
            log_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

# 检查Docker是否已安装
check_docker_installed() {
    if command -v docker &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 主函数
main() {
    log_info "Starting Docker update/installation process..."
    
    check_root
    detect_os
    
    if check_docker_installed; then
        log_info "Docker is already installed. Checking for updates..."
        update_docker
        log_info "Docker updated successfully!"
    else
        log_info "Docker is not installed. Installing Docker..."
        install_docker
        log_info "Docker installed successfully!"
    fi
    
    # 验证安装
    log_info "Verifying Docker installation..."
    docker --version
    if [ $? -eq 0 ]; then
        log_info "Docker is successfully installed and running!"
        log_info "Current Docker version: $(docker --version)"
    else
        log_error "Docker installation verification failed!"
        exit 1
    fi
    
    # 检查Docker服务状态
    log_info "Docker service status:"
    $SUDO systemctl status docker --no-pager -l
}

# 执行主函数
main "$@"