#!/bin/bash

set -e

# ========================
# 配置区域（请根据实际情况修改）
# ========================
SERVER_IP="38.209.119.107"
SS_PORT=$(shuf -i 10000-65535 -n 1)  # 随机高位端口
SS_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)  # 32位随机密码
ENC_METHOD="2022-blake3-aes-128-gcm"

echo "=========================================="
echo " 开始部署 Sing-Box + Shadowsocks 2022"
echo "=========================================="
echo "服务器IP: $SERVER_IP"
echo "Shadowsocks 端口: $SS_PORT"
echo "Shadowsocks 密码: $SS_PASSWORD"
echo "加密方式: $ENC_METHOD"
echo "=========================================="

# ========================
# 1. 更新系统 & 安装依赖
# ========================
apt update && apt upgrade -y
apt install -y curl wget jq unzip systemd

# ========================
# 2. 下载最新 sing-box
# ========================
SINGBOX_VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r '.tag_name')
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" == "aarch64" ]; then
    ARCH="arm64"
else
    echo " 不支持的架构: $ARCH"
    exit 1
fi

DOWNLOAD_URL="https://github.com/SagerNet/sing-box/releases/download/${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-${ARCH}.tar.gz"
echo " 下载 sing-box ${SINGBOX_VERSION}..."
wget -q "$DOWNLOAD_URL" -O /tmp/sing-box.tar.gz
tar -xzf /tmp/sing-box.tar.gz -C /usr/local/bin/
rm /tmp/sing-box.tar.gz
chmod +x /usr/local/bin/sing-box

# ========================
# 3. 创建配置文件目录
# ========================
mkdir -p /etc/sing-box
cat > /etc/sing-box/config.json << EOF
{
  "inbounds": [
    {
      "type": "shadowsocks",
      "listen": "::",
      "listen_port": ${SS_PORT},
      "method": "${ENC_METHOD}",
      "password": "${SS_PASSWORD}"
    }
  ],
  "outbounds": [
    {
      "type": "direct"
    }
  ]
}
EOF

# ========================
# 4. 创建 systemd 服务文件
# ========================
cat > /etc/systemd/system/sing-box.service << EOF
[Unit]
Description=Sing-Box Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# ========================
# 5. 启动服务 & 设置开机自启
# ========================
systemctl daemon-reload
systemctl enable sing-box
systemctl start sing-box

# ========================
# 6. 防火墙放行端口（如果启用 ufw）
# ========================
if command -v ufw &> /dev/null; then
    ufw allow $SS_PORT/tcp
    echo "✅ 已放行端口 $SS_PORT"
fi

# ========================
# 7. 输出连接信息
# ========================
echo ""
echo "=========================================="
echo "✅ 部署完成！以下是你的 Shadowsocks 2022 连接信息："
echo "=========================================="
echo "服务器地址: $SERVER_IP"
echo "端口:       $SS_PORT"
echo "密码:       $SS_PASSWORD"
echo "加密方式:   $ENC_METHOD"
echo "协议类型:   Shadowsocks 2022"
echo "=========================================="
echo "📱 客户端推荐:"
echo "  - Windows/macOS/Linux: v2rayN, Clash Verge, Hiddify"
echo "  - Android: SagerNet, Matsuri, Hiddify"
echo "  - iOS: Surge, Quantumult X, Hiddify"
echo "=========================================="
echo "💡 提示：请将上述信息导入支持 SS2022 的客户端即可使用。"
echo "=========================================="

# ========================
# 8. （可选）生成二维码（需 qrencode）
# ========================
if command -v qrencode &> /dev/null; then
    SS_URL="ss://${ENC_METHOD}:${SS_PASSWORD}@${SERVER_IP}:${SS_PORT}"
    echo ""
    echo "🔗 分享链接（可扫码）:"
    echo "$SS_URL"
    echo ""
    echo "️ 二维码:"
    qrencode -t ANSIUTF8 "$SS_URL"
else
    echo ""
    echo "ℹ️ 未安装 qrencode，跳过二维码生成。"
    echo "   安装命令: apt install qrencode"
fi

echo ""
echo "🎉 所有操作已完成！享受高速网络吧～"
