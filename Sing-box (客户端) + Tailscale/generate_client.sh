#!/bin/bash
# ====================================================
# Sing-box 国内端 (大本营) 智能分流客户端一键装配脚本 2.0
# ====================================================

echo "🚀 正在启动国内端装配流水线 (2.0 旗舰版)..."
echo "请准备好刚才在海外节点生成的【车票信息】！"
echo "------------------------------------------------"

# 1. 交互式获取海外节点信息 (增加 SNI 自定义和默认值)
read -p "🌐 请输入海外 VPS 的 IP (推荐填 Tailscale 内网 IP): " SERVER_IP
read -p "🔑 请输入 UUID (密码): " UUID
read -p "🛡️  请输入 Public Key (公钥): " PUBLIC_KEY
read -p "🏷️  请输入 Short ID (短 ID): " SHORT_ID
read -p "🌍 请输入 SNI 伪装域名 (直接回车默认 www.microsoft.com): " SNI_DOMAIN

# 如果用户直接回车没输入，则赋予默认值
SNI_DOMAIN=${SNI_DOMAIN:-www.microsoft.com}

echo "------------------------------------------------"
echo "⚙️ 正在优化国内机的网络内核参数 (加大 UDP 缓冲区)..."
# 自动为客户端机器优化 UDP 缓冲区，提升 QUIC/Tailscale 速度
sudo sysctl -w net.core.rmem_max=2500000 2>/dev/null || echo "⚠️ 提示: 当前非 root 权限，临时跳过内核优化，不影响使用。"

echo "⚙️ 正在组装智能分流引擎与防泄漏 DNS..."

# 2. 创建目录
mkdir -p ./sing-box

# 3. 写入 config.json (注入 DNS 模块并适配新版语法)
cat > ./sing-box/config.json <<EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "dns-remote",
        "address": "tcp://1.1.1.1",
        "detour": "proxy"
      },
      {
        "tag": "dns-local",
        "address": "223.5.5.5",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "rule_set": "geosite-cn",
        "server": "dns-local"
      }
    ],
    "final": "dns-remote",
    "strategy": "ipv4_only"
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
        "server_name": "${SNI_DOMAIN}",
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
echo "3. 🛡️ 防 DNS 泄漏已开启：国内域名用阿里(223.5.5.5)，海外域名走代理用 CF(1.1.1.1)"
echo "4. 🎭 uTLS 指纹伪装已开启：目标 SNI [${SNI_DOMAIN}]"
echo "=========================================================="
echo "💡 架构师，现在只需在国内机器上运行 'docker compose up -d' 即可点亮全图！"
