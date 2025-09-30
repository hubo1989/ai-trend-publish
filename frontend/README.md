# 数据源管理前端系统

这是一个用于管理AI趋势发布系统中数据源的前端界面，提供了完整的CRUD功能来管理数据库中的数据源。

## 功能特性

- 🔍 **查看数据源**: 以表格形式展示所有数据源，支持实时刷新
- ➕ **添加数据源**: 支持单个和批量添加数据源
- ✏️ **编辑数据源**: 修改现有数据源的平台类型和标识符
- 🗑️ **删除数据源**: 安全删除数据源，带确认提示
- 📊 **统计信息**: 实时显示数据源数量统计
- 🔧 **配置管理**: 支持API地址和密钥配置
- 📱 **响应式设计**: 支持桌面和移动设备

## 支持的平台

- **Firecrawl**: 网页爬取平台，标识符为完整URL
- **Twitter**: Twitter平台，标识符为用户名（包含@符号）

## 快速开始

### 1. 启动后端服务

确保AI趋势发布系统的后端服务正在运行：

```bash
cd /Users/hubo/mycode/ai-trend-publish
npm run dev  # 或者您使用的启动命令
```

后端服务默认运行在 `http://localhost:8000`

### 2. 配置环境变量

确保后端服务配置了以下环境变量：

```bash
ENABLE_DB=true                    # 启用数据库功能
SERVER_API_KEY=your-api-key      # API认证密钥
```

### 3. 启动前端服务

由于这是一个纯静态前端应用，您可以通过以下几种方式启动：

#### 方式一：使用Python内置服务器
```bash
cd frontend
python3 -m http.server 8080
```

#### 方式二：使用Node.js serve
```bash
cd frontend
npx serve -p 8080
```

#### 方式三：使用任何Web服务器
将frontend目录配置为Web服务器的根目录即可。

### 4. 访问应用

在浏览器中打开：`http://localhost:8080`

### 5. 配置API连接

1. 在页面顶部的"API配置"面板中：
   - **API地址**: 输入后端服务地址（默认：`http://localhost:8000/api/workflow`）
   - **API密钥**: 输入您在环境变量中设置的`SERVER_API_KEY`值

2. 点击"测试连接"按钮验证配置是否正确

3. 配置成功后，点击"刷新数据"加载现有数据源

## 使用说明

### 查看数据源
- 页面加载后会自动显示所有数据源
- 点击"刷新数据"按钮可以重新加载最新数据
- 统计面板显示总数量和各平台数量

### 添加单个数据源
1. 点击"添加数据源"按钮
2. 选择平台类型（Firecrawl或Twitter）
3. 输入标识符：
   - Firecrawl: 完整的网页URL，如 `https://techcrunch.com`
   - Twitter: 用户名，如 `@elonmusk`
4. 点击"保存"

### 批量添加数据源
1. 点击"批量添加"按钮
2. 在文本框中按格式输入数据源，每行一个：
   ```
   firecrawl,https://techcrunch.com
   twitter,@elonmusk
   firecrawl,https://venturebeat.com
   ```
3. 点击"批量添加"

### 编辑数据源
1. 在数据源列表中找到要编辑的项
2. 点击"编辑"按钮
3. 修改平台类型或标识符
4. 点击"保存"

### 删除数据源
1. 在数据源列表中找到要删除的项
2. 点击"删除"按钮
3. 在确认对话框中点击"确认删除"

## 技术架构

### 前端技术栈
- **HTML5**: 语义化标记
- **CSS3**: 现代化样式，支持响应式设计
- **Vanilla JavaScript**: 原生JavaScript，无框架依赖
- **JSON-RPC 2.0**: 与后端API通信协议

### 核心组件
- `DataSourceManager`: 主要的应用管理类
- API客户端: 处理与后端的JSON-RPC通信
- UI组件: 模态框、表格、表单等交互组件
- 消息系统: 用户反馈和错误处理

### 数据流
1. 用户操作 → JavaScript事件处理
2. 事件处理 → JSON-RPC API调用
3. API响应 → 数据更新和UI刷新
4. 错误处理 → 用户友好的错误提示

## 文件结构

```
frontend/
├── index.html          # 主页面
├── styles.css          # 样式文件
├── app.js             # 应用逻辑
└── README.md          # 说明文档
```

## API接口

本前端应用调用以下JSON-RPC接口：

- `getDataSources`: 获取所有数据源
- `createDataSource`: 创建单个数据源
- `updateDataSource`: 更新数据源
- `deleteDataSource`: 删除数据源
- `batchCreateDataSources`: 批量创建数据源

详细的API文档请参考：`docs/data-sources-api.md`

## 浏览器兼容性

- Chrome 60+
- Firefox 55+
- Safari 12+
- Edge 79+

## 故障排除

### 连接测试失败
1. 检查后端服务是否正在运行
2. 确认API地址是否正确
3. 验证API密钥是否匹配
4. 检查网络连接和CORS设置

### 数据加载失败
1. 确认数据库功能已启用（`ENABLE_DB=true`）
2. 检查数据库连接配置
3. 查看后端服务日志

### 操作失败
1. 检查输入数据格式是否正确
2. 确认数据源是否已存在（创建时）
3. 验证数据源ID是否有效（更新/删除时）

## 开发说明

### 本地开发
1. 修改代码后直接刷新浏览器即可看到效果
2. 使用浏览器开发者工具调试JavaScript
3. 检查网络面板查看API请求和响应

### 自定义配置
- 修改`app.js`中的默认API地址
- 调整`styles.css`中的主题颜色
- 在`index.html`中添加新的UI组件

## 安全注意事项

- API密钥会保存在浏览器本地存储中，请确保在安全环境下使用
- 生产环境中应配置HTTPS
- 建议定期更换API密钥

## 许可证

本项目遵循与主项目相同的许可证。
