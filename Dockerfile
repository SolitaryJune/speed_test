# 使用官方Python运行时作为基础镜像
FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 复制requirements.txt（如果存在）
COPY requirements.txt .

# 安装依赖包
RUN pip install --no-cache-dir -r requirements.txt

# 将当前目录的内容复制到容器的/app目录中
COPY . .

# 暴露端口（根据您的应用需求修改）
EXPOSE 8000

# 定义环境变量
ENV NAME World

# 运行应用
CMD ["python", "speedtest.py"]