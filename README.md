# speed_test: Docker 化多线程限速测速工具

本项目提供了一个基于 Python 的多线程测速工具，并将其打包为 Docker 容器，支持在启动时灵活配置线程数和下载速度限制（限速）。

## 核心功能

*   **多线程下载：** 通过多线程并发下载，模拟高负载测速。
*   **速度限制（限速）：** 支持通过命令行参数设置下载速度上限（单位：MB/s）。默认限速为 **10.0 MB/s**。
*   **自动切换测速源：** 脚本会自动从内置的多个测速源中随机选择，并每下载 500MB 自动切换一次，以模拟真实的持续下载场景。
*   **持续运行：** 测速将持续进行，直到手动停止容器。
*   **Docker 化部署：** 提供 `Dockerfile` 和一键脚本，方便快速部署和运行。

## 文件说明

| 文件名 | 描述 |
| :--- | :--- |
| `speed_test_limited.py` | 核心 Python 脚本，包含多线程下载和基于令牌桶算法的限速逻辑。 |
| `Dockerfile` | Docker 镜像构建文件，基于 `python:3.9-slim-buster`。 |
| `.dockerignore` | Docker 忽略文件，用于优化镜像构建速度。 |
| `build_and_run_docker.sh` | **终极一键部署脚本**，用于下载仓库文件、构建 Docker 镜像和运行容器。 |

## 终极一键部署和运行

您可以使用以下一行命令完成所有部署和启动工作。

### 1. 标准 GitHub 链接（推荐非大陆用户）

```bash
wget -O build_and_run_docker.sh https://raw.githubusercontent.com/SolitaryJune/speed_test/main/build_and_run_docker.sh && chmod +x build_and_run_docker.sh && ./build_and_run_docker.sh --threads 8 --speed-limit 10
```

### 2. 加速站点链接（推荐大陆用户）

```bash
wget -O build_and_run_docker.sh https://git.gushao.club/https://github.com/SolitaryJune/speed_test/raw/main/build_and_run_docker.sh && chmod +x build_and_run_docker.sh && ./build_and_run_docker.sh --threads 8 --speed-limit 10
```

## 运行说明

脚本运行后，会自动下载所需的 `Dockerfile` 和 `speed_test_limited.py` 等文件，然后构建 Docker 镜像，并在后台启动测速容器。脚本会在启动容器后立即退出，测速将在后台持续进行。

| 参数 | 描述 | 默认值 | 示例 |
| :--- | :--- | :--- | :--- |
| `--urls` | 测速源 URL(s) | 默认使用内置的多个测速源 | `--urls https://example.com/file1.zip` |
| `--threads` | 并发下载线程数 | `4` | `--threads 8` |
| `--speed-limit` | 下载速度限制（MB/s） | `10.0` | `--speed-limit 5` |

## 容器管理

由于脚本运行后会立即退出，您可以使用以下 Docker 命令来管理后台的测速任务：

*   **查看实时测速日志：**
    `sudo docker logs -f speed-tester-instance`
*   **停止测速任务：**
    `sudo docker stop speed-tester-instance`
*   **重新启动测速任务：**
    `sudo docker start speed-tester-instance`

## 注意事项

*   `build_and_run_docker.sh` 脚本在执行 `docker build` 和 `docker run` 时会使用 `sudo` 命令，请确保您的用户有权限执行 `sudo docker` 命令。
*   限速功能基于 Python 的 `time.sleep()` 实现，在多线程和不同操作系统环境下，实际限速精度可能略有偏差。
