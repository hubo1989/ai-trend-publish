# Docker完整部署指南

## 概述

本指南将前端和后端服务都打包到Docker中，使用docker-compose统一管理，彻底解决网络连接问题。

## 架构说明

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   前端容器       │    │   后端容器       │    │   数据库容器     │
│   Nginx:80      │───▶│   Deno:8000     │───▶│   MySQL:3306    │
│   (端口8080)     │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                        │                        │
        └────────────────────────┼────────────────────────┘
                                 │
                        Docker网络 (app-network)
```

## 快速部署

### 1. 准备环境变量

```bash
# 复制环境变量模板
cp env.example .env

# 编辑环境变量
vim .env
```

关键配置：
```bash
SERVER_API_KEY=your-secret-api-key-here
DB_PASSWORD=your-secure-password
```

### 2. 一键启动所有服务

```bash
# 构建并启动所有服务
docker-compose -f docker-compose.full.yml up --build -d

# 查看服务状态
docker-compose -f docker-compose.full.yml ps

# 查看日志
docker-compose -f docker-compose.full.yml logs -f
```

### 3. 访问应用

- **前端界面**: http://localhost:8080
- **后端API**: http://localhost:8000
- **数据库**: localhost:3306

## 详细部署步骤

### 步骤1: 环境准备

```bash
# 确保Docker和docker-compose已安装
docker --version
docker-compose --version

# 进入项目目录
cd /Users/hubo/mycode/ai-trend-publish
```

### 步骤2: 配置环境变量

```bash
# 创建环境变量文件
cat > .env << EOF
SERVER_API_KEY=my-secret-api-key-123
ENABLE_DB=true
DB_HOST=db
DB_PORT=3306
DB_USER=trendfinder
DB_PASSWORD=trendfinder123
DB_DATABASE=trendfinder
DB_ROOT_PASSWORD=rootpassword
EOF
```

### 步骤3: 构建和启动服务

```bash
# 停止现有服务（如果有）
docker-compose -f docker-compose.full.yml down

# 清理旧的镜像和容器（可选）
docker system prune -f

# 构建并启动所有服务
docker-compose -f docker-compose.full.yml up --build -d
```

### 步骤4: 验证部署

```bash
# 检查所有容器状态
docker-compose -f docker-compose.full.yml ps

# 检查健康状态
docker-compose -f docker-compose.full.yml exec frontend curl -f http://localhost/
docker-compose -f docker-compose.full.yml exec backend curl -f http://localhost:8000

# 查看日志
docker-compose -f docker-compose.full.yml logs backend
docker-compose -f docker-compose.full.yml logs frontend
```

## 服务详情

### 前端服务 (frontend)
- **容器名**: ai-trend-frontend
- **端口**: 8080:80
- **技术栈**: Nginx + 静态文件
- **功能**: 
  - 提供Web界面
  - API代理到后端
  - 自动CORS处理

### 后端服务 (backend)
- **容器名**: ai-trend-backend  
- **端口**: 8000:8000
- **技术栈**: Deno + JSON-RPC
- **功能**:
  - 数据源管理API
  - 认证和授权
  - 数据库操作

### 数据库服务 (db)
- **容器名**: ai-trend-db
- **端口**: 3306:3306
- **技术栈**: MySQL 8.0
- **功能**:
  - 数据持久化
  - 自动初始化

### 缓存服务 (redis) - 可选
- **容器名**: ai-trend-redis
- **端口**: 6379:6379
- **技术栈**: Redis 7
- **功能**: 缓存和会话存储

## 网络解决方案

### 问题解决
1. **CORS问题**: Nginx代理 + 后端CORS头部
2. **网络隔离**: Docker内部网络通信
3. **端口冲突**: 容器内部端口映射

### Nginx配置亮点
```nginx
# API代理到后端
location /api/ {
    proxy_pass http://backend:8000/api/;
    # 自动添加CORS头部
    add_header Access-Control-Allow-Origin *;
}
```

### 前端自动配置
```javascript
// 自动检测环境并配置API地址
getApiUrl: function() {
    if (window.location.port === '8080') {
        return `${window.location.origin}/api/workflow`;
    }
    return 'http://localhost:8000/api/workflow';
}
```

## 管理命令

### 启动和停止
```bash
# 启动所有服务
docker-compose -f docker-compose.full.yml up -d

# 停止所有服务
docker-compose -f docker-compose.full.yml down

# 重启特定服务
docker-compose -f docker-compose.full.yml restart backend
```

### 日志和调试
```bash
# 查看所有日志
docker-compose -f docker-compose.full.yml logs -f

# 查看特定服务日志
docker-compose -f docker-compose.full.yml logs -f backend

# 进入容器调试
docker-compose -f docker-compose.full.yml exec backend bash
docker-compose -f docker-compose.full.yml exec frontend sh
```

### 数据管理
```bash
# 数据库备份
docker-compose -f docker-compose.full.yml exec db mysqldump -u trendfinder -p trendfinder > backup.sql

# 数据库恢复
docker-compose -f docker-compose.full.yml exec -T db mysql -u trendfinder -p trendfinder < backup.sql

# 清理数据卷
docker-compose -f docker-compose.full.yml down -v
```

## 生产环境配置

### 安全加固
1. 修改默认密码
2. 配置SSL证书
3. 限制网络访问
4. 启用日志监控

### 性能优化
1. 调整Nginx缓存策略
2. 配置数据库连接池
3. 启用Redis缓存
4. 配置资源限制

### 监控和维护
```bash
# 健康检查
docker-compose -f docker-compose.full.yml exec backend curl -f http://localhost:8000
docker-compose -f docker-compose.full.yml exec frontend curl -f http://localhost/

# 资源监控
docker stats

# 系统清理
docker system prune -a
```

## 故障排除

### 常见问题
1. **端口被占用**: 修改docker-compose.yml中的端口映射
2. **数据库连接失败**: 检查环境变量和网络配置
3. **前端无法访问后端**: 检查Nginx代理配置
4. **权限问题**: 检查文件权限和Docker用户组

### 调试步骤
1. 检查容器状态: `docker-compose ps`
2. 查看容器日志: `docker-compose logs [service]`
3. 进入容器调试: `docker-compose exec [service] bash`
4. 检查网络连接: `docker network ls`

## 优势总结

✅ **彻底解决网络问题**: 前后端在同一Docker网络中
✅ **统一管理**: 一个命令启动所有服务  
✅ **生产就绪**: 包含数据库、缓存、负载均衡
✅ **易于部署**: 任何支持Docker的环境都可运行
✅ **自动配置**: 前端自动检测环境配置API地址
✅ **健康检查**: 自动监控服务状态
✅ **数据持久化**: 数据库和缓存数据持久保存

