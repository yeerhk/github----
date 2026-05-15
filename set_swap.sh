#!/bin/bash

# ==============================================================================
# 脚本名称: set_swap.sh
# 描述: Linux Swap 一键创建与永久激活脚本（带智能检测）
# ==============================================================================

# 确保脚本是以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "❌ 错误: 请使用 sudo 运行此脚本！例如: sudo bash set_swap.sh"
    exit 1
fi

echo "=========================================="
echo "🚀 开始配置 Linux Swap 虚拟内存..."
echo "=========================================="

# 1. 检查是否已经存在 swapfile 激活，或者 fstab 里已经有记录
if swapon --show | grep -q '/swapfile' || grep -q '/swapfile' /etc/fstab; then
    echo "⚠️ 提示: 检测到系统中似乎已经配置过 /swapfile。"
    read -p "是否要删除旧的并重新创建？(y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "🧹 正在清理旧的 Swap 配置..."
        swapoff /swapfile 2>/dev/null
        sed -i '\#/swapfile#d' /etc/fstab
        rm -f /swapfile
    else
        echo "🛑 脚本已退出，未做任何修改。"
        exit 0
    fi
fi

# 2. 划出 2GB 的硬盘空间作为 Swap 文件
echo "📦 1/4 正在划出 2GB 硬盘空间..."
if ! fallocate -l 2G /swapfile 2>/dev/null; then
    # 如果系统不支持 fallocate（某些文件系统不支持），则降级使用 dd 命令
    dd if=/dev/zero of=/swapfile bs=1M count=2048
fi

# 3. 修改权限
echo "🔒 2/4 正在设置安全权限 (600)..."
chmod 600 /swapfile

# 4. 格式化为 Swap 格式
echo "🧹 3/4 正在格式化 Swap 文件..."
mkswap /swapfile >/dev/null

# 5. 立即激活
echo "⚡ 4/4 正在立即激活 Swap..."
swapon /swapfile

# 6. 写入开机启动名单（签合同）
echo "📝 正在将配置写入 /etc/fstab 以确保重启有效..."
echo '/swapfile none swap sw 0 0' >> /etc/fstab

echo "------------------------------------------"
echo "🎉 Swap 配置完成！以下是当前的内存状态："
echo "------------------------------------------"

# 7. 验证成果
free -h

echo "=========================================="
echo "💡 看到上面的 Swap 总量为 2.0Gi 变大，即说明大功告成！"
echo "=========================================="