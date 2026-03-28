#!/bin/bash

echo "🚀 开始一键部署 AI 基础环境 (Python + NVM)..."
echo "================================================="

# 1. 更新系统软件包列表并升级已安装的软件
echo "📦 正在更新系统软件包..."
sudo apt update && sudo apt upgrade -y

# 2. 安装 Python 及必备的编译工具
# build-essential 是为了以后安装某些需要编译的 Python 库 (如 xformers) 做准备
# python3-venv 是极其重要的虚拟环境工具，防止不同 AI 项目的依赖打架
echo "🐍 正在安装 Python3, pip 和 venv 虚拟环境..."
sudo apt install -y curl wget git build-essential python3 python3-pip python3-venv

# 3. 安装 NVM (Node Version Manager)
# 注意：NVM 必须安装在当前用户下，千万不要加 sudo！
echo "🟢 正在下载并安装 NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# 4. 立即加载 NVM 环境变量，使其在当前脚本生效
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 5. 使用 NVM 安装最新的 Node.js LTS (长期支持版)
echo "📦 正在通过 NVM 安装 Node.js LTS 版本..."
nvm install --lts
nvm use --lts

echo "================================================="
echo "🎉 恭喜！一键部署完成！"
echo "⚠️ 重要提示：请关闭当前终端窗口并重新打开，或者输入 'source ~/.bashrc' 让所有环境变量彻底生效。"
