# AI趋势发布系统 - 生产环境部署指南

## 概述

本指南详细说明如何在生产环境中使用预编译镜像部署AI趋势发布系统。

## 目录结构

建议的生产环境部署目录结构：

```
/opt/ai-trend-publish/
├── docker-compose.yml          # 主配置文件
├── .env                        # 环境变量配置
├── configs/                    # 配置文件目录
│   ├── nginx.conf             # Nginx配置
│   ├── mysql.conf             # MySQL配置
│   └── redis.conf             # Redis配置
├── data/                      # 数据持久化目录
│   ├── mysql/                 # MySQL数据
│   ├── redis/                 # Redis数据
│   ├── logs/                  # 应用日志
│   ├── uploads/               # 文件上传
│   └── nginx/                 # Nginx日志
├── ssl/                       # SSL证书目录（可选）
│   ├── cert.pem
│   └── key.pem
├── init/                      # 数据库初始化脚本
│   └── init.sql
└── scripts/                   # 部署脚本
    ├── deploy.sh
    ├── backup.sh
    └── restore.sh
```

## 部署步骤

### 1. 准备环境

```bash
# 创建部署目录
sudo mkdir -p /opt/ai-trend-publish
cd /opt/ai-trend-publish

# 创建必要的子目录
sudo mkdir -p {configs,data/{mysql,redis,logs,uploads,nginx},ssl,init,scripts}

# 设置权限
sudo chown -R $USER:$USER /opt/ai-trend-publish
```

### 2. 选择部署配置

项目提供了两种部署配置：

#### 完整版本（推荐生产环境）
```bash
# 复制完整配置（包含nginx、详细的健康检查等）
cp /path/to/source/docker-compose.production.yml /opt/ai-trend-publish/docker-compose.yml
cp /path/to/source/env.production /opt/ai-trend-publish/.env

# 复制服务配置文件
cp /path/to/source/docker-configs/* /opt/ai-trend-publish/configs/
```

#### 简化版本（快速部署）
```bash
# 复制简化配置（只包含核心服务）
cp /path/to/source/docker-compose.simple.yml /opt/ai-trend-publish/docker-compose.yml
cp /path/to/source/env.production /opt/ai-trend-publish/.env
```

### 3. 复制其他文件

```bash
# 复制数据库初始化脚本（如果有）
cp /path/to/source/drizzle/*.sql /opt/ai-trend-publish/init/
```

### 4. 配置环境变量

编辑 `.env` 文件，修改以下关键配置：

```bash
# 必须修改的安全配置
SERVER_API_KEY=your-super-secret-api-key-change-me
DB_PASSWORD=your-strong-db-password-change-me
DB_ROOT_PASSWORD=your-strong-root-password-change-me
REDIS_PASSWORD=your-redis-password-change-me

# 镜像配置（替换为您的镜像仓库地址）
BACKEND_IMAGE=your-registry.com/ai-trend-backend:latest
FRONTEND_IMAGE=your-registry.com/ai-trend-frontend:latest

# 端口配置（根据需要调整）
BACKEND_PORT=8000
FRONTEND_PORT=8080
HTTP_PORT=80
HTTPS_PORT=443

# 外部服务API密钥（根据需要配置）
OPENAI_API_KEY=your-openai-api-key
FIRECRAWL_API_KEY=your-firecrawl-api-key
JINA_API_KEY=your-jina-api-key
```

### 5. 构建和推送镜像

在源码目录执行以下命令构建镜像：

```bash
# 构建后端镜像
docker build -t your-registry.com/ai-trend-backend:latest .

# 构建前端镜像
docker build -t your-registry.com/ai-trend-frontend:latest ./frontend

# 推送镜像到仓库
docker push your-registry.com/ai-trend-backend:latest
docker push your-registry.com/ai-trend-frontend:latest
```

### 6. 启动服务

```bash
cd /opt/ai-trend-publish

# 拉取最新镜像
docker-compose pull

# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 7. 验证部署

```bash
# 检查服务健康状态
curl http://localhost:8000/health
curl http://localhost:8080/

