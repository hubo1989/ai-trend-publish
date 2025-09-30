# 前端服务 Dockerfile
FROM nginx:alpine

# 缓存破坏参数
ARG CACHEBUST=1
RUN echo "Cache bust: $CACHEBUST"

# 安装基本工具（跳过curl以避免网络问题）
# RUN apk add --no-cache curl

# 创建应用目录
WORKDIR /usr/share/nginx/html

# 复制前端文件
COPY *.html ./
COPY *.css ./
COPY *.js ./
COPY *.md ./

# 创建 Nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80

# 健康检查（使用nginx状态）
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD test -f /usr/share/nginx/html/index.html || exit 1

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]

