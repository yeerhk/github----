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

# 3. 创建 Systemd 后台服务
echo -e "\n\033[32m[3/4] 正在配置守护进程...\033[0m"
cat <<EOF > /etc/systemd/system/gost-server.service
[Unit]
Description=Gost Server Tunnel (v2.12.0)
After=network.target

[Service]
Type=simple
# 核心启动命令：监听 8443，开启 mwss 加密，开启 404 伪装防探测
ExecStart=/usr/local/bin/gost -L "mwss://ai_admin:SuperSecret999@:8443?probe_resist=code:404"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 4. 启动服务并设置开机自启
echo -e "\n\033[32m[4/4] 正在启动服务...\033[0m"
systemctl daemon-reload
systemctl enable gost-server
systemctl restart gost-server

echo -e "\n\033[32m====================================================\033[0m"
echo -e "\033[32m🎉 服务端 (Azure) Gost v2.12.0 部署成功！\033[0m"
echo -e "当前状态: \033[33m$(systemctl is-active gost-server)\033[0m"
echo -e "请务必确保 Azure 控制台 (NSG) 已放行 \033[31mTCP 8443\033[0m 端口！"
echo -e "\033[32m====================================================\033[0m"
'