# 如果使用nginx
curl http://localhost/health
curl http://localhost/api/health
```

## 服务管理

### 基本操作

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启特定服务
docker-compose restart backend

# 查看日志
docker-compose logs -f backend

# 更新服务
docker-compose pull
docker-compose up -d
```

### 服务配置说明

#### 可选服务

使用 `profiles` 控制可选服务：

```bash
# 启动包含nginx的完整服务
docker-compose --profile nginx up -d

# 只启动核心服务（不包含nginx）
docker-compose up -d
```

#### 端口映射

- **8000**: 后端API服务
- **8080**: 前端Web服务
- **3306**: MySQL数据库（可选暴露）
- **6379**: Redis缓存（可选暴露）
- **80/443**: Nginx反向代理（可选）

## 数据管理

### 数据备份

```bash
# 备份MySQL数据
docker-compose exec db mysqldump -u root -p${DB_ROOT_PASSWORD} ${DB_DATABASE} > backup.sql

# 备份Redis数据
docker-compose exec redis redis-cli --rdb /data/backup.rdb

# 备份整个数据目录
tar -czf ai-trend-backup-$(date +%Y%m%d).tar.gz data/
```

### 数据恢复

```bash
# 恢复MySQL数据
docker-compose exec -T db mysql -u root -p${DB_ROOT_PASSWORD} ${DB_DATABASE} < backup.sql

# 恢复Redis数据
docker-compose exec redis redis-cli --rdb /data/dump.rdb
```

## 监控和日志

### 日志查看

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend

# 查看最近的日志
docker-compose logs --tail=100 backend
```

### 健康检查

所有服务都配置了健康检查，可以通过以下命令查看：

```bash
# 查看服务健康状态
docker-compose ps

# 查看详细健康检查信息
docker inspect ai-trend-backend | grep -A 10 "Health"
```

## 性能优化

### 资源限制

可以在docker-compose.yml中添加资源限制：

```yaml
services:
  backend:
    # ... 其他配置
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### 数据库优化

- 根据实际负载调整MySQL配置文件中的参数
- 定期执行数据库维护操作
- 监控慢查询日志

### Redis优化

- 根据内存使用情况调整maxmemory设置
- 选择合适的淘汰策略
- 监控内存使用和命中率

## 安全配置

### 网络安全

- 使用防火墙限制端口访问
- 配置SSL/TLS证书
- 定期更新系统和依赖

### 密钥管理

- 使用强密码
- 定期轮换API密钥
- 使用密钥管理服务（如HashiCorp Vault）

### 访问控制

- 配置适当的用户权限
- 使用非root用户运行容器
- 定期审计访问日志

## 故障排除

### 常见问题

1. **服务无法启动**
   - 检查环境变量配置
   - 查看服务日志
   - 验证镜像是否可用

2. **数据库连接失败**
   - 检查数据库服务状态
   - 验证连接参数
   - 查看数据库日志

3. **性能问题**
   - 监控资源使用情况
   - 检查数据库查询性能
   - 优化应用配置

### 调试命令

```bash
# 进入容器调试
docker-compose exec backend bash
docker-compose exec db mysql -u root -p

# 查看网络配置
docker network ls
docker network inspect ai-trend-publish_app-network

# 查看卷挂载
docker volume ls
docker volume inspect ai-trend-publish_db_data
```

## 更新和维护

### 应用更新

```bash
# 拉取新镜像
docker-compose pull

# 滚动更新
docker-compose up -d

# 验证更新
docker-compose ps
```

### 系统维护

- 定期清理未使用的镜像和容器
- 监控磁盘空间使用
- 更新系统安全补丁
- 备份重要数据

## 支持和联系

如果在部署过程中遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查项目的GitHub Issues
3. 联系技术支持团队

---

**注意**: 请确保在生产环境中使用强密码和安全配置，定期备份数据，并保持系统更新。
