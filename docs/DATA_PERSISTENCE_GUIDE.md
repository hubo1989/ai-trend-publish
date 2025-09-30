# 数据持久化和初始化指南

本指南详细说明如何确保数据永久保存，以及如何正确进行数据库初始化。

## 数据持久化策略

### 1. 数据卷配置

项目使用Docker卷来确保数据持久化，即使容器被删除，数据也会保留。

```yaml
volumes:
  # 数据库数据持久化
  db_data:
    name: ai-trend-publish_db_data
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/mysql  # 绑定到本地目录

  # Redis数据持久化
  redis_data:
    name: ai-trend-publish_redis_data
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/redis

  # 应用数据持久化
  app_logs:
    driver_opts:
      device: ./data/logs
  app_uploads:
    driver_opts:
      device: ./data/uploads
```

### 2. 目录结构

部署后的数据目录结构：

```
/opt/ai-trend-publish/
├── docker-compose.yml
├── .env
├── data/                    # 持久化数据目录
│   ├── mysql/              # 数据库数据
│   │   ├── trendfinder/    # 数据库文件
│   │   └── mysql/          # 系统数据库
│   ├── redis/              # Redis数据
│   │   ├── dump.rdb        # RDB快照
│   │   └── appendonly.aof  # AOF日志
│   ├── logs/               # 应用日志
│   └── uploads/            # 上传文件
└── configs/                # 配置文件
```

## 数据库初始化方案

### 方案1：使用Drizzle初始化（推荐）

这是您当前使用的方式，我已经集成到新的配置中：

```yaml
# docker-compose.with-init.yml
services:
  drizzle-init:
    image: ai-trend-backend:latest
    container_name: drizzle-init
    env_file:
      - .env
    environment:
      - DB_HOST=db
      - DB_PORT=3306
    command: deno run -A npm:drizzle-kit push
    networks:
      - app-network
    depends_on:
      db:
        condition: service_healthy
    restart: "no"  # 只运行一次
    profiles:
      - init  # 使用profile控制
```

#### 使用步骤：

```bash
# 1. 启动数据库和Redis
docker-compose up -d db redis

# 2. 等待数据库就绪
docker-compose logs db

# 3. 运行数据库初始化
docker-compose --profile init up drizzle-init

# 4. 启动其他服务
docker-compose up -d backend frontend
```

### 方案2：自动化部署脚本

创建一个完整的部署脚本：

```bash
#!/bin/bash
# deploy-with-init.sh

set -e

echo "开始部署AI趋势发布系统..."

# 1. 创建数据目录
mkdir -p data/{mysql,redis,logs,uploads}

# 2. 启动数据库服务
echo "启动数据库服务..."
docker-compose up -d db redis

# 3. 等待数据库就绪
echo "等待数据库启动..."
sleep 30

# 4. 运行数据库初始化
echo "初始化数据库..."
docker-compose --profile init up drizzle-init

# 5. 启动应用服务
echo "启动应用服务..."
docker-compose up -d backend frontend

echo "部署完成！"
```

## 数据备份和恢复

### 自动备份脚本

<function_calls>
<invoke name="todo_write">
<parameter name="merge">true

