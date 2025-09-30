# 后端API设计说明与CORS修复原因

## 原始API设计

### 1. 调用方式
后端API采用 **JSON-RPC 2.0** 协议设计：

```json
{
  "jsonrpc": "2.0",
  "method": "getDataSources",
  "params": {},
  "id": 1
}
```

### 2. 支持的调用场景
原始设计主要支持：

#### A. 服务端调用（同源）
- 后端内部模块调用
- 命令行工具调用
- 同域名下的应用调用

#### B. Docker容器内部调用
```bash
# 容器内部调用
curl -X POST http://localhost:8000/api/workflow \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-key" \
  -d '{"jsonrpc":"2.0","method":"getDataSources","params":{},"id":1}'
```

#### C. 测试脚本调用
项目中的 `scripts/test-data-sources-api.ts` 就是这种用法。

### 3. 原始设计的局限性

#### 缺少CORS支持的原因：
1. **设计初衷**: 主要用于服务端到服务端通信
2. **部署环境**: 预期在同一网络环境中使用
3. **安全考虑**: 避免跨域访问的安全风险

#### 不支持浏览器跨域调用：
- 浏览器的同源策略阻止跨域请求
- 没有OPTIONS预检请求处理
- 缺少必要的CORS头部

## 为什么需要修改后端代码

### 1. 浏览器安全限制

当前端运行在 `http://localhost:8080`，后端运行在 `http://localhost:8000` 时：
- **不同端口** = **跨域请求**
- 浏览器会发送OPTIONS预检请求
- 没有正确的CORS头部会被浏览器阻止

### 2. Docker网络隔离

```
┌─────────────────┐    ┌─────────────────┐
│   宿主机:8080   │    │  Docker:8000    │
│   (前端页面)     │───▶│   (后端API)     │
└─────────────────┘    └─────────────────┘
        跨域请求            需要CORS支持
```

### 3. 字符编码问题

原始代码中的中文错误消息：
```javascript
// 问题代码
message: "未授权的访问"  // 中文字符导致HTTP头部编码错误
```

在HTTP响应中会导致：
```
Failed to read the 'headers' property: String contains non ISO-8859-1 code point
```

## 修复内容详解

### 1. 添加CORS支持

#### A. OPTIONS预检处理
```javascript
if (req.method === "OPTIONS") {
  return new Response(null, {
    status: 200,
    headers: corsHeaders,
  });
}
```

#### B. CORS头部设置
```javascript
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Max-Age": "86400",
};
```

### 2. 字符编码修复

```javascript
// 修复前
message: "未授权的访问"

// 修复后  
message: "Unauthorized access"
```

### 3. 完整的跨域支持

现在支持：
- ✅ 浏览器跨域请求
- ✅ OPTIONS预检请求
- ✅ 复杂请求（带Authorization头）
- ✅ 错误响应也包含CORS头

## 替代方案分析

### 方案1: 反向代理（未采用）
```nginx
server {
    listen 8080;
    location /api/ {
        proxy_pass http://localhost:8000/;
    }
    location / {
        root /frontend;
    }
}
```
**缺点**: 需要额外配置，增加复杂性

### 方案2: 前端代理（未采用）
```javascript
// webpack.config.js
devServer: {
  proxy: {
    '/api': 'http://localhost:8000'
  }
}
```
**缺点**: 只适用于开发环境

### 方案3: 修改后端CORS（已采用）
**优点**: 
- 一次修改，永久解决
- 支持生产环境
- 不需要额外配置

## 兼容性说明

修改后的API：
- ✅ 保持完全向后兼容
- ✅ 原有调用方式仍然有效
- ✅ 新增浏览器跨域支持
- ✅ Docker环境正常工作

## 总结

原始API设计是合理的，主要用于：
1. 服务端内部调用
2. 命令行工具
3. 同网络环境使用

但要支持**浏览器前端跨域调用**，必须：
1. 添加CORS头部支持
2. 处理OPTIONS预检请求  
3. 修复字符编码问题

这就是为什么需要修改后端代码的根本原因。

