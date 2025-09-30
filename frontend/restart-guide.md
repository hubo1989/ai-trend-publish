# 重启Docker服务指南

## 问题说明
修改了后端代码后，需要重启Docker容器以使更改生效。特别是CORS配置和字符编码修复。

## 重启步骤

### 1. 查看当前运行的容器
```bash
docker ps
```

### 2. 重启特定容器
```bash
# 方式1: 使用容器名称
docker restart <container_name>

# 方式2: 使用容器ID
docker restart <container_id>

# 方式3: 如果使用docker-compose
docker-compose restart
```

### 3. 检查容器状态
```bash
# 查看容器是否正常启动
docker ps

# 查看容器日志
docker logs <container_name>

# 实时查看日志
docker logs -f <container_name>
```

### 4. 验证服务
```bash
# 测试端口连通性
curl -I http://localhost:8000

# 测试OPTIONS请求
curl -X OPTIONS http://localhost:8000/api/workflow \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type, Authorization"
```

## 常见问题

### 容器启动失败
- 检查端口是否被占用
- 查看错误日志：`docker logs <container_name>`
- 确认Docker配置文件正确

### 端口访问问题
- 确认端口映射：`docker port <container_name>`
- 检查防火墙设置
- 验证服务监听地址（应该是0.0.0.0而不是127.0.0.1）

### CORS仍然失败
- 确认代码修改已保存
- 重新构建镜像：`docker build -t your-image .`
- 清除浏览器缓存

## 完整重启流程

```bash
# 1. 停止容器
docker stop <container_name>

# 2. 删除容器（如果需要重新构建）
docker rm <container_name>

# 3. 重新构建镜像（如果代码有更改）
docker build -t your-image .

# 4. 启动新容器
docker run -p 8000:8000 your-image

# 5. 验证服务
curl http://localhost:8000
```

## 使用docker-compose

```bash
# 重启服务
docker-compose restart

# 或者重新构建并启动
docker-compose down
docker-compose up --build -d
```

