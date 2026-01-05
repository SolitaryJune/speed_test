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
| `build_and_run_docker.sh` | **终极一键部署脚本**，用于下载仓库文件、构建 Docker 镜像和运行容器。 |

## 终极一键部署和运行 (`build_and_run_docker.sh`)

这个脚本将自动完成下载文件、构建镜像和运行容器的所有步骤。

### 1. 下载脚本

您可以通过以下方式下载并运行脚本。

**使用标准 GitHub 链接：**

```bash
wget https://raw.githubusercontent.com/SolitaryJune/speed_test/main/build_and_run_docker.sh
chmod +x build_and_run_docker.sh
./build_and_run_docker.sh [可选参数]
```

**使用加速站点下载脚本（例如，Debian系统）：**

如果您在中国大陆，可以使用加速站点下载脚本：

```bash
wget https://git.gushao.club/https://github.com/SolitaryJune/speed_test/raw/main/build_and_run_docker.sh
chmod +x build_and_run_docker.sh
./build_and_run_docker.sh [可选参数]
```
或者使用 `curl`：

```bash
curl -O https://git.gushao.club/https://github.com/SolitaryJune/speed_test/raw/main/build_and_run_docker.sh
chmod +x build_and_run_docker.sh
./build_and_run_docker.sh [可选参数]
```

### 2. 运行测速容器

脚本运行后，会自动下载所需的 `Dockerfile` 和 `speed_test_limited.py` 等文件，然后构建 Docker 镜像，并运行测速。脚本会在运行结束后自动清理下载的临时文件。

您可以将测速参数直接传递给 `./build_and_run_docker.sh` 脚本，这些参数将传递给内部的 Python 测速脚本。

| 参数 | 描述 | 默认值 | 示例 |
| :--- | :--- | :--- | :--- |
| `--url` | 测速源 URL | 默认测试文件 URL | `--url https://example.com/file.zip` |
| `--threads` | 并发下载线程数 | `4` | `--threads 8` |
| `--duration` | 测速持续时间（秒） | `10` | `--duration 60` |
| `--speed-limit` | 下载速度限制（Mbps） | `100.0` | `--speed-limit 50` |

**示例 1: 使用默认设置运行 (限速 100.0 Mbps)**

```bash
./build_and_run_docker.sh
```

**示例 2: 设置 8 线程，运行 30 秒，限速 5 Mbps**

```bash
./build_and_run_docker.sh --threads 8 --duration 30 --speed-limit 5
```

## 注意事项

*   `build_and_run_docker.sh` 脚本在执行 `docker build` 和 `docker run` 时会使用 `sudo` 命令，请确保您的用户有权限执行 `sudo docker` 命令。
*   限速功能基于 Python 的 `time.sleep()` 实现，在多线程和不同操作系统环境下，实际限速精度可能略有偏差。
*   如果遇到下载中断问题，请尝试更换 `--url` 或检查本地网络环境。
