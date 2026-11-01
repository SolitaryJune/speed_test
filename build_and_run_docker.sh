#!/bin/bash

# 脚本名称: build_and_run_docker.sh
# 功能: 真正的“一键”部署脚本。自动下载所需文件、构建 Docker 镜像并在后台运行测速容器。
#
# 2026-11 修复说明:
# 1. 下载改为 raw.githubusercontent.com 直连 + curl -f 失败即报错 + HTML 内容校验。
#    原 git.gushao.club 代理会间歇性返回 403 Cloudflare 挑战页，而 curl -sO 遇 HTTP
#    错误不报错，会把 HTML 错误页当文件保存，导致 COPY 找不到文件/构建出垃圾镜像。
# 2. 容器显式 --memory 1g。部分 NAS 的 docker 会给容器套一个极小的默认内存限制
#    （实测遇到过 6MiB），Python 一启动就被 OOM 杀掉，陷入无限重启。
# 3. 默认测速 URL 换成实测能跑满限速的大文件。原默认列表多为失效/被限速的小文件，
#    8 线程大部分时间浪费在反复握手下载几百 KB 的图片上，速度跑不起来。

REPO_OWNER="SolitaryJune"
REPO_NAME="speed_test"
BRANCH="main"
RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"
# 备用代理（直连 GitHub 失败时才使用）
PROXY_RAW_URL="https://git.gushao.club/https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

# 文件列表
FILES=("Dockerfile" "speed_test_limited.py" ".dockerignore")
IMAGE_NAME="speed-tester-limited"
CONTAINER_NAME="speed-tester-instance"

# 默认测速 URL: 微信安装包(dldir1.qq.com)单连接约 2.5MB/s 且多连接可线性叠加，
# 重复传入同一 URL 提高 random.choice 命中权重，8 线程合计可稳定跑满限速值；
# 最后一个阿里云 Ubuntu ISO 仅作分散，失效也不影响整体速度
DEFAULT_URLS=(
    "https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe"
    "https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe"
    "https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe"
    "https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe"
    "https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe"
    "https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe"
    "https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe"
    "https://mirrors.aliyun.com/ubuntu-releases/24.04/ubuntu-24.04.5.1-desktop-amd64.iso"
)

# 检查是否安装了 Docker
if ! command -v docker &> /dev/null
then
    echo "错误: Docker 未安装。请先安装 Docker。"
    exit 1
fi

download_file() {
    local FILE="$1"
    # -f: HTTP 错误码返回非零; -L: 跟随重定向; --retry-all-errors: 连接重置等错误也重试
    for i in 1 2; do
        if curl -fsSL --retry 2 --retry-all-errors --connect-timeout 10 -o "${FILE}" "${RAW_URL}/${FILE}"; then
            return 0
        fi
        sleep 1
    done
    echo "直连 GitHub 失败，尝试代理下载 ${FILE} ..."
    for i in 1 2; do
        if curl -fsSL --retry 2 --retry-all-errors --connect-timeout 10 -o "${FILE}" "${PROXY_RAW_URL}/${FILE}"; then
            return 0
        fi
        sleep 1
    done
    return 1
}

# .dockerignore 只是构建上下文白名单，无需联网：下载失败时直接本地生成
ensure_dockerignore() {
    if download_file ".dockerignore" && verify_file ".dockerignore"; then
        return 0
    fi
    echo "警告: .dockerignore 下载失败，使用本地生成的白名单。"
    printf '*
!Dockerfile
!speed_test_limited.py
' > ".dockerignore"
}

verify_file() {
    local FILE="$1"
    # 非空
    [ -s "${FILE}" ] || return 1
    # 拒绝 Cloudflare 挑战页等 HTML 内容
    if head -c 200 "${FILE}" | grep -qi "<!doctype html\|<html"; then
        return 1
    fi
    return 0
}

# 1. 下载所需文件
echo "--- 1. 下载所需文件 ---"
for FILE in "${FILES[@]}"; do
    echo "正在下载 ${FILE}..."
    if [ "${FILE}" = ".dockerignore" ]; then
        ensure_dockerignore
        continue
    fi
    if ! download_file "${FILE}"; then
        echo "错误: 下载 ${FILE} 失败。请检查网络连接或仓库路径。"
        rm -f "${FILE}"
        exit 1
    fi
    if ! verify_file "${FILE}"; then
        echo "错误: ${FILE} 内容校验失败（可能被代理劫持或返回了错误页）。"
        rm -f "${FILE}"
        exit 1
    fi
done
echo "文件下载完成。"

# 2. 构建 Docker 镜像
echo "--- 2. 开始构建 Docker 镜像: ${IMAGE_NAME} ---"
# 使用 sudo 构建镜像，-q 减少输出
sudo docker build -q -t ${IMAGE_NAME} .
if [ $? -ne 0 ]; then
    echo "--- 错误: Docker 镜像构建失败 ---"
    exit 1
fi
echo "--- Docker 镜像构建成功: ${IMAGE_NAME} ---"

# 3. 运行 Docker 容器 (后台模式)
echo "--- 3. 在后台启动 Docker 容器: ${CONTAINER_NAME} ---"
# 如果已有同名容器在运行，先停止并删除
sudo docker rm -f ${CONTAINER_NAME} &> /dev/null

# 用户未显式传 --urls 时，追加默认大文件列表
RUN_ARGS=("$@")
if ! printf '%s\n' "${RUN_ARGS[@]}" | grep -q -- "--urls"; then
    RUN_ARGS+=(--urls "${DEFAULT_URLS[@]}")
fi

# --memory 1g 防止被默认小内存限制 OOM；--restart always 确保崩溃或重启后自动恢复
sudo docker run -d --name ${CONTAINER_NAME} --restart always \
    --memory 1g --memory-swap 1g \
    ${IMAGE_NAME} "${RUN_ARGS[@]}"

if [ $? -ne 0 ]; then
    echo "--- 错误: Docker 容器启动失败 ---"
    exit 1
fi

echo "--- 容器已在后台启动 ---"
echo "提示: 您可以使用 'sudo docker logs -f ${CONTAINER_NAME}' 查看实时日志。"
echo "提示: 您可以使用 'sudo docker stop ${CONTAINER_NAME}' 停止测速。"

# 4. 清理下载的文件
echo "--- 4. 清理下载的临时文件 ---"
for FILE in "${FILES[@]}"; do
    rm -f "${FILE}"
done
echo "清理完成。"

echo "--- 部署完成，脚本退出 ---"
