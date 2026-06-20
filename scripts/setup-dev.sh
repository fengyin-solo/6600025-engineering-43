#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
LOG_DIR="$PROJECT_ROOT/logs"
PID_DIR="$PROJECT_ROOT/.pids"

BACKEND_PORT=8080
FRONTEND_PORT=5180
BACKEND_PID_FILE="$PID_DIR/backend.pid"
FRONTEND_PID_FILE="$PID_DIR/frontend.pid"
BACKEND_LOG="$LOG_DIR/backend.log"
FRONTEND_LOG="$LOG_DIR/frontend.log"
MVN_CMD=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

step_count=0
total_steps=7

print_banner() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   CAN Bus Analyzer - 联调环境准备脚本   ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_step() {
    step_count=$((step_count + 1))
    echo -e "${YELLOW}[${step_count}/${total_steps}]${NC} ${BLUE}$1${NC}"
    echo -e "----------------------------------------"
}

check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 完成${NC}"
    else
        echo -e "${RED}✗ 失败${NC}"
        exit 1
    fi
    echo ""
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

find_mvn() {
    if command_exists mvn; then
        echo "mvn"
        return 0
    fi
    local candidates=(
        "$HOME/.sdkman/candidates/maven/current/bin/mvn"
        "/opt/homebrew/bin/mvn"
        "/usr/local/bin/mvn"
        "$HOME/.local/bin/mvn"
    )
    for c in "${candidates[@]}"; do
        if [ -x "$c" ]; then
            echo "$c"
            return 0
        fi
    done
    return 1
}

kill_port() {
    local port=$1
    local pid=$(lsof -ti:$port 2>/dev/null || true)
    if [ -n "$pid" ]; then
        echo -e "${YELLOW}端口 $port 被进程 $pid 占用，正在清理...${NC}"
        kill -9 $pid 2>/dev/null || true
        sleep 1
    fi
}

wait_for_port() {
    local port=$1
    local timeout=$2
    local start_time=$(date +%s)
    echo -n "等待端口 $port 就绪"
    while ! lsof -i:$port >/dev/null 2>&1; do
        local current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge $timeout ]; then
            echo -e "\n${RED}超时：端口 $port 未能在 ${timeout}s 内就绪${NC}"
            return 1
        fi
        echo -n "."
        sleep 1
    done
    echo -e " ${GREEN}就绪${NC}"
    return 0
}

check_connectivity() {
    local url=$1
    local name=$2
    local max_retries=10
    local retry_count=0

    echo -n "检查 $name 联通性"
    while [ $retry_count -lt $max_retries ]; do
        if curl -s --connect-timeout 2 "$url" >/dev/null 2>&1; then
            echo -e " ${GREEN}✓ 联通${NC}"
            return 0
        fi
        retry_count=$((retry_count + 1))
        echo -n "."
        sleep 2
    done
    echo -e "\n${RED}✗ 无法联通 $url${NC}"
    return 1
}

mkdir -p "$LOG_DIR"
mkdir -p "$PID_DIR"

print_banner

print_step "检查运行环境依赖"
echo "→ 检查 Java..."
if command_exists java; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' | cut -d. -f1)
    if [ "$JAVA_VERSION" -ge 17 ]; then
        echo -e "  ${GREEN}✓ Java $JAVA_VERSION 已安装${NC}"
    else
        echo -e "  ${RED}✗ Java 版本过低，需要 Java 17+，当前为 Java $JAVA_VERSION${NC}"
        exit 1
    fi
else
    echo -e "  ${RED}✗ Java 未安装，请先安装 Java 17+${NC}"
    exit 1
fi

echo "→ 检查 Maven..."
MVN_CMD=$(find_mvn || true)
if [ -n "$MVN_CMD" ]; then
    MVN_VERSION=$($MVN_CMD -v 2>&1 | head -n 1 | grep -oP 'Apache Maven \K[^\s]+' || echo "unknown")
    echo -e "  ${GREEN}✓ Maven 已安装 (${MVN_VERSION}) [${MVN_CMD}]${NC}"
