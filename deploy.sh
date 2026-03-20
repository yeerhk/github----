#!/bin/bash

# 遇到常规错误停止运行
set -e 

# ==========================================
# 🎨 0. 界面 UI 与基础函数
# ==========================================
echo_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
echo_success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
echo_warning() { echo -e "\e[33m[WARNING]\e[0m $1"; }
echo_error() { echo -e "\e[41;37m[ERROR]\e[0m $1"; }

clear
echo -e "\e[36m"
echo "======================================================="
echo "       🚀 Node.js 生产环境交互式自动化部署脚本"
echo "======================================================="
echo -e "\e[0m"

# ==========================================
# 📝 1. 交互式配置收集 (支持 curl | bash)
# ==========================================
echo_info "请配置项目信息 (直接回车将使用括号内的默认值)："

# 注意结尾新增的 < /dev/tty
read -p "1. 项目名称 (PM2中显示的名称) [默认: my-app]: " INPUT_NAME < /dev/tty
PROJECT_NAME=${INPUT_NAME:-"my-app"}

read -p "2. Git 仓库 SSH 地址 [默认: git@github.com:用户名/仓库名.git]: " INPUT_REPO < /dev/tty
GIT_REPO=${INPUT_REPO:-"git@github.com:用户名/仓库名.git"}

read -p "3. 拉取的 Git 分支 [默认: main]: " INPUT_BRANCH < /dev/tty
BRANCH=${INPUT_BRANCH:-"main"}

read -p "4. 是否需要执行编译 (例如 Vue/React/TS)？(y/n) [默认: y]: " INPUT_NEED_BUILD < /dev/tty
INPUT_NEED_BUILD=${INPUT_NEED_BUILD:-"y"}

if [[ "$INPUT_NEED_BUILD" == "y" || "$INPUT_NEED_BUILD" == "Y" ]]; then
    NEED_BUILD=true
    read -p "   ➡️ 请输入编译命令 [默认: npm run build]: " INPUT_BUILD_CMD < /dev/tty
    BUILD_CMD=${INPUT_BUILD_CMD:-"npm run build"}
else
    NEED_BUILD=false
fi

read -p "5. 项目启动命令 (如 npm start 或 node dist/main.js) [默认: npm start]: " INPUT_START_CMD < /dev/tty
START_CMD=${INPUT_START_CMD:-"npm start"}

PROJECT_DIR="$HOME/www/$PROJECT_NAME"


echo ""
echo_success "配置收集完毕！即将开始自动化流程..."
sleep 2

# ==========================================
# 🔑 2. GitHub SSH 密钥检查与初始化 (方案二核心)
# ==========================================
echo_info "正在检查 GitHub SSH 访问权限..."

# 检查是否已有 ed25519 类型的 SSH 密钥，没有则自动生成
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    echo_warning "未检测到本机的 SSH 密钥，正在自动生成..."
    # 静默生成 ed25519 密钥，不设密码
    ssh-keygen -t ed25519 -C "vps-deploy-key" -N "" -f "$HOME/.ssh/id_ed25519" > /dev/null 2>&1
    echo_success "SSH 密钥生成完毕！"
fi

# 测试能否连通 GitHub (关闭 StrictHostKeyChecking 防止卡在确认提示)
# 注意：即使成功，ssh -T 也会返回 exit code 1，所以必须用 grep 捕获输出，并临时关闭 set -e
set +e 
SSH_TEST_RESULT=$(ssh -T -o StrictHostKeyChecking=no git@github.com 2>&1)
set -e

if echo "$SSH_TEST_RESULT" | grep -q "successfully authenticated"; then
    echo_success "GitHub 权限验证通过！(已绑定 Deploy Key)"
else
    echo_error "你的 VPS 还没有访问该 GitHub 仓库的权限！"
    echo "========================================================="
    echo -e "\e[33m请复制下方这把【公钥】，添加到你 GitHub 仓库的 Deploy Keys 中：\e[0m"
    echo "👉 路径：你的 GitHub 仓库 -> Settings -> Deploy keys -> Add deploy key"
    echo "========================================================="
    echo -e "\e[32m"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo -e "\e[0m"
    echo "========================================================="
    echo_warning "⚠️ 添加完成后，请重新运行此脚本 ( ./deploy.sh )！"
    exit 1 # 停止脚本，等待用户去配置
fi

# ==========================================
# 📦 3. 环境检查 (NVM / Node.js / PM2)
# ==========================================
echo_info "检查 Node.js 环境..."
export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
    echo_info "未检测到 NVM，正在下载安装..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash > /dev/null 2>&1
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts > /dev/null 2>&1
    nvm use --lts > /dev/null 2>&1
    echo_success "NVM 及 Node.js (LTS) 安装完成！"
else
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    echo_success "Node.js 已就绪 (版本: $(node -v))"
fi

if ! command -v pm2 &> /dev/null; then
    echo_info "正在全局安装 PM2..."
    npm install -g pm2 > /dev/null 2>&1
    echo_success "PM2 安装完成！"
fi

# ==========================================
# 🚀 4. 拉取代码与安装依赖
# ==========================================
echo_info "准备处理项目代码..."

if [ ! -d "$PROJECT_DIR" ]; then
    echo_info "首次部署，正在克隆仓库 (git clone)..."
    mkdir -p "$HOME/www"
    git clone -b $BRANCH $GIT_REPO "$PROJECT_DIR"
else
    echo_info "项目存在，拉取最新代码 (git pull)..."
    cd "$PROJECT_DIR"
    git reset --hard origin/$BRANCH > /dev/null 2>&1
    git pull origin $BRANCH > /dev/null 2>&1
fi

cd "$PROJECT_DIR"

echo_info "📦 正在安装依赖 (npm install)，这可能需要一点时间..."
npm install > /dev/null 2>&1
echo_success "依赖安装完成！"

# ==========================================
# 🔨 5. 编译程序 (Build)
# ==========================================
if [ "$NEED_BUILD" = true ]; then
    echo_info "🔥 开始编译打包项目 ($BUILD_CMD) ..."
    $BUILD_CMD
    echo_success "编译完成！"
fi

# ==========================================
# 🔄 6. 使用 PM2 启动/重启项目
# ==========================================
echo_info "配置 PM2 进程守护..."

if pm2 list | grep -q "$PROJECT_NAME"; then
    echo_info "项目已在运行，正在平滑重启 (Reloading)..."
    pm2 reload "$PROJECT_NAME" > /dev/null 2>&1
else
    echo_info "项目未运行，正在首次启动 (Starting)..."
    pm2 start "$START_CMD" --name "$PROJECT_NAME" > /dev/null 2>&1
fi

pm2 save > /dev/null 2>&1

echo ""
echo "======================================================="
echo_success "🎉 部署全流程完毕！你的网站已成功运行。"
echo_info "👉 查看实时日志命令: pm2 logs $PROJECT_NAME"
echo_info "👉 查看运行状态命令: pm2 list"
echo "======================================================="
