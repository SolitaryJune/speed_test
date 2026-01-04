# 使用官方Python运行时作为基础镜像
FROM python:3.9-alpine

# 设置工作目录
WORKDIR /app

# 安装依赖包（如果需要系统级依赖）
RUN apk update && apk add --no-cache gcc musl-dev libffi-dev

# 复制requirements.txt（如果存在）
COPY requirements.txt .

# 安装Python依赖包
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

# 只复制应用所需的文件
COPY speedtest.py .
COPY speed_test_limited.py .

# 暴露端口（根据您的应用需求修改）
EXPOSE 8000

# 运行应用
CMD ["python", "speedtest.py"]