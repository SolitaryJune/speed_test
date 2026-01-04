# Dockerfile 优化说明

## 优化措施

### 1. 创建 .dockerignore 文件
- 排除了不必要的文件和目录，减少传输到构建上下文的数据量
- 包括 __pycache__/, .git/, 日志文件等

### 2. 使用 Alpine 基础镜像
- 从 `python:3.9-slim` 改为 `python:3.9-alpine`
- Alpine 镜像比 slim 镜像更小，通常只有几十MB

### 3. 优化依赖安装
- 只安装实际需要的依赖（requests）
- 使用 `--no-cache-dir` 选项减少镜像大小
- 合并安装命令以减少层数

### 4. 精确复制文件
- 不再使用 `COPY . .` 复制整个目录
- 只复制应用实际需要的文件

### 5. 提供多阶段构建选项
- `Dockerfile.optimized` 提供多阶段构建
- 进一步减少最终镜像大小

## 使用方法

### 构建优化后的镜像
```bash
# 使用标准优化版本
docker build -t speedtest:optimized .

# 使用多阶段构建版本
docker build -f Dockerfile.optimized -t speedtest:multi-stage .
```

## 预期效果

- 减少构建上下文传输的数据量
- 缩短构建时间
- 减小最终镜像大小
- 提高部署效率