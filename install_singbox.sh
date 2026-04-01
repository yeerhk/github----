#!/bin/bash
# =====================================================
# Sing-box SS-2022 专线一键部署脚本 (Server & Client)
# 适用系统: Debian / Ubuntu
# =====================================================

# ----------------- ⚠️ 请在这里修改你的核心变量 ⚠️ -----------------

# 节点角色: 填 "server" 或 "client" 
NODE_ROLE="server"

# 服务端公网 IP (如果是装 server，这里填 0.0.0.0 即可；如果是装 client，server端的真实公网 IP)
SERVER_IP="0.0.0.0"

# 隧道通信端口 (server 和 client 必须保持一致)
SERVER_PORT=4430

# 客户端本地 SOCKS5 代理端口 (仅当 NODE_ROLE="client" 时有效)
CLIENT_SOCKS_PORT=1080

# SS-2022 加密密码 (必须是 32-byte 的 Base64 字符串)
# 强烈建议保持为 "AUTO"，脚本会自动为你生成一个绝对安全的密钥！
SS_PASSWORD="AUTO"

# -----------------------------------------------------------------

# 1. 基础环境检查与准备
echo -e "\n[1/5] 🚀 正在初始化安装环境..."
if [ "$EUID" -ne 0 ]; then
  echo "❌ 错误: 请使用 root 用户运行此脚本 (可以使用 sudo bash)"
  exit 1
fi

apt-get update -y
apt-get install -y curl wget openssl jq

# 2. 处理 SS-2022 密码
if [ "$SS_PASSWORD" == "AUTO" ]; then
    SS_PASSWORD=$(openssl rand -base64 32)
    echo -e "✅ 已自动生成 SS-2022 专属安全密钥: \033[32m$SS_PASSWORD\033[0m"
    echo -e "⚠️ 请务必保存好此密钥，客户端和服务端必须完全一致！"
fi

# 3. 安装 Sing-box (使用官方源)
echo -e "\n[2/5] 📦 正在安装最新版 Sing-box..."
curl -fsSL https://sing-box.app/deb-install.sh | bash

# 4. 生成配置文件
echo -e "\n[3/5] ⚙️ 正在生成 $NODE_ROLE 配置文件..."
mkdir -p /etc/sing-box

if [ "$NODE_ROLE" == "server" ]; then
    # --- 服务端配置 (Azure) ---
    cat > /etc/sing-box/config.json <<EOF
{
  "log": { "level": "info" },
  "inbounds": [
    {
      "type": "shadowsocks",
      "tag": "ss-in",
      "listen": "::",
      "listen_port": $SERVER_PORT,
      "network": "tcp",
      "method": "2022-blake3-aes-256-gcm",
      "password": "$SS_PASSWORD"
    }
  ],
  "outbounds": [
    { "type": "direct", "tag": "direct" }
  ]
}
EOF
elif [ "$NODE_ROLE" == "client" ]; then
    # --- 客户端配置 (/本地) ---
    if [ "$SERVER_IP" == "0.0.0.0" ]; then
        echo "❌ 错误: 作为 client，你必须在脚本顶部填入服务端的真实公网 IP！"
        exit 1
    fi
    cat > /etc/sing-box/config.json <<EOF
{
  "log": { "level": "info" },
  "inbounds": [
    {
      "type": "socks",
      "tag": "socks-in",
      "listen": "127.0.0.1",
      "listen_port": $CLIENT_SOCKS_PORT
    }
  ],
  "outbounds": [
    {
      "type": "shadowsocks",
      "tag": "ss-out",
      "server": "$SERVER_IP",
      "server_port": $SERVER_PORT,
      "method": "2022-blake3-aes-256-gcm",
      "password": "$SS_PASSWORD"
    }
  ]
}
EOF
else
    echo "❌ 错误: NODE_ROLE 只能是 'server' 或 'client'"
    exit 1
fi

# 5. 启动并设置开机自启
echo -e "\n[4/5] 🔄 正在重启 Sing-box 服务..."
systemctl enable sing-box
systemctl restart sing-box

# 6. 检查运行状态
sleep 2
if systemctl is-active --quiet sing-box; then
    echo -e "\n[5/5] 🎉 部署成功！Sing-box 正在稳定运行。"
    echo -e "====================================================="
    echo -e "📌 节点角色: \033[36m$NODE_ROLE\033[0m"
    if [ "$NODE_ROLE" == "server" ]; then
        echo -e "📡 监听端口: \033[33m$SERVER_PORT\033[0m"
        echo -e "🔑 你的密码: \033[32m$SS_PASSWORD\033[0m (请复制此密码用于客户端)"
        echo -e "⚠️ 请确保云服务器防火墙(安全组)已放行 \033[33mTCP $SERVER_PORT\033[0m 端口！"
    else
        echo -e "🔗 连接目标: \033[36m$SERVER_IP:$SERVER_PORT\033[0m"
        echo -e "🔌 本地代理: \033[33msocks5://127.0.0.1:$CLIENT_SOCKS_PORT\033[0m"
        echo -e "🧪 测试命令: \033[32mcurl -x socks5://127.0.0.1:$CLIENT_SOCKS_PORT https://api.ipify.org\033[0m"
    fi
    echo -e "====================================================="
else
    echo -e "\n❌ 启动失败！请使用命令查看报错原因: journalctl -u sing-box --no-pager -n 20"
fi
