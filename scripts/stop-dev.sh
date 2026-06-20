#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PID_DIR="$PROJECT_ROOT/.pids"
LOG_DIR="$PROJECT_ROOT/logs"

BACKEND_PORT=8080
FRONTEND_PORT=5180
BACKEND_PID_FILE="$PID_DIR/backend.pid"
FRONTEND_PID_FILE="$PID_DIR/frontend.pid"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   CAN Bus Analyzer - 停止联调环境      ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

kill_by_pid_file() {
    local pid_file=$1
    local name=$2

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${YELLOW}正在停止 $name (PID: $pid)...${NC}"
            kill "$pid" 2>/dev/null || true
            local count=0
            while ps -p "$pid" > /dev/null 2>&1 && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            if ps -p "$pid" > /dev/null 2>&1; then
                echo -e "${YELLOW}优雅停止超时，强制终止...${NC}"
                kill -9 "$pid" 2>/dev/null || true
            fi
            if ! ps -p "$pid" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ $name 已停止${NC}"
            fi
        else
            echo -e "${YELLOW}! $name 进程 (PID: $pid) 已不存在${NC}"
        fi
        rm -f "$pid_file"
    else
        echo -e "${YELLOW}! 未找到 $name PID 文件，尝试端口检测...${NC}"
    fi
}

kill_by_port() {
    local port=$1
    local name=$2
    local pids=$(lsof -ti:$port 2>/dev/null || true)

    if [ -n "$pids" ]; then
        echo -e "${YELLOW}端口 $port 仍被占用，正在清理 $name 进程...${NC}"
        for pid in $pids; do
            if ps -p "$pid" > /dev/null 2>&1; then
                echo "  → 终止 PID: $pid"
                kill -9 "$pid" 2>/dev/null || true
            fi
        done
        sleep 1
        if ! lsof -i:$port >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $name 端口 $port 已释放${NC}"
        fi
    fi
}

print_banner

echo -e "${BLUE}[1/2]${NC} 停止后端服务..."
kill_by_pid_file "$BACKEND_PID_FILE" "后端服务"
kill_by_port "$BACKEND_PORT" "后端"
echo ""

echo -e "${BLUE}[2/2]${NC} 停止前端服务..."
kill_by_pid_file "$FRONTEND_PID_FILE" "前端服务"
kill_by_port "$FRONTEND_PORT" "前端"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}       联调环境已停止${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "  日志文件保留在: ${YELLOW}$LOG_DIR${NC}"
echo -e "  重新启动请运行: ${YELLOW}./scripts/setup-dev.sh${NC}"
echo -e "${GREEN}========================================${NC}"
