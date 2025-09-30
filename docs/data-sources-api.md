# 数据源管理 API 文档

## 概述

本文档介绍如何通过 JSON-RPC API 在数据库中管理数据源。所有API都使用JSON-RPC 2.0协议，需要Bearer Token认证。

## 认证方式

所有API请求都需要在请求头中添加Authorization字段：

```
Authorization: Bearer your-api-key
```

API密钥通过环境变量 `SERVER_API_KEY` 配置。

## 前置条件

确保在环境变量中设置：
```bash
ENABLE_DB=true  # 启用数据库功能
SERVER_API_KEY=your-api-key  # API认证密钥
```

## API 方法列表

### 1. 获取所有数据源 (getDataSources)

获取数据库中的所有数据源。

**请求示例：**
```bash
curl -X POST http://localhost:8000/api/workflow \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "getDataSources",
    "params": {},
    "id": 1
  }'
```

**响应示例：**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "success": true,
    "data": [
      {
        "id": 1,
        "platform": "firecrawl",
        "identifier": "https://example.com"
      },
      {
        "id": 2,
        "platform": "twitter",
        "identifier": "@username"
      }
    ],
    "count": 2
  },
  "id": 1
}
```

### 2. 创建数据源 (createDataSource)

在数据库中创建新的数据源。

**请求参数：**
- `platform` (string, 必需): 平台类型，支持 "firecrawl" 或 "twitter"
- `identifier` (string, 必需): 数据源标识符

**请求示例：**
```bash
curl -X POST http://localhost:8000/api/workflow \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "createDataSource",
    "params": {
      "platform": "firecrawl",
      "identifier": "https://techcrunch.com"
    },
    "id": 1
  }'
```

**响应示例：**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "success": true,
    "data": {
      "id": 3,
      "platform": "firecrawl",
      "identifier": "https://techcrunch.com"
    },
    "message": "数据源创建成功"
  },
  "id": 1
}
```

### 3. 更新数据源 (updateDataSource)

更新现有数据源的信息。

**请求参数：**
- `id` (number, 必需): 数据源ID
- `platform` (string, 必需): 新的平台类型
- `identifier` (string, 必需): 新的标识符

**请求示例：**
```bash
curl -X POST http://localhost:8000/api/workflow \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "updateDataSource",
    "params": {
      "id": 3,
      "platform": "firecrawl",
      "identifier": "https://venturebeat.com"
    },
    "id": 1
  }'
```

**响应示例：**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "success": true,
    "data": {
      "id": 3,
      "platform": "firecrawl",
      "identifier": "https://venturebeat.com"
    },
    "message": "数据源更新成功"
  },
  "id": 1
}
```

### 4. 删除数据源 (deleteDataSource)

从数据库中删除指定的数据源。

**请求参数：**
- `id` (number, 必需): 要删除的数据源ID

**请求示例：**
```bash
curl -X POST http://localhost:8000/api/workflow \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "deleteDataSource",
    "params": {
      "id": 3
    },
    "id": 1
  }'
```

**响应示例：**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "success": true,
    "message": "数据源删除成功"
  },
  "id": 1
}
```

### 5. 批量创建数据源 (batchCreateDataSources)

一次性创建多个数据源。

**请求参数：**
- `dataSources` (array, 必需): 数据源数组，每个元素包含 platform 和 identifier

**请求示例：**
```bash
curl -X POST http://localhost:8000/api/workflow \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "batchCreateDataSources",
    "params": {
      "dataSources": [
        {
          "platform": "firecrawl",
          "identifier": "https://techcrunch.com"
        },
        {
          "platform": "twitter",
          "identifier": "@elonmusk"
        },
        {
          "platform": "firecrawl",
          "identifier": "https://venturebeat.com"
        }
      ]
    },
    "id": 1
  }'
```

**响应示例：**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "success": true,
    "data": [
      {
        "success": true,
        "id": 4,
        "platform": "firecrawl",
        "identifier": "https://techcrunch.com"
      },
      {
        "success": true,
        "id": 5,
        "platform": "twitter",
        "identifier": "@elonmusk"
      },
      {
        "success": false,
        "error": "已存在",
        "platform": "firecrawl",
        "identifier": "https://venturebeat.com"
      }
    ],
    "summary": {
      "total": 3,
      "success": 2,
      "failed": 1
    },
    "message": "批量创建完成: 2/3 成功"
  },
  "id": 1
}
```

## 支持的平台类型

目前支持以下平台类型：

| 平台 | 说明 | 标识符示例 |
|------|------|-----------|
| `firecrawl` | 网页爬取平台 | `https://example.com` |
| `twitter` | Twitter平台 | `@username` |

## 错误处理

### 常见错误代码

| 错误代码 | 说明 | 解决方案 |
|---------|------|---------|
| -32001 | 未授权的访问 | 检查 Authorization 请求头 |
| -32600 | 无效的请求 | 检查JSON-RPC格式 |
| -32601 | 方法不存在 | 确认方法名是否正确 |
| -32602 | 无效的参数 | 检查参数格式和必填字段 |
| -32603 | 内部错误 | 查看服务器日志 |

### 业务错误示例

**数据库未启用：**
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32603,
    "message": "数据库未启用，请设置 ENABLE_DB=true 以启用数据库功能"
  },
  "id": 1
}
```

**数据源已存在：**
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32603,
    "message": "平台 firecrawl 上的标识符 https://example.com 已存在"
  },
  "id": 1
}
```

**无效的平台类型：**
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32603,
    "message": "platform 必须是以下值之一: firecrawl, twitter"
  },
  "id": 1
}
```

## 直接SQL操作（可选）

如果你有数据库访问权限，也可以直接通过SQL操作数据源：

### 插入数据源
```sql
INSERT INTO data_sources (platform, identifier) VALUES 
('firecrawl', 'https://techcrunch.com'),
('twitter', '@elonmusk');
```

### 查询数据源
```sql
SELECT * FROM data_sources;
```

### 更新数据源
```sql
UPDATE data_sources 
SET identifier = 'https://venturebeat.com' 
WHERE id = 1;
```

### 删除数据源
```sql
DELETE FROM data_sources WHERE id = 1;
```

## 注意事项

1. **数据库启用**：确保设置 `ENABLE_DB=true`，否则所有数据源API都会返回错误
2. **唯一性约束**：相同平台和标识符的组合不能重复
3. **数据验证**：platform 和 identifier 字段都是必需的，且不能为空
4. **平台限制**：目前只支持 "firecrawl" 和 "twitter" 两种平台类型
5. **认证要求**：所有API调用都需要有效的Bearer Token

## 完整示例脚本

以下是一个完整的示例脚本，展示如何使用所有数据源API：

```bash
#!/bin/bash

API_KEY="your-api-key"
BASE_URL="http://localhost:8000/api/workflow"

# 1. 获取所有数据源
echo "=== 获取所有数据源 ==="
curl -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "method": "getDataSources",
    "params": {},
    "id": 1
  }' | jq

# 2. 创建单个数据源
echo -e "\n=== 创建数据源 ==="
curl -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "method": "createDataSource",
    "params": {
      "platform": "firecrawl",
      "identifier": "https://techcrunch.com"
    },
    "id": 2
  }' | jq

# 3. 批量创建数据源
echo -e "\n=== 批量创建数据源 ==="
curl -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "method": "batchCreateDataSources",
    "params": {
      "dataSources": [
        {
          "platform": "twitter",
          "identifier": "@elonmusk"
        },
        {
          "platform": "firecrawl",
          "identifier": "https://venturebeat.com"
        }
      ]
    },
    "id": 3
  }' | jq

# 4. 更新数据源
echo -e "\n=== 更新数据源 ==="
curl -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "method": "updateDataSource",
    "params": {
      "id": 1,
      "platform": "firecrawl",
      "identifier": "https://updated-url.com"
    },
    "id": 4
  }' | jq

# 5. 删除数据源
echo -e "\n=== 删除数据源 ==="
curl -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "method": "deleteDataSource",
    "params": {
      "id": 1
    },
    "id": 5
  }' | jq
```

使用前请将 `your-api-key` 替换为实际的API密钥。