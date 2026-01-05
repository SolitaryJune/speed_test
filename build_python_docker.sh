#!/bin/bash

# Python Docker一键构建和运行脚本
# 该脚本将自动创建Python项目文件、Dockerfile并构建运行Docker镜像

set -e  # 遇到错误时退出

echo "开始构建Python Docker项目..."

# 创建项目目录
PROJECT_DIR="/opt/python-docker-app"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 创建Python应用文件
cat > app.py << 'EOF'
from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return '''
    <h1>Python Docker应用运行成功！</h1>
    <p>欢迎使用一键构建的Python应用</p>
    <p>当前时间: {}</p>
    '''.format(str(__import__('datetime').datetime.now()))

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
EOF

# 创建requirements.txt
cat > requirements.txt << 'EOF'
flask==2.3.3
gunicorn==21.2.0
EOF

# 创建Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
EOF

# 创建.dockerignore
cat > .dockerignore << 'EOF'
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.venv/
pip-log.txt
pip-delete-this-directory.txt
.tox
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.log
.git
.mypy_cache
.pytest_cache
.hypothesis
.DS_Store
EOF

# 创建README.md
cat > README.md << 'EOF'
# Python Docker应用

这是一个通过一键脚本构建的Python应用，使用Flask框架并通过Docker容器化部署。

## 项目结构
- app.py: 主应用文件
- requirements.txt: Python依赖
- Dockerfile: Docker构建文件
- .dockerignore: Docker忽略文件

## 构建和运行
构建镜像:
```bash
docker build -t python-docker-app .
```

运行容器:
```bash
docker run -d -p 5000:5000 python-docker-app
```

## 访问应用
应用运行后，可以通过 http://localhost:5000 访问
EOF

# 创建启动脚本
cat > start.sh << 'EOF'
#!/bin/bash
# 启动Python Docker应用

# 构建Docker镜像
echo "正在构建Docker镜像..."
docker build -t python-docker-app .

# 停止并删除之前运行的容器（如果存在）
docker stop python-app-container 2>/dev/null || true
docker rm python-app-container 2>/dev/null || true

# 运行新的容器
echo "正在启动容器..."
docker run -d --name python-app-container -p 5000:5000 python-docker-app

echo "Python应用已启动，访问 http://localhost:5000"
EOF

chmod +x start.sh

echo "项目文件创建完成！"

# 检查Docker是否已安装
if ! command -v docker &> /dev/null; then
    echo "错误: Docker未安装，请先安装Docker"
    exit 1
fi

echo "Docker已安装，开始构建镜像..."

# 执行构建
chmod +x start.sh
./start.sh

echo "Python Docker应用构建并运行完成！"
echo "访问 http://localhost:5000 查看应用"