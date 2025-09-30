# Docker镜像重新构建指南

## 重要提醒
⚠️ **修改了源代码后，必须重新构建Docker镜像才能使更改生效！**

## 完整重建流程

### 步骤1: 停止并删除现有容器
```bash
# 查看运行中的容器
docker ps

# 停止容器
docker stop <container_name>

# 删除容器
docker rm <container_name>
```

### 步骤2: 重新构建镜像
```bash
# 进入项目目录
cd /Users/hubo/mycode/ai-trend-publish

# 重新构建镜像（注意替换为实际的镜像名称）
docker build -t ai-trend-publish .

# 或者如果有特定的标签
docker build -t your-image-name:latest .
```

### 步骤3: 启动新容器
```bash
# 启动新容器（确保端口映射正确）
docker run -d -p 8000:8000 \
  -e ENABLE_DB=true \
  -e SERVER_API_KEY=your-api-key \
  --name ai-trend-publish \
  ai-trend-publish

# 或者如果你有其他环境变量
docker run -d -p 8000:8000 \
  --env-file .env \
  --name ai-trend-publish \
  ai-trend-publish
```

### 步骤4: 验证新容器
```bash
# 检查容器状态
docker ps

# 查看启动日志
docker logs ai-trend-publish

# 测试连接
curl -I http://localhost:8000
```

## 使用docker-compose的情况

如果使用docker-compose，流程更简单：

```bash
# 停止服务
docker-compose down

# 重新构建并启动
docker-compose up --build -d

# 查看日志
docker-compose logs -f
```

## 验证修复

重新构建后，使用CORS测试工具验证：

1. 打开 `cors-test.html`
2. 测试OPTIONS请求 - 应该成功
3. 测试API请求 - 不应该再有字符编码错误
4. 应该能收到正确的401认证错误（说明CORS工作）

## 常见问题

### 构建失败
- 检查Dockerfile是否正确
- 确认所有依赖文件存在
- 查看构建日志中的错误信息

### 容器启动失败
- 检查环境变量是否正确设置
- 确认端口8000未被其他进程占用
- 查看容器日志：`docker logs <container_name>`

### 仍有CORS问题
- 确认镜像重新构建成功
- 验证容器使用的是新镜像
- 清除浏览器缓存

## 快速命令总结

```bash
# 一键重建流程
docker stop <container_name> && \
docker rm <container_name> && \
docker build -t ai-trend-publish . && \
docker run -d -p 8000:8000 \
  -e ENABLE_DB=true \
  -e SERVER_API_KEY=your-api-key \
  --name ai-trend-publish \
  ai-trend-publish && \
docker logs ai-trend-publish
```

记得替换 `<container_name>` 和 `your-api-key` 为实际值！

