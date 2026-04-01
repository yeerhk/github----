sudo bash -c '
# 1. 开启 BBR 网络加速
echo -e "\n\033[32m[1/4] 正在开启 BBR 网络加速...\033[0m"
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# 2. 下载并安装 Gost (更新至 v2.12.0 稳定版)
echo -e "\n\033[32m[2/4] 正在下载 Gost v2.12.0...\033[0m"
wget -qO- https://github.com/ginuerzh/gost/releases/download/v2.12.0/gost-linux-amd64-2.12.0.gz | gzip -d > /usr/local/bin/gost
chmod +x /usr/local/bin/gost

# 3. 交互获取 Azure IP
echo -e "\n\033[33m请输入你的 Azure 服务器公网 IP 地址 (例如: 20.1.2.3): \033[0m"
read AZURE_IP

# 4. 创建 Systemd 后台服务
echo -e "\n\033[32m[3/4] 正在配置守护进程...\033[0m"
cat <<EOF > /etc/systemd/system/gost-client.service
[Unit]
Description=Gost Client Tunnel (v2.12.0)
After=network.target

[Service]
Type=simple
# 核心启动命令：监听本机 9000，通过加密隧道转发给 Azure 的本地 8000 端口
ExecStart=/usr/local/bin/gost -L "tcp://:9000/127.0.0.1:8000" -F "mwss://ai_admin:SuperSecret999@${AZURE_IP}:8443"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 5. 启动服务并设置开机自启
echo -e "\n\033[32m[4/4] 正在启动服务...\033[0m"
systemctl daemon-reload
systemctl enable gost-client
systemctl restart gost-client

echo -e "\n\033[32m====================================================\033[0m"
echo -e "\033[32m🎉 客户端 (VPS-B) Gost v2.12.0 部署成功！\033[0m"
echo -e "当前状态: \033[33m$(systemctl is-active gost-client)\033[0m"
echo -e "本地监听端口: \033[36m9000\033[0m -> 目标指向 Azure 的 \033[36m8000\033[0m"
echo -e "请务必确保 VPS-B 云控制台已放行 \033[31mTCP 9000\033[0m 端口！"
echo -e "现在你可以通过浏览器访问: \033[35mhttp://<VPS-B的IP>:9000\033[0m 了！"
echo -e "\033[32m====================================================\033[0m"
'
