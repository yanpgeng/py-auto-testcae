SINGBOX_VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r '.tag_name')
ARCH=$(uname -m)
[ "$ARCH" == "x86_64" ] && ARCH="amd64"
[ "$ARCH" == "aarch64" ] && ARCH="arm64"

wget -q "https://github.com/SagerNet/sing-box/releases/download/${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-${ARCH}.tar.gz" -O /tmp/sing-box.tar.gz
tar -xzf /tmp/sing-box.tar.gz -C /usr/local/bin/
rm /tmp/sing-box.tar.gz
chmod +x /usr/local/bin/sing-box

echo "✅ sing-box installed: $(sing-box version)"
