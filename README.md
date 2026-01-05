# speed_test: Docker 化多线程限速测速工具

本项目提供了一个基于 Python 的多线程测速工具，并将其打包为 Docker 容器，支持在启动时灵活配置线程数、测速时长和下载速度限制（限速）。

## 核心功能

*   **多线程下载：** 通过多线程并发下载，模拟高负载测速。
*   **速度限制（限速）：** 支持通过命令行参数设置下载速度上限（单位：Mbps）。默认限速为 **100.0 Mbps**。
*   **连接稳定性增强：** 增加了连接超时时间（30秒）和指数退避重试机制，以提高长时间下载的稳定性。
*   **Docker 化部署：** 提供 `Dockerfile` 和一键脚本，方便快速部署和运行。

## 文件说明

| 文件名 | 描述 |
| :--- | :--- |
| `speed_test_limited.py` | 核心 Python 脚本，包含多线程下载和基于令牌桶算法的限速逻辑。 |
| `Dockerfile` | Docker 镜像构建文件，基于 `python:3.9-slim-buster`。 |
| `.dockerignore` | Docker 忽略文件，用于优化镜像构建速度。 |
| `run.sh` | **一键部署脚本**，用于简化 Docker 镜像的构建和容器的运行。 |

## 一键部署和运行 (`run.sh`)

`run.sh` 脚本简化了 Docker 的操作流程。

### 1. 克隆仓库

首先，将本仓库克隆到您的本地：

```bash
git clone https://github.com/SolitaryJune/speed_test.git
cd speed_test
```

### 2. 赋予脚本权限

确保 `run.sh` 脚本具有可执行权限：

```bash
chmod +x run.sh
```

### 3. 构建 Docker 镜像

使用 `build` 命令构建 Docker 镜像。镜像名称默认为 `speed-tester-limited`。

```bash
./run.sh build
```

### 4. 运行测速容器

使用 `run` 命令运行容器。您可以通过在 `run` 命令后添加参数来配置测速：

| 参数 | 描述 | 默认值 | 示例 |
| :--- | :--- | :--- | :--- |
| `--url` | 测速源 URL | 默认测试文件 URL | `--url https://example.com/file.zip` |
| `--threads` | 并发下载线程数 | `4` | `--threads 8` |
| `--duration` | 测速持续时间（秒） | `10` | `--duration 60` |
| `--speed-limit` | 下载速度限制（Mbps） | `100.0` | `--speed-limit 50` |

**示例 1: 使用默认设置运行 (限速 100.0 Mbps)**

```bash
./run.sh run
```

**示例 2: 设置 8 线程，运行 30 秒，限速 5 Mbps**

```bash
./run.sh run --threads 8 --duration 30 --speed-limit 5
```

**示例 3: 运行帮助信息**

```bash
./run.sh run --help
```

## 注意事项

*   `run.sh` 脚本在执行 `docker build` 和 `docker run` 时会使用 `sudo` 命令，请确保您的用户有权限执行 `sudo docker` 命令。
*   限速功能基于 Python 的 `time.sleep()` 实现，在多线程和不同操作系统环境下，实际限速精度可能略有偏差。
*   如果遇到下载中断问题，请尝试更换 `--url` 或检查本地网络环境。
