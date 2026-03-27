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
    
    # 交互式配置 API Key 和 Base URL
    echo -e "${YELLOW}开始配置 API 环境变量...${NC}"
    
    # 1. 询问 API Key
    read -p "请输入您的 API Key (官方或第三方的均可，直接回车跳过): " USER_API_KEY
    
    if [ -n "$USER_API_KEY" ]; then
        # 2. 询问 Base URL (默认官方)
        echo -e "如果您使用的是第三方中转 API，请输入接口地址。"
        echo -e "例如: https://api.proxy.com (注意：通常不需要加 /v1)"
        read -p "请输入 Base URL (直接回车则默认使用官方地址): " USER_BASE_URL
        
        # 处理 ~/.bashrc 中的旧配置
        sed -i '/export ANTHROPIC_API_KEY=/d' ~/.bashrc
        sed -i '/export ANTHROPIC_BASE_URL=/d' ~/.bashrc
        
        # 写入新配置
        echo -e '\n# Claude Code Environment Variables' >> ~/.bashrc
        echo "export ANTHROPIC_API_KEY=\"$USER_API_KEY\"" >> ~/.bashrc
        export ANTHROPIC_API_KEY="$USER_API_KEY"
        
        # 如果用户输入了自定义 URL，则写入；否则不写（默认走官方）
        if [ -n "$USER_BASE_URL" ]; then
            echo "export ANTHROPIC_BASE_URL=\"$USER_BASE_URL\"" >> ~/.bashrc
            export ANTHROPIC_BASE_URL="$USER_BASE_URL"
            echo -e "${GREEN}已配置第三方中转地址: $USER_BASE_URL ${NC}"
        else
            echo -e "${GREEN}未输入第三方地址，将使用 Anthropic 官方接口。${NC}"
        fi
        
        echo -e "${GREEN}配置完成！环境变量已写入 ~/.bashrc。${NC}"
        echo -e "请执行 ${YELLOW}source ~/.bashrc${NC} 让环境变量在当前终端生效。"
        echo -e "然后输入 ${GREEN}claude${NC} 即可开始使用！"
    else
        echo -e "${YELLOW}您跳过了自动配置。${NC}"
    fi
else
    echo -e "${RED}安装似乎出现问题，请检查上方报错信息。${NC}"
fi
