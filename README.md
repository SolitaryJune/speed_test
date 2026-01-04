# 一键构建Docker

这个项目包含一键构建Docker镜像和一键安装/更新Docker的脚本，可以帮助您快速构建和管理Docker镜像以及维护Docker环境。

## 文件说明

- `Dockerfile`: Docker镜像构建文件
- `build_docker.sh`: 一键构建Docker镜像的脚本
- `build_and_run_docker.sh`: 一键构建、更新、安装和运行Docker的脚本，启动后自动运行
- `requirements.txt`: Python依赖包列表
- `speed_test_limited.py`: 示例Python应用文件
- `speedtest.py`: 网络速度测试脚本，默认限速值为100.00 Mbps
- `update_docker.sh`: 一键安装或更新Docker的脚本

## 使用方法

### 1. 一键构建、更新、安装和运行Docker（推荐）

```bash
./build_and_run_docker.sh
```

这个脚本会自动完成以下操作：
- 如果需要，更新或安装Docker
- 构建Docker镜像
- 运行容器并设置为开机自启
- 容器会在系统启动时自动运行

### 2. 使用加速站点下载脚本（Debian系统）

如果您在中国大陆，可以使用加速站点下载脚本：

```bash
wget https://git.gushao.club/https://github.com/SolitaryJune/speed_test/build_and_run_docker.sh
chmod +x build_and_run_docker.sh
./build_and_run_docker.sh
```

或者使用curl：

```bash
curl -O https://git.gushao.club/https://github.com/SolitaryJune/speed_test/build_and_run_docker.sh
chmod +x build_and_run_docker.sh
./build_and_run_docker.sh
```

### 3. 直接构建（使用默认参数）

```bash
./build_docker.sh
```

### 4. 指定镜像名称和标签

```bash
./build_docker.sh -n myapp -t v1.0
```

### 5. 使用构建参数

```bash
./build_docker.sh -n myapp -t v1.0 -b "ARG1=value1" -b "ARG2=value2"
```

### 6. 查看帮助信息

```bash
./build_docker.sh -h
```

## build_and_run_docker.sh 脚本参数

- `-n, --name NAME`: Docker镜像名称（默认: myapp）
- `-c, --container NAME`: 容器名称（默认: myapp-container）
- `-t, --tag TAG`: 镜像标签（默认: latest）
- `-f, --file PATH`: Dockerfile路径（默认: .）
- `-u, --update-docker`: 更新Docker（如果已安装则更新，否则安装）
- `-r, --remove-old`: 构建前移除旧容器和镜像
- `-h, --help`: 显示帮助信息

## build_docker.sh 脚本参数

- `-n, --name NAME`: 镜像名称 (默认: myapp)
- `-t, --tag TAG`: 镜像标签 (默认: latest)
- `-f, --file PATH`: Dockerfile路径 (默认: Dockerfile)
- `-c, --context PATH`: 构建上下文路径 (默认: .)
- `-b, --build-arg ARG`: 构建参数 (可以多次使用)
- `-h, --help`: 显示帮助信息

## 自定义配置

1. 根据您的应用需求修改 `Dockerfile`
2. 在 `requirements.txt` 中添加所需的Python包
3. 根据需要修改 `speed_test_limited.py` 或替换为您的应用文件

## 示例

构建名为 `myapp` 标签为 `v1.0` 的镜像：

```bash
./build_docker.sh -n myapp -t v1.0
```

构建后，您可以通过以下命令运行容器：

```bash
docker run -p 8000:8000 myapp:v1.0
```

## speedtest.py 使用方法

网络速度测试脚本，默认限速值为100.00 Mbps。

### 基本用法

```bash
python speedtest.py
```

### 自定义参数

```bash
# 设置测试持续时间为20秒
python speedtest.py -d 20

# 设置限速值为50.00 Mbps
python speedtest.py -l 50.00

# 同时设置持续时间和限速值
python speedtest.py -d 15 -l 200.00
```

### 参数说明

- `-d, --duration`: 测试持续时间（秒），默认为10
- `-l, --limit`: 限速值（Mbps），默认为100.00

## update_docker.sh 使用方法

一键安装或更新Docker的脚本。

### 基本用法

```bash
./update_docker.sh
```

脚本会自动检测Docker是否已安装：
- 如果已安装，将更新到最新版本
- 如果未安装，将自动安装Docker

### 注意事项

- 脚本支持Ubuntu、Debian、CentOS、Red Hat、Fedora和openSUSE
- 脚本会自动启动Docker服务并设置开机自启
- 可能需要重新登录以使docker组权限生效
- 脚本会安装Docker CE（社区版）以及Docker Compose插件

## 注意事项

- 确保您的系统已安装Docker（或使用update_docker.sh脚本安装）
- 确保有足够的磁盘空间来构建镜像
- 如果构建失败，请检查Dockerfile和相关依赖文件