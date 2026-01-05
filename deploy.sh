#!/bin/bash

# 一键部署脚本 - 自动安装环境并构建项目
# 适用于物理机部署

set -e  # 遇到错误立即退出

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

# 检查系统类型
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    
    log_info "检测到操作系统: $OS, 版本: $VER"
}

# 安装必要的包管理器
install_package_manager() {
    if command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        UPDATE_CMD="apt update"
        INSTALL_CMD="apt install -y"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        UPDATE_CMD="yum update -y"
        INSTALL_CMD="yum install -y"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        UPDATE_CMD="dnf update -y"
        INSTALL_CMD="dnf install -y"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        UPDATE_CMD="pacman -Sy"
        INSTALL_CMD="pacman -S --noconfirm"
    else
        log_error "不支持的包管理器"
        exit 1
    fi
    
    log_info "使用包管理器: $PKG_MANAGER"
}

# 安装必要工具
install_dependencies() {
    log_info "更新包列表..."
    $UPDATE_CMD
    
    log_info "安装必要工具..."
    
    # 通用工具
    $INSTALL_CMD curl wget git unzip tar gzip
    
    # 安装 Node.js
    if ! command -v node &> /dev/null; then
        log_info "安装 Node.js..."
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
            $INSTALL_CMD nodejs
        elif [[ "$PKG_MANAGER" == "yum" || "$PKG_MANAGER" == "dnf" ]]; then
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
            $INSTALL_CMD nodejs
        else
            # 对于其他系统使用官方安装脚本
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
            $INSTALL_CMD nodejs
        fi
    fi
    
    # 安装 Python (如果需要)
    if ! command -v python3 &> /dev/null; then
        $INSTALL_CMD python3 python3-pip
    fi
    
    # 安装 Docker (如果需要)
    if ! command -v docker &> /dev/null; then
        log_info "安装 Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl start docker
        systemctl enable docker
        # 添加当前用户到 docker 组
        usermod -aG docker $USER
    fi
    
    # 安装 Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_info "安装 Docker Compose..."
        DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
        mkdir -p $DOCKER_CONFIG/cli-plugins
        curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o $DOCKER_CONFIG/cli-plugins/docker-compose
        chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    fi
    
    log_info "依赖安装完成"
}

# 创建项目目录结构
create_project_structure() {
    log_info "创建项目目录结构..."
    
    PROJECT_DIR="/opt/myapp"
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
    
    # 创建基本目录结构
    mkdir -p {src,public,config,logs,tests,docs}
    
    # 创建前端项目结构
    mkdir -p src/{components,utils,assets,styles}
    
    log_info "项目目录结构创建完成"
}

# 创建基础项目文件
create_project_files() {
    log_info "创建基础项目文件..."
    
    cd /opt/myapp
    
    # 创建 package.json
    cat > package.json << 'EOF'
{
  "name": "myapp",
  "version": "1.0.0",
  "description": "自动部署的应用程序",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "jest",
    "build": "npm run build:frontend && npm run build:backend"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3",
    "mongoose": "^6.8.4",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.0"
  },
  "devDependencies": {
    "nodemon": "^2.0.20",
    "jest": "^29.3.1",
    "supertest": "^6.3.3"
  }
}
EOF

    # 创建基础服务器文件
    cat > index.js << 'EOF'
const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// 路由
app.get('/', (req, res) => {
    res.json({ message: '应用部署成功!' });
});

app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
    console.log(`服务器运行在 http://0.0.0.0:${PORT}`);
});
EOF

    # 创建 .env 文件
    cat > .env << 'EOF'
PORT=3000
NODE_ENV=production
DB_HOST=localhost
DB_PORT=27017
DB_NAME=myapp
JWT_SECRET=your_jwt_secret_key_here
EOF

    # 创建 Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
EOF

    # 创建 docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    volumes:
      - ./logs:/app/logs
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: mongo:5
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=password
    restart: unless-stopped

volumes:
  mongodb_data:
EOF

    # 创建 nginx 配置（可选）
    mkdir -p nginx/conf.d
    cat > nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server {
        listen 80;
        server_name localhost;
        
        location / {
            proxy_pass http://localhost:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
EOF

    log_info "基础项目文件创建完成"
}

# 初始化 Git 仓库
setup_git() {
    log_info "初始化 Git 仓库..."
    
    cd /opt/myapp
    
    git init
    git add .
    
    # 创建 .gitignore
    cat > .gitignore << 'EOF'
node_modules/
.env
*.log
logs/
npm-debug.log*
coverage/
dist/
build/
.nyc_output/
.vscode/
.idea/
.DS_Store
EOF
    
    git add .gitignore
    git commit -m "Initial commit: Auto-generated project structure"
    
    log_info "Git 仓库初始化完成"
}

# 安装 Node.js 依赖
install_node_dependencies() {
    log_info "安装 Node.js 依赖..."
    
    cd /opt/myapp
    npm install
    
    log_info "Node.js 依赖安装完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    cd /opt/myapp
    
    # 如果有 Docker Compose，则使用它启动
    if command -v docker-compose &> /dev/null && [ -f docker-compose.yml ]; then
        log_info "使用 Docker Compose 启动服务..."
        docker-compose up -d
    else
        # 否则直接启动 Node.js 应用
        log_info "直接启动 Node.js 应用..."
        npm start &
    fi
    
    log_info "服务启动完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    # 等待几秒让服务启动
    sleep 5
    
    # 检查端口是否开放
    if nc -z localhost 3000; then
        log_info "端口 3000 已开放"
        
        # 尝试访问健康检查端点
        if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
            log_info "服务运行正常: http://localhost:3000"
        else
            log_warn "服务可能未完全启动，稍后重试"
        fi
    else
        log_warn "端口 3000 未开放，服务可能启动失败"
    fi
}

# 显示完成信息
show_completion_info() {
    log_info "=================================="
    log_info "部署完成!"
    log_info "=================================="
    log_info "项目位置: /opt/myapp"
    log_info "访问地址: http://localhost:3000"
    log_info "API 健康检查: http://localhost:3000/api/health"
    log_info ""
    log_info "常用命令:"
    log_info "  - 查看服务状态: docker-compose ps (如果使用 Docker)"
    log_info "  - 查看日志: docker-compose logs (如果使用 Docker)"
    log_info "  - 停止服务: docker-compose down (如果使用 Docker)"
    log_info "  - 进入项目目录: cd /opt/myapp"
    log_info "=================================="
}

# 主函数
main() {
    log_info "开始一键部署..."
    
    detect_os
    install_package_manager
    install_dependencies
    create_project_structure
    create_project_files
    setup_git
    install_node_dependencies
    start_services
    verify_deployment
    show_completion_info
    
    log_info "一键部署脚本执行完成!"
}

# 运行主函数
main "$@"