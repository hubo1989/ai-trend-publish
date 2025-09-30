# Docker部署配置说明

本项目提供了多种Docker部署配置，以适应不同的使用场景。

## 配置文件概览

| 文件名 | 用途 | 适用场景 |
|--------|------|----------|
| `docker-compose.full.yml` | 原始完整配置（包含构建） | 开发环境，需要现场构建 |
| `docker-compose.production.yml` | 生产环境配置（使用预编译镜像） | 生产环境，完整功能 |
| `docker-compose.simple.yml` | 简化配置（核心服务） | 快速部署，测试环境 |
| `env.production` | 环境变量配置模板 | 所有部署场景 |

## 快速开始

### 1. 编译镜像

```bash
# 快速编译（推荐）
./scripts/quick-build.sh

# 或使用完整编译脚本
./scripts/build-images.sh
```

### 2. 选择配置并部署

#### 选项A：简化部署（推荐新手）

```bash
# 复制配置文件
cp docker-compose.simple.yml /path/to/deploy/docker-compose.yml
cp env.production /path/to/deploy/.env

# 编辑环境变量
nano /path/to/deploy/.env

# 启动服务
cd /path/to/deploy
docker-compose up -d
```

#### 选项B：完整部署（推荐生产环境）

```bash
# 复制配置文件
cp docker-compose.production.yml /path/to/deploy/docker-compose.yml
cp env.production /path/to/deploy/.env
cp -r docker-configs /path/to/deploy/configs

# 编辑环境变量
nano /path/to/deploy/.env

# 启动服务
cd /path/to/deploy
docker-compose up -d
```

## 环境变量配置

### 必须修改的配置项

```bash
# 安全密钥（必须修改）
SERVER_API_KEY=your-super-secret-api-key-change-me
DB_PASSWORD=your-strong-db-password-change-me
DB_ROOT_PASSWORD=your-strong-root-password-change-me
REDIS_PASSWORD=your-redis-password-change-me

# 镜像配置（如果使用远程仓库）
BACKEND_IMAGE=your-registry.com/ai-trend-backend:latest
FRONTEND_IMAGE=your-registry.com/ai-trend-frontend:latest
```

### 常用配置项

```bash
# 服务端口
BACKEND_PORT=8000
FRONTEND_PORT=8080

# 数据库配置
DB_HOST=db
DB_PORT=3306
DB_DATABASE=trendfinder
DB_USER=trendfinder

# Redis配置
REDIS_HOST=redis
REDIS_PORT=6379

# 应用配置
NODE_ENV=production
LOG_LEVEL=INFO
ENABLE_DB=true
```

### 外部服务配置（可选）

```bash
# OpenAI服务
OPENAI_API_KEY=your-openai-key
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-3.5-turbo

# 其他AI服务
JINA_API_KEY=your-jina-key
DASHSCOPE_API_KEY=your-dashscope-key
FIRECRAWL_API_KEY=your-firecrawl-key

# 通知服务
ENABLE_FEISHU=false
FEISHU_WEBHOOK_URL=your-webhook-url
```

## 配置差异说明

### docker-compose.simple.yml
- **特点**：最简配置，只包含核心服务
- **包含**：backend、frontend、database、redis
- **不包含**：nginx反向代理、详细健康检查、高级网络配置
- **适用**：开发环境、快速测试、资源受限环境

### docker-compose.production.yml
- **特点**：完整生产配置
- **包含**：所有服务 + nginx反向代理 + 详细健康检查 + 高级配置
- **额外功能**：
  - Nginx反向代理（可选）
  - 详细的健康检查
  - 数据持久化配置
  - 网络优化
  - 资源限制
- **适用**：生产环境、完整功能需求

## Backend环境变量处理

**重要说明**：在新的配置中，backend服务的所有环境变量都通过`.env`文件处理，不再在docker-compose.yml中重复定义。

```yaml
# 旧的方式（不推荐）
environment:
  - SERVER_API_KEY=${SERVER_API_KEY}
  - DB_HOST=${DB_HOST}
  # ... 更多环境变量

# 新的方式（推荐）
env_file:
  - .env
```

这样做的好处：
1. 配置更集中，易于管理
2. 避免重复定义
3. 支持更多环境变量类型
4. 便于版本控制

## 服务访问地址

启动后，服务可通过以下地址访问：

| 服务 | 地址 | 说明 |
|------|------|------|
| 前端 | http://localhost:8080 | Web界面 |
| 后端API | http://localhost:8000 | API服务 |
| 数据库 | localhost:3306 | MySQL数据库 |
| Redis | localhost:6379 | Redis缓存 |
| Nginx | http://localhost | 反向代理（仅production配置） |

## 常用命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 更新服务
docker-compose pull
docker-compose up -d

# 清理数据（谨慎使用）
docker-compose down -v
```

## 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 修改.env文件中的端口配置
   BACKEND_PORT=8001
   FRONTEND_PORT=8081
   ```

2. **镜像拉取失败**
   ```bash
   # 使用本地镜像
   BACKEND_IMAGE=ai-trend-backend:latest
   FRONTEND_IMAGE=ai-trend-frontend:latest
   ```

3. **数据库连接失败**
   ```bash
   # 检查数据库配置
   DB_HOST=db
   DB_PORT=3306
   DB_PASSWORD=your-password
   ```

### 调试命令

```bash
# 检查网络连接
docker-compose exec backend ping db
docker-compose exec backend ping redis

# 查看环境变量
docker-compose exec backend env

# 进入容器调试
docker-compose exec backend bash
docker-compose exec db mysql -u root -p
```

## 更多信息

- 详细部署指南：[PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)
- 镜像编译指南：[BUILD_IMAGES.md](BUILD_IMAGES.md)
- Docker部署文档：[DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)

