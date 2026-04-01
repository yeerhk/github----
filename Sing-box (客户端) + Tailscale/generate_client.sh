#!/bin/bash
# ====================================================
# Sing-box 国内端 (大本营) 智能分流客户端一键装配脚本
# ====================================================

echo "🚀 正在启动国内端装配流水线..."
echo "请准备好刚才在海外节点生成的【车票信息】！"
echo "------------------------------------------------"

# 1. 交互式获取海外节点信息
read -p "🌐 请输入海外 VPS 的公网 IP: " SERVER_IP
read -p "🔑 请输入 UUID (密码): " UUID
read -p "🛡️  请输入 Public Key (公钥): " PUBLIC_KEY
read -p "🏷️  请输入 Short ID (短 ID): " SHORT_ID

echo "------------------------------------------------"
echo "⚙️ 正在组装智能分流引擎..."

# 2. 创建目录
mkdir -p ./sing-box

# 3. 写入 config.json
cat > ./sing-box/config.json <<EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "0.0.0.0",
      "listen_port": 7890,
      "sniff": true
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "proxy",
      "server": "${SERVER_IP}",
      "server_port": 443,
      "uuid": "${UUID}",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "www.microsoft.com",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": "${PUBLIC_KEY}",
          "short_id": "${SHORT_ID}"
        }
      }
    },
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
    "rule_set": [
      {
        "tag": "geosite-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs",
        "download_detour": "proxy"
      },
      {
        "tag": "geoip-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs",
        "download_detour": "proxy"
      }
    ],
    "rules": [
      {
        "rule_set": [
          "geosite-cn",
          "geoip-cn"
        ],
        "outbound": "direct"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      }
    ],
    "final": "proxy",
    "auto_detect_interface": true
  }
}
EOF

# 4. 打印成功信息
echo ""
echo "✅ 客户端配置组装完成！已保存至: ./sing-box/config.json"
echo "=========================================================="
echo "🎯 你的国内大本营网络状态汇报："
echo "1. 🚪 本地 HTTP/SOCKS5 代理端口已开启在: 7890"
echo "2. 🧠 智能路由已就绪：国内流量直连，海外流量自动加密出海"
echo "3. 🎭 uTLS 指纹伪装已开启：你的流量看起来就像是正版 Chrome 浏览器"
echo "=========================================================="
echo "💡 架构师，现在只需在国内机器上运行 'docker-compose up -d' 即可点亮全图！"
