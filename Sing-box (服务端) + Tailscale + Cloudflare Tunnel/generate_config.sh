#!/bin/bash
# ====================================================
# Sing-box VLESS + REALITY 跨国高铁一键装配脚本
# ====================================================

echo "🚀 正在启动自动化装配流水线..."

# 1. 创建配置文件存放目录
mkdir -p ./sing-box

# 2. 生成高强度安全密钥
echo "🔑 正在向系统内核申请高强度随机数..."

# 使用 Linux 内核自带的 /proc/sys/kernel/random/uuid 生成标准 UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# 使用 openssl 生成 8 字节的随机十六进制作为 Short ID
SHORT_ID=$(openssl rand -hex 8)

echo "🎭 正在调用 Docker 生成 REALITY 易容密钥对 (可能需要几秒钟)..."
# 调用 Docker 里的 sing-box 临时容器生成密钥对
KEYPAIR=$(docker run --rm ghcr.io/sagernet/sing-box generate reality-keypair)

# 提取私钥和公钥
PRIVATE_KEY=$(echo "$KEYPAIR" | grep PrivateKey | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEYPAIR" | grep PublicKey | awk '{print $2}')

# 3. 组装并写入 config.json
echo "📝 正在生成服务端 config.json..."

cat > ./sing-box/config.json <<EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": 443,
      "sniff": true,
      "sniff_override_destination": true,
      "users": [
        {
          "uuid": "${UUID}",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "www.microsoft.com",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "www.microsoft.com",
            "server_port": 443
          },
          "private_key": "${PRIVATE_KEY}",
          "short_id": [
            "${SHORT_ID}"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "rules": [
      {
        "ip_is_private": true,
        "outbound": "block"
      }
    ],
    "final": "direct"
  }
}
EOF

# 4. 打印最终结果供架构师检阅
echo ""
echo "✅ 组装完成！配置文件已保存至: ./sing-box/config.json"
echo ""
echo "=========================================================="
echo "🎉 你的【客户端】专属车票信息如下（请截图或复制保存）："
echo "----------------------------------------------------------"
echo "📍 服务器 IP  : (请填写你这台海外 VPS 的公网 IP)"
echo "🔌 端口       : 443"
echo "🔑 密码(UUID) : ${UUID}"
echo "🛡️  公钥(PubKey): ${PUBLIC_KEY}"
echo "🏷️  短 ID(Short): ${SHORT_ID}"
echo "🎭 伪装域名   : www.microsoft.com"
echo "🌊 流控(Flow) : xtls-rprx-vision"
echo "=========================================================="
echo "💡 架构师，现在只需运行 'docker-compose up -d' 即可全线通车！"
