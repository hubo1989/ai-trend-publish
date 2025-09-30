# Docker网络连接问题解决指南

## 问题描述

当后端服务运行在Docker容器中，而前端运行在宿主机上时，可能会遇到网络连接问题。

## 解决方案

### 1. 检查Docker容器状态

```bash
# 查看运行中的容器
docker ps

# 查看容器详细信息
docker inspect <container_name>

# 查看容器日志
docker logs <container_name>
```

### 2. 端口映射解决方案

确保Docker容器正确映射端口：

```bash
# 启动容器时映射端口
docker run -p 8000:8000 your-image

# 或者使用docker-compose
version: '3'
services:
  backend:
    build: .
    ports:
      - "8000:8000"
```

### 3. 网络地址测试

按优先级测试以下地址：

1. **http://localhost:8000** - 如果有端口映射
2. **http://127.0.0.1:8000** - 本地回环地址
3. **http://host.docker.internal:8000** - Docker Desktop专用
4. **http://172.17.0.1:8000** - Docker默认网关
5. **http://0.0.0.0:8000** - 绑定所有接口

### 4. Docker网络模式

#### Host网络模式（推荐用于开发）
```bash
docker run --network=host your-image
```

#### Bridge网络模式（默认）
```bash
docker run -p 8000:8000 your-image
```

### 5. 检查防火墙设置

确保防火墙允许端口8000的连接：

```bash
# macOS
sudo pfctl -d  # 临时禁用防火墙测试

# Linux
sudo ufw allow 8000
```

### 6. 容器内部测试

进入容器测试内部连接：

```bash
# 进入容器
docker exec -it <container_name> /bin/bash

# 测试内部连接
curl http://localhost:8000/api/workflow
```

### 7. Docker Compose配置示例

```yaml
version: '3.8'
services:
  backend:
    build: .
    ports:
      - "8000:8000"
    environment:
      - ENABLE_DB=true
      - SERVER_API_KEY=your-api-key
    networks:
      - app-network

  frontend:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./frontend:/usr/share/nginx/html
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

### 8. 常见错误及解决方案

#### CORS错误
- 确保后端设置了正确的CORS头
- 检查`Access-Control-Allow-Origin`是否包含前端域名

#### 连接被拒绝
- 检查容器是否正在运行
- 确认端口映射是否正确
- 验证服务是否监听正确的地址（0.0.0.0而不是127.0.0.1）

#### 超时错误
- 检查网络连接
- 增加超时时间
- 确认服务响应正常

### 9. 调试工具

使用提供的网络诊断工具：
1. 打开 `network-test.html`
2. 测试各种可能的连接地址
3. 检查CORS配置
4. 验证API接口

### 10. 最佳实践

1. **开发环境**: 使用`--network=host`模式简化网络配置
2. **生产环境**: 使用明确的端口映射和网络配置
3. **监控**: 定期检查容器健康状态
4. **日志**: 启用详细的网络和应用日志

## 快速解决方案

如果急需解决问题，按以下顺序尝试：

1. 重启Docker容器
2. 检查端口映射：`docker port <container_name>`
3. 尝试不同的地址：localhost、127.0.0.1、host.docker.internal
4. 使用网络诊断工具测试连接
5. 查看容器日志排查问题

