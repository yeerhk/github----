#!/bin/bash

# 定义颜色输出，让界面更美观
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 恢复默认颜色

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Claude Code 一键部署脚本 (Ubuntu/Debian) ${NC}"
echo -e "${GREEN}========================================${NC}"

# 1. 检查是否为 root 用户 (做菜需要厨房钥匙)
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}请使用 root 权限运行此脚本。请输入: sudo $0${NC}"
  exit 1
fi

# 2. 更新系统包列表
echo -e "${YELLOW}[1/4] 正在更新系统软件包列表...${NC}"
apt-get update -y

# 3. 安装必要的依赖 (curl 用于下载)
echo -e "${YELLOW}[2/4] 正在安装基础依赖 (curl)...${NC}"
apt-get install -y curl

# 4. 安装 Node.js (Claude Code 运行的底层环境)
# 这里我们选择安装 Node.js 20.x LTS 版本，兼容性最好
echo -e "${YELLOW}[3/4] 正在安装 Node.js 20.x 环境...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    echo -e "${GREEN}Node.js 安装成功！版本: $(node -v)${NC}"
else
    echo -e "${GREEN}检测到已安装 Node.js，版本: $(node -v)${NC}"
fi

# 5. 全局安装 Claude Code
echo -e "${YELLOW}[4/4] 正在通过 npm 全局安装 Claude Code...${NC}"
npm install -g @anthropic-ai/claude-code

# 6. 验证安装与配置 API Key
if command -v claude &> /dev/null; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}🎉 恭喜！Claude Code 部署成功！${NC}"
    echo -e "${GREEN}当前版本: $(claude --version)${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    # 交互式配置 API Key
    echo -e "${YELLOW}为了在 VPS 环境下使用，需要配置 API Key。${NC}"
    read -p "请输入您的 Anthropic API Key (直接回车可跳过，稍后手动配置): " USER_API_KEY
    
    if [ -n "$USER_API_KEY" ]; then
        # 检查 ~/.bashrc 中是否已经存在配置，避免重复写入
        if grep -q "export ANTHROPIC_API_KEY=" ~/.bashrc; then
            # 替换旧的 Key (使用 sed)
            sed -i "s/^export ANTHROPIC_API_KEY=.*/export ANTHROPIC_API_KEY=\"$USER_API_KEY\"/" ~/.bashrc
            echo -e "${GREEN}已更新 ~/.bashrc 中的 API Key 配置。${NC}"
        else
            # 追加新的 Key
            echo -e '\n# Claude Code API Key' >> ~/.bashrc
            echo "export ANTHROPIC_API_KEY=\"$USER_API_KEY\"" >> ~/.bashrc
            echo -e "${GREEN}已将 API Key 写入 ~/.bashrc。${NC}"
        fi
        
        # 立即在当前脚本会话中生效
        export ANTHROPIC_API_KEY="$USER_API_KEY"
        
        echo -e "${GREEN}配置完成！${NC}"
        echo -e "请执行 ${YELLOW}source ~/.bashrc${NC} 让环境变量在当前终端生效。"
        echo -e "然后输入 ${GREEN}claude${NC} 即可开始使用！"
    else
        echo -e "${YELLOW}您跳过了自动配置。${NC}"
        echo -e "请稍后手动执行以下命令设置您的 API Key："
        echo -e "export ANTHROPIC_API_KEY='你的_sk-xxxx_密钥'"
    fi
else
    echo -e "${RED}安装似乎出现问题，请检查上方报错信息。${NC}"
fi