else
    echo -e "  ${RED}✗ Maven 未安装，请先安装 Maven${NC}"
    echo -e "  ${YELLOW}  提示: 可通过 brew install maven 或 sdk install maven 安装${NC}"
    exit 1
fi

echo "→ 检查 Node.js..."
if command_exists node; then
    NODE_VERSION=$(node -v | sed 's/v//')
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 18 ]; then
        echo -e "  ${GREEN}✓ Node.js $NODE_VERSION 已安装${NC}"
    else
        echo -e "  ${YELLOW}! Node.js 版本偏低，建议 Node.js 18+，当前为 $NODE_VERSION${NC}"
    fi
else
    echo -e "  ${RED}✗ Node.js 未安装，请先安装 Node.js 18+${NC}"
    exit 1
fi

echo "→ 检查 npm..."
if command_exists npm; then
    echo -e "  ${GREEN}✓ npm 已安装 ($(npm -v))${NC}"
else
    echo -e "  ${RED}✗ npm 未安装${NC}"
    exit 1
fi
check_success

print_step "检查并清理端口占用"
kill_port $BACKEND_PORT
kill_port $FRONTEND_PORT
check_success

print_step "安装后端依赖 (Maven)"
cd "$BACKEND_DIR"
echo "→ 执行 mvn dependency:resolve ..."
$MVN_CMD dependency:resolve -q
echo "→ 编译项目 ..."
$MVN_CMD compile -q -DskipTests
check_success

print_step "安装前端依赖 (npm)"
cd "$FRONTEND_DIR"
if [ ! -d "node_modules" ] || [ -n "$FORCE_INSTALL" ]; then
    echo "→ 执行 npm install ..."
    npm install
else
    echo "→ node_modules 已存在，跳过安装（设置 FORCE_INSTALL=1 可强制重新安装）"
fi
check_success

print_step "启动后端服务 (Spring Boot)"
cd "$BACKEND_DIR"
nohup $MVN_CMD spring-boot:run > "$BACKEND_LOG" 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > "$BACKEND_PID_FILE"
echo -e "  后端 PID: $BACKEND_PID"
echo -e "  日志文件: $BACKEND_LOG"

if wait_for_port $BACKEND_PORT 60; then
    check_success
else
    echo -e "${RED}后端启动失败，查看日志: tail -f $BACKEND_LOG${NC}"
    exit 1
fi

print_step "启动前端服务 (Vite)"
cd "$FRONTEND_DIR"
nohup npm run dev > "$FRONTEND_LOG" 2>&1 &
FRONTEND_PID=$!
echo $FRONTEND_PID > "$FRONTEND_PID_FILE"
echo -e "  前端 PID: $FRONTEND_PID"
echo -e "  日志文件: $FRONTEND_LOG"

if wait_for_port $FRONTEND_PORT 30; then
    check_success
else
    echo -e "${RED}前端启动失败，查看日志: tail -f $FRONTEND_LOG${NC}"
    exit 1
fi

print_step "验证前后端联通性"
sleep 2

echo "→ 直连后端 API..."
check_connectivity "http://localhost:${BACKEND_PORT}/api/stats" "后端接口"

echo "→ 通过前端代理访问后端..."
check_connectivity "http://localhost:${FRONTEND_PORT}/api/stats" "前端代理"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}       联调环境准备完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "  前端地址: ${BLUE}http://localhost:${FRONTEND_PORT}${NC}"
echo -e "  后端地址: ${BLUE}http://localhost:${BACKEND_PORT}${NC}"
echo -e "  后端 API: ${BLUE}http://localhost:${BACKEND_PORT}/api/*${NC}"
echo -e ""
echo -e "  停止服务请运行: ${YELLOW}./scripts/stop-dev.sh${NC}"
echo -e "  查看后端日志: ${YELLOW}tail -f logs/backend.log${NC}"
echo -e "  查看前端日志: ${YELLOW}tail -f logs/frontend.log${NC}"
echo -e "${GREEN}========================================${NC}"
