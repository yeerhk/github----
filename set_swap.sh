#!/bin/bash

# ==============================================================================
# 脚本名称: set_swap.sh
# 描述: Linux Swap 一键创建与永久激活脚本（高颜值彩显版）
# ==============================================================================

# 定义 ANSI 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color（重置颜色）

# 确保脚本是以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}${BOLD}❌ 错误: 请使用 sudo 运行此脚本！${NC}"
    echo -e "${YELLOW}例如: sudo bash set_swap.sh${NC}"
    exit 1
fi

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}${BOLD}🚀 开始配置 Linux Swap 虚拟内存...${NC}"
echo -e "${CYAN}==================================================${NC}"

# 1. 检查是否已经存在 swapfile 激活，或者 fstab 里已经有记录
if swapon --show | grep -q '/swapfile' || grep -q '/swapfile' /etc/fstab; then
    echo -e "${YELLOW}⚠️ 提示: 检测到系统中似乎已经配置过 /swapfile。${NC}"
    echo -ne "${PURPLE}${BOLD}是否要删除旧的并重新创建？(y/n): ${NC}"
    read choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo -e "${BLUE}🧹 正在清理旧的 Swap 配置...${NC}"
        swapoff /swapfile 2>/dev/null
        sed -i '\#/swapfile#d' /etc/fstab
        rm -f /swapfile
    else
        echo -e "${RED}🛑 脚本已退出，未做任何修改。${NC}"
        exit 0
    fi
fi

# 2. 划出 2GB 的硬盘空间作为 Swap 文件
echo -e "${BLUE}[1/4] 📦 正在划出 2GB 硬盘空间...${NC}"
if ! fallocate -l 2G /swapfile 2>/dev/null; then
    # 如果系统不支持 fallocate（某些文件系统不支持），则降级使用 dd 命令
    dd if=/dev/zero of=/swapfile bs=1M count=2048
fi

# 3. 修改权限
echo -e "${BLUE}[2/4] 🔒 正在设置安全权限 (600)...${NC}"
chmod 600 /swapfile

# 4. 格式化为 Swap 格式
echo -e "${BLUE}[3/4] 🧹 正在格式化 Swap 文件...${NC}"
mkswap /swapfile >/dev/null

# 5. 立即激活
echo -e "${BLUE}[4/4] ⚡ 正在立即激活 Swap...${NC}"
swapon /swapfile

# 6. 写入开机启动名单
echo -e "${BLUE}[⚙️] 📝 正在将配置写入 /etc/fstab 以确保重启有效...${NC}"
echo '/swapfile none swap sw 0 0' >> /etc/fstab

echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN}${BOLD}🎉 Swap 配置完成！以下是当前的内存状态：${NC}"
echo -e "${GREEN}--------------------------------------------------${NC}"

# 7. 验证成果
free -h

echo -e "${GREEN}==================================================${NC}"
echo -e "${YELLOW}💡 看到上面的 Swap 总量变为 ${BOLD}2.0Gi${NC}${YELLOW}，即说明大功告成！${NC}"
echo -e "${GREEN}==================================================${NC}"