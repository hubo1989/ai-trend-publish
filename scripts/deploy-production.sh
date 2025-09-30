#!/bin/bash

# AI趋势发布系统 - 生产环境部署脚本
# 使用方法: ./deploy-production.sh [目标目录]

set -e

# 默认配置
DEFAULT_DEPLOY_DIR="/opt/ai-trend-publish"
DEPLOY_DIR="${1:-$DEFAULT_DEPLOY_DIR}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    log_info "依赖检查通过"
}

# 创建部署目录结构
create_directory_structure() {
    log_info "创建部署目录结构: $DEPLOY_DIR"
    
    # 创建主目录
    sudo mkdir -p "$DEPLOY_DIR"
    
    # 创建子目录
    sudo mkdir -p "$DEPLOY_DIR"/{configs,data/{mysql,redis,logs,uploads,nginx},ssl,init,scripts}
    
    # 设置权限
    sudo chown -R "$USER:$USER" "$DEPLOY_DIR"
    
    log_info "目录结构创建完成"
}

# 复制配置文件
copy_configuration_files() {
    log_info "复制配置文件..."
    
    # 复制主配置文件
    cp "$SOURCE_DIR/docker-compose.production.yml" "$DEPLOY_DIR/docker-compose.yml"
    
    # 复制环境变量文件
    if [ ! -f "$DEPLOY_DIR/.env" ]; then
        cp "$SOURCE_DIR/env.production" "$DEPLOY_DIR/.env"
        log_warn "请编辑 $DEPLOY_DIR/.env 文件，修改密码和API密钥"
    else
        log_info "环境变量文件已存在，跳过复制"
    fi
    
    # 复制服务配置文件
    cp "$SOURCE_DIR/docker-configs/"* "$DEPLOY_DIR/configs/"
    
    # 复制数据库初始化脚本
    if [ -d "$SOURCE_DIR/drizzle" ]; then
        cp "$SOURCE_DIR/drizzle/"*.sql "$DEPLOY_DIR/init/" 2>/dev/null || log_warn "没有找到数据库初始化脚本"
    fi
    
    # 复制部署脚本
    cp "$SOURCE_DIR/scripts/deploy-production.sh" "$DEPLOY_DIR/scripts/"
    chmod +x "$DEPLOY_DIR/scripts/deploy-production.sh"
    
    log_info "配置文件复制完成"
}

# 构建镜像
build_images() {
    log_info "构建Docker镜像..."
    
    cd "$SOURCE_DIR"
    
    # 读取环境变量
    source "$DEPLOY_DIR/.env"
    
    # 构建后端镜像
    log_info "构建后端镜像: $BACKEND_IMAGE"
    docker build -t "$BACKEND_IMAGE" .
    
    # 构建前端镜像
    log_info "构建前端镜像: $FRONTEND_IMAGE"
    docker build -t "$FRONTEND_IMAGE" ./frontend
    
    log_info "镜像构建完成"
}

# 推送镜像到仓库（可选）
push_images() {
    if [ "$PUSH_IMAGES" = "true" ]; then
        log_info "推送镜像到仓库..."
        
        source "$DEPLOY_DIR/.env"
        
        docker push "$BACKEND_IMAGE"
        docker push "$FRONTEND_IMAGE"
        
        log_info "镜像推送完成"
    fi
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    cd "$DEPLOY_DIR"
    
    # 拉取镜像（如果使用远程镜像）
    docker-compose pull || log_warn "无法拉取镜像，将使用本地镜像"
    
    # 启动服务
    docker-compose up -d
    
    log_info "服务启动完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    cd "$DEPLOY_DIR"
    
    # 等待服务启动
    sleep 30
    
    # 检查服务状态
    docker-compose ps
    
    # 检查健康状态
    log_info "检查服务健康状态..."
    
    # 检查后端服务
    if curl -f http://localhost:8000/health &> /dev/null; then
        log_info "后端服务运行正常"
    else
        log_warn "后端服务可能未正常启动，请检查日志"
    fi
    
    # 检查前端服务
    if curl -f http://localhost:8080/ &> /dev/null; then
        log_info "前端服务运行正常"
    else
        log_warn "前端服务可能未正常启动，请检查日志"
    fi
    
    log_info "部署验证完成"
}

# 显示部署信息
show_deployment_info() {
    log_info "部署完成！"
    echo
    echo "部署目录: $DEPLOY_DIR"
    echo "服务访问地址:"
    echo "  - 前端: http://localhost:8080"
    echo "  - 后端API: http://localhost:8000"
    echo
    echo "常用命令:"
    echo "  - 查看服务状态: cd $DEPLOY_DIR && docker-compose ps"
    echo "  - 查看日志: cd $DEPLOY_DIR && docker-compose logs -f"
    echo "  - 重启服务: cd $DEPLOY_DIR && docker-compose restart"
    echo "  - 停止服务: cd $DEPLOY_DIR && docker-compose down"
    echo
    echo "重要提醒:"
    echo "  1. 请修改 $DEPLOY_DIR/.env 文件中的密码和API密钥"
    echo "  2. 建议定期备份 $DEPLOY_DIR/data 目录"
    echo "  3. 查看详细部署文档: $SOURCE_DIR/PRODUCTION_DEPLOYMENT.md"
}

# 主函数
main() {
    log_info "开始部署AI趋势发布系统到生产环境..."
    
    check_dependencies
    create_directory_structure
    copy_configuration_files
    
    # 询问是否构建镜像
    read -p "是否需要构建镜像? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        build_images
        
        # 询问是否推送镜像
        read -p "是否需要推送镜像到仓库? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            PUSH_IMAGES=true
            push_images
        fi
    fi
    
    start_services
    verify_deployment
    show_deployment_info
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

