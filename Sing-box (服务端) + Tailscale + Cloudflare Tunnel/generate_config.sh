#!/bin/bash
# ====================================================
# Sing-box VLESS + REALITY 跨国高铁一键装配脚本 (适配 1.13.0+ 新语法)
# ====================================================

echo "🚀 正在启动自动化装配流水线..."

# 1. 创建配置文件存放目录
mkdir -p ./sing-box

# 2. 生成高强度安全密钥
echo "🔑 正在向系统内核申请高强度随机数..."

UUID=$(cat /proc/sys/kernel/random/uuid)
SHORT_ID=$(openssl rand -hex 8)

echo "🎭 正在调用 Docker 生成 REALITY 易容密钥对 (可能需要几秒钟)..."
KEYPAIR=$(docker run --rm ghcr.io/sagernet/sing-box generate reality-keypair)

PRIVATE_KEY=$(echo "$KEYPAIR" | grep PrivateKey | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEYPAIR" | grep PublicKey | awk '{print $2}')

# 3. 组装并写入 config.json (⭐ 这里使用了最新的 1.13.0 语法)
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
        "inbound": "vless-in",
        "action": "sniff"
      },
      {
        "ip_cidr": [
          "10.0.0.0/8",
          "172.16.0.0/12",
          "192.168.0.0/16",
          "127.0.0.0/8",
          "fc00::/7",
          "fe80::/10"
        ],
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
echo "💡 架构师，现在只需运行 'docker compose up -d' 即可全线通车！"
