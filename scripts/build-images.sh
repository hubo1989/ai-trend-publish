#!/bin/bash

# AI趋势发布系统 - 镜像编译脚本
# 使用方法: ./build-images.sh [版本标签] [镜像仓库地址]

set -e

# 默认配置
DEFAULT_TAG="latest"
DEFAULT_REGISTRY=""

# 参数解析
TAG="${1:-$DEFAULT_TAG}"
REGISTRY="${2:-$DEFAULT_REGISTRY}"

# 镜像名称
BACKEND_IMAGE_NAME="ai-trend-backend"
FRONTEND_IMAGE_NAME="ai-trend-frontend"

# 完整镜像名称
if [ -n "$REGISTRY" ]; then
    BACKEND_IMAGE="$REGISTRY/$BACKEND_IMAGE_NAME:$TAG"
    FRONTEND_IMAGE="$REGISTRY/$FRONTEND_IMAGE_NAME:$TAG"
else
    BACKEND_IMAGE="$BACKEND_IMAGE_NAME:$TAG"
    FRONTEND_IMAGE="$FRONTEND_IMAGE_NAME:$TAG"
fi

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 显示配置信息
show_config() {
    echo "========================================"
    echo "AI趋势发布系统 - 镜像编译配置"
    echo "========================================"
    echo "项目目录: $PROJECT_ROOT"
    echo "版本标签: $TAG"
    echo "镜像仓库: ${REGISTRY:-本地}"
    echo "Backend镜像: $BACKEND_IMAGE"
    echo "Frontend镜像: $FRONTEND_IMAGE"
    echo "========================================"
    echo
}

# 检查Docker环境
check_docker() {
    log_step "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行，请启动Docker"
        exit 1
    fi
    
    log_info "Docker环境检查通过"
}

# 清理旧镜像（可选）
cleanup_old_images() {
    if [ "$CLEANUP" = "true" ]; then
        log_step "清理旧镜像..."
        
        # 删除旧的镜像
        docker rmi "$BACKEND_IMAGE" 2>/dev/null || true
        docker rmi "$FRONTEND_IMAGE" 2>/dev/null || true
        
        # 清理悬空镜像
        docker image prune -f
        
        log_info "镜像清理完成"
    fi
}

# 编译Backend镜像
build_backend() {
    log_step "编译Backend镜像..."
    
    cd "$PROJECT_ROOT"
    
    # 检查Dockerfile是否存在
    if [ ! -f "Dockerfile" ]; then
        log_error "Backend Dockerfile不存在"
        exit 1
    fi
    
    # 编译镜像
    log_info "开始编译Backend镜像: $BACKEND_IMAGE"
    docker build \
        --tag "$BACKEND_IMAGE" \
        --file Dockerfile \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VERSION="$TAG" \
        .
    
    log_info "Backend镜像编译完成"
}

# 编译Frontend镜像
build_frontend() {
    log_step "编译Frontend镜像..."
    
    cd "$PROJECT_ROOT/frontend"
    
    # 检查Dockerfile是否存在
    if [ ! -f "Dockerfile" ]; then
        log_error "Frontend Dockerfile不存在"
        exit 1
    fi
    
    # 编译镜像
    log_info "开始编译Frontend镜像: $FRONTEND_IMAGE"
    docker build \
        --tag "$FRONTEND_IMAGE" \
        --file Dockerfile \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VERSION="$TAG" \
        .
    
    log_info "Frontend镜像编译完成"
}

# 测试镜像
test_images() {
    log_step "测试镜像..."
    
    # 测试Backend镜像
    log_info "测试Backend镜像..."
    if docker run --rm --detach --name test-backend -p 18000:8000 "$BACKEND_IMAGE" &> /dev/null; then
        sleep 10
        if curl -f http://localhost:18000/health &> /dev/null; then
            log_info "Backend镜像测试通过"
        else
            log_warn "Backend镜像健康检查失败"
        fi
        docker stop test-backend &> /dev/null || true
    else
        log_warn "Backend镜像启动测试失败"
    fi
    
    # 测试Frontend镜像
    log_info "测试Frontend镜像..."
    if docker run --rm --detach --name test-frontend -p 18080:80 "$FRONTEND_IMAGE" &> /dev/null; then
        sleep 5
        if curl -f http://localhost:18080/ &> /dev/null; then
            log_info "Frontend镜像测试通过"
        else
            log_warn "Frontend镜像健康检查失败"
        fi
        docker stop test-frontend &> /dev/null || true
    else
        log_warn "Frontend镜像启动测试失败"
    fi
}

