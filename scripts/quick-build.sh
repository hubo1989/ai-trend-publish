#!/bin/bash

# 快速编译脚本 - 简化版本
# 使用方法: ./quick-build.sh

set -e

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "========================================"
echo "AI趋势发布系统 - 快速镜像编译"
echo "========================================"

# 编译Backend
log_step "编译Backend镜像..."
cd "$PROJECT_ROOT"
docker build -t ai-trend-backend:latest .
log_info "Backend镜像编译完成"

# 编译Frontend
log_step "编译Frontend镜像..."
cd "$PROJECT_ROOT/frontend"
docker build -t ai-trend-frontend:latest .
log_info "Frontend镜像编译完成"

# 显示结果
log_step "编译结果:"
docker images | grep ai-trend

echo
log_info "镜像编译完成！现在可以使用 docker-compose.production.yml 进行部署"
echo
echo "快速部署命令:"
echo "  1. 复制配置: cp docker-compose.production.yml /path/to/deploy/docker-compose.yml"
echo "  2. 复制环境变量: cp env.production /path/to/deploy/.env"
echo "  3. 编辑环境变量: nano /path/to/deploy/.env"
echo "  4. 启动服务: cd /path/to/deploy && docker-compose up -d"

