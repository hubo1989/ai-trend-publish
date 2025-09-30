# 镜像编译指南

本指南说明如何编译backend和frontend镜像，以便在生产环境中使用。

## 快速开始

### 使用自动化脚本编译

```bash
# 使用提供的编译脚本（推荐）
./scripts/build-images.sh

# 或者指定镜像标签
./scripts/build-images.sh v1.0.0

# 或者指定镜像仓库地址
./scripts/build-images.sh latest your-registry.com
```

### 手动编译步骤

#### 1. 编译Backend镜像

```bash
# 在项目根目录执行
cd /Users/hubo/mycode/ai-trend-publish

# 编译backend镜像
docker build -t ai-trend-backend:latest .

# 或者指定自定义标签
docker build -t ai-trend-backend:v1.0.0 .

# 或者指定完整的仓库地址
docker build -t your-registry.com/ai-trend-backend:latest .
```

#### 2. 编译Frontend镜像

```bash
# 进入frontend目录
cd /Users/hubo/mycode/ai-trend-publish/frontend

# 编译frontend镜像
docker build -t ai-trend-frontend:latest .

# 或者指定自定义标签
docker build -t ai-trend-frontend:v1.0.0 .

# 或者指定完整的仓库地址
docker build -t your-registry.com/ai-trend-frontend:latest .
```

#### 3. 验证镜像

```bash
# 查看编译的镜像
docker images | grep ai-trend

# 测试backend镜像
docker run --rm -p 8000:8000 ai-trend-backend:latest

# 测试frontend镜像
docker run --rm -p 8080:80 ai-trend-frontend:latest
```

## 镜像推送到仓库

### 推送到Docker Hub

```bash
# 登录Docker Hub
docker login

# 推送镜像
docker push your-username/ai-trend-backend:latest
docker push your-username/ai-trend-frontend:latest
```

### 推送到私有仓库

```bash
# 登录私有仓库
docker login your-registry.com

# 推送镜像
docker push your-registry.com/ai-trend-backend:latest
docker push your-registry.com/ai-trend-frontend:latest
```

## 优化编译过程

### 使用多阶段构建（Backend优化）

如果需要优化backend镜像大小，可以修改Dockerfile使用多阶段构建：

```dockerfile
# 构建阶段
FROM denoland/deno as builder
WORKDIR /app
COPY . .
RUN deno cache --reload src/index.ts

# 运行阶段
FROM denoland/deno:alpine
WORKDIR /app
COPY --from=builder /app .
CMD ["deno", "task", "start"]
```

### 使用.dockerignore

创建`.dockerignore`文件来排除不必要的文件：

```
node_modules
.git
.env
*.md
docs/
test/
*.test.ts
.vscode/
.idea/
```

## 版本管理

### 使用Git标签作为镜像标签

```bash
# 获取当前Git提交哈希
GIT_COMMIT=$(git rev-parse --short HEAD)

# 使用Git提交哈希作为标签
docker build -t ai-trend-backend:$GIT_COMMIT .
docker build -t ai-trend-frontend:$GIT_COMMIT ./frontend

# 同时打上latest标签
docker tag ai-trend-backend:$GIT_COMMIT ai-trend-backend:latest
docker tag ai-trend-frontend:$GIT_COMMIT ai-trend-frontend:latest
```

### 使用版本号标签

```bash
VERSION="v1.0.0"

# 编译带版本号的镜像
docker build -t ai-trend-backend:$VERSION .
docker build -t ai-trend-frontend:$VERSION ./frontend

# 推送版本化镜像
docker push your-registry.com/ai-trend-backend:$VERSION
docker push your-registry.com/ai-trend-frontend:$VERSION
```

## CI/CD集成

### GitHub Actions示例

```yaml
name: Build and Push Images

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to Registry
      uses: docker/login-action@v2
      with:
        registry: your-registry.com
        username: ${{ secrets.REGISTRY_USERNAME }}
        password: ${{ secrets.REGISTRY_PASSWORD }}
    
    - name: Build and push backend
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: your-registry.com/ai-trend-backend:latest
    
    - name: Build and push frontend
      uses: docker/build-push-action@v4
      with:
        context: ./frontend
        push: true
        tags: your-registry.com/ai-trend-frontend:latest
```

## 故障排除

### 常见问题

1. **编译失败 - 依赖问题**
   ```bash
   # 清理Docker缓存
   docker system prune -a
   
   # 重新编译
   docker build --no-cache -t ai-trend-backend:latest .
   ```

2. **镜像过大**
   ```bash
   # 查看镜像大小
   docker images ai-trend-backend
   
   # 分析镜像层
   docker history ai-trend-backend:latest
   ```

3. **推送失败**
   ```bash
   # 检查登录状态
   docker info
   
   # 重新登录
   docker logout
   docker login your-registry.com
   ```

### 调试镜像

```bash
# 运行镜像进行调试
docker run -it --rm ai-trend-backend:latest sh

# 查看镜像内容
docker run --rm ai-trend-backend:latest ls -la /app

# 查看镜像环境变量
docker run --rm ai-trend-backend:latest env
```

## 性能优化建议

1. **使用Alpine Linux基础镜像**减少镜像大小
2. **合并RUN指令**减少镜像层数
3. **使用.dockerignore**排除不必要文件
4. **多阶段构建**分离构建和运行环境
5. **缓存依赖**利用Docker层缓存机制

## 安全最佳实践

1. **不要在镜像中包含敏感信息**
2. **使用非root用户运行应用**
3. **定期更新基础镜像**
4. **扫描镜像漏洞**
5. **使用官方或可信的基础镜像**

---

完成镜像编译后，您就可以使用`docker-compose.production.yml`配置文件进行部署了。