# 显示镜像信息
show_image_info() {
    log_step "镜像信息..."
    
    echo "编译完成的镜像:"
    docker images | grep -E "(ai-trend-backend|ai-trend-frontend)" | grep "$TAG"
    
    echo
    echo "镜像大小统计:"
    echo "Backend: $(docker images --format "table {{.Size}}" "$BACKEND_IMAGE" | tail -n 1)"
    echo "Frontend: $(docker images --format "table {{.Size}}" "$FRONTEND_IMAGE" | tail -n 1)"
}

# 推送镜像到仓库
push_images() {
    if [ "$PUSH" = "true" ] && [ -n "$REGISTRY" ]; then
        log_step "推送镜像到仓库..."
        
        # 登录检查
        if ! docker info | grep -q "Username:"; then
            log_warn "未登录镜像仓库，请先执行: docker login $REGISTRY"
            read -p "是否现在登录? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                docker login "$REGISTRY"
            else
                log_warn "跳过镜像推送"
                return
            fi
        fi
        
        # 推送Backend镜像
        log_info "推送Backend镜像: $BACKEND_IMAGE"
        docker push "$BACKEND_IMAGE"
        
        # 推送Frontend镜像
        log_info "推送Frontend镜像: $FRONTEND_IMAGE"
        docker push "$FRONTEND_IMAGE"
        
        log_info "镜像推送完成"
    fi
}

# 生成部署配置
generate_deployment_config() {
    if [ "$GENERATE_CONFIG" = "true" ]; then
        log_step "生成部署配置..."
        
        # 创建临时env文件
        TEMP_ENV="$PROJECT_ROOT/deploy.env"
        cp "$PROJECT_ROOT/env.production" "$TEMP_ENV"
        
        # 更新镜像配置
        sed -i.bak "s|BACKEND_IMAGE=.*|BACKEND_IMAGE=$BACKEND_IMAGE|" "$TEMP_ENV"
        sed -i.bak "s|FRONTEND_IMAGE=.*|FRONTEND_IMAGE=$FRONTEND_IMAGE|" "$TEMP_ENV"
        
        rm "$TEMP_ENV.bak"
        
        log_info "部署配置已生成: $TEMP_ENV"
        log_info "请将此文件复制到部署目录并重命名为 .env"
    fi
}

# 显示使用说明
show_usage() {
    echo "使用方法: $0 [选项] [版本标签] [镜像仓库地址]"
    echo
    echo "参数:"
    echo "  版本标签        镜像版本标签 (默认: latest)"
    echo "  镜像仓库地址    镜像仓库地址 (可选)"
    echo
    echo "环境变量选项:"
    echo "  CLEANUP=true    编译前清理旧镜像"
    echo "  PUSH=true       编译后推送镜像"
    echo "  NO_TEST=true    跳过镜像测试"
    echo "  GENERATE_CONFIG=true  生成部署配置文件"
    echo
    echo "示例:"
    echo "  $0                                    # 编译latest版本到本地"
    echo "  $0 v1.0.0                           # 编译v1.0.0版本到本地"
    echo "  $0 latest registry.example.com      # 编译并推送到私有仓库"
    echo "  PUSH=true $0 v1.0.0 docker.io/user  # 编译并推送到Docker Hub"
    echo
}

# 主函数
main() {
    # 显示使用说明
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    show_config
    
    # 确认编译
    read -p "确认开始编译镜像? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "编译已取消"
        exit 0
    fi
    
    # 执行编译流程
    check_docker
    cleanup_old_images
    build_backend
    build_frontend
    
    if [ "$NO_TEST" != "true" ]; then
        test_images
    fi
    
    show_image_info
    push_images
    generate_deployment_config
    
    # 编译完成
    log_info "镜像编译流程完成！"
    echo
    echo "后续步骤:"
    echo "1. 如需推送镜像: PUSH=true $0 $TAG $REGISTRY"
    echo "2. 使用镜像部署: 参考 PRODUCTION_DEPLOYMENT.md"
    echo "3. 更新环境变量: 修改 .env 文件中的镜像配置"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

