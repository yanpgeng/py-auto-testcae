#!/bin/bash

# 设置严格模式，遇到错误立即停止
set -e

echo "🚀 开始安装 Sing-Box..."

# ==========================================
# 1. 安装必要依赖 (curl, wget, jq, tar)
# ==========================================
echo " 检查并安装依赖..."
apt update > /dev/null 2>&1
apt install -y curl wget jq tar gzip > /dev/null 2>&1
echo "✅ 依赖安装完成"

# ==========================================
# 2. 获取最新版本的 Sing-Box
# ==========================================
echo "🔍 正在获取最新版本号..."
# 使用 curl 获取 GitHub API 数据，并用 jq 解析标签名
SINGBOX_VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r '.tag_name')

if [ -z "$SINGBOX_VERSION" ] || [ "$SINGBOX_VERSION" == "null" ]; then
    echo "❌ 无法获取最新版本号，请检查网络连接或 GitHub API 状态。"
    exit 1
fi
echo "ℹ️ 检测到最新版本: $SINGBOX_VERSION"

# ==========================================
# 3. 判断系统架构
# ==========================================
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    *)
        echo "❌ 不支持的系统架构: $ARCH"
        exit 1
        ;;
esac
echo "ℹ️ 系统架构: $ARCH"

# ==========================================
# 4. 下载并解压
# ==========================================
DOWNLOAD_URL="https://github.com/SagerNet/sing-box/releases/download/${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-${ARCH}.tar.gz"
TEMP_FILE="/tmp/sing-box.tar.gz"

echo "📥 正在下载: $DOWNLOAD_URL"
wget -q "$DOWNLOAD_URL" -O "$TEMP_FILE"

if [ ! -f "$TEMP_FILE" ]; then
    echo "❌ 下载失败，文件不存在。"
    exit 1
fi

echo " 正在解压到 /usr/local/bin/..."
# 注意：新版 sing-box 解压后通常是一个名为 sing-box-${VERSION}-linux-${ARCH} 的目录，里面包含 sing-box 二进制文件
# 为了兼容性，我们先解压到 /tmp，然后移动二进制文件

tar -xzf "$TEMP_FILE" -C /tmp/

# 查找解压后的二进制文件路径 (通常在子目录里)
BIN_PATH=$(find /tmp -name "sing-box" -type f | head -n 1)

if [ -z "$BIN_PATH" ]; then
    echo "❌ 解压后未找到 sing-box 二进制文件。"
    rm -f "$TEMP_FILE"
    exit 1
fi

# 移动到系统路径
mv "$BIN_PATH" /usr/local/bin/sing-box
chmod +x /usr/local/bin/sing-box

# 清理临时文件
rm -rf /tmp/sing-box*
rm -f "$TEMP_FILE"

# ==========================================
# 5. 验证安装
# ==========================================
echo ""
if command -v sing-box &> /dev/null; then
    VERSION_INFO=$(sing-box version)
    echo "=========================================="
    echo "✅ Sing-Box 安装成功!"
    echo "版本信息:"
    echo "$VERSION_INFO"
    echo "=========================================="
else
    echo "❌ 安装失败，sing-box 命令不可用。"
    exit 1
fi
