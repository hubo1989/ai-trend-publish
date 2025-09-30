# GEMINI.md - AI-Trend-Publish 项目深度解析

## 项目概述

`ai-trend-publish` 是一个基于 Deno 和 TypeScript 构建的自动化趋势发现与内容发布系统。该系统能够从多个信息源（如 Twitter、RSS、网页等）抓取最新内容，利用大型语言模型（LLM）对信息进行智能分析、摘要、排序和再创作，最终将高质量的内容自动发布到指定平台（如微信公众号）。

该项目旨在解决在信息爆炸时代，如何高效地获取、筛选和发布高质量内容的问题，特别适合于内容创作者、媒体运营者和需要进行舆情监控的团队。

## 主要功能

*   **🤖 多源数据采集**:
    *   **社交媒体**: 支持抓取 Twitter/X 的热门内容。
    *   **网页抓取**: 集成 FireCrawl、Jina AI 等服务，可以深度抓取和解析网页内容。
    *   **RSS 订阅**: 支持通过 RSSHub 等服务订阅和获取更新。
    *   **可扩展性**: 系统设计支持轻松添加新的数据源。

*   **🧠 AI 智能处理**:
    *   **内容总结与润色**: 对接了多种大模型服务（如 Deepseek, 通义千问, 讯飞星火, Jina AI 等），能够自动生成文章摘要、提炼关键词、并对内容进行润色。
    *   **智能排序**: 内置了基于 AI 的内容排序模块（`ContentRanker`），可以根据内容的重要性、相关性等维度进行打分和排序，筛选出最有价值的信息。
    *   **内容去重**: 利用向量嵌入（Vector Embeddings）技术，计算内容的相似度，有效避免发布重复或高度相似的内容。
    *   **标题生成**: 能够根据文章核心内容，智能生成吸引人的标题。

*   **📢 自动化发布**:
    *   **微信公众号**: 核心功能之一是作为微信公众号的内容发布机器人，支持将处理好的内容排版并发布。
    *   **自定义模板**: 支持使用 EJS 模板引擎定制发布的文章样式，满足不同的品牌和排版需求。
    *   **定时任务**: 通过 `node-cron` 实现定时任务，可以设定在每天的固定时间自动执行完整的内容处理和发布流程。

*   **📱 实时通知**:
    *   集成了 Bark、钉钉、飞书等多种通知渠道。
    *   在任务开始、结束、成功或失败时，都能发送实时通知，方便用户掌握系统运行状态。

## 技术栈

*   **核心框架**: [Deno](https://deno.land/) (v2.0.0+) + TypeScript
*   **AI 服务**:
    *   **LLM**: DeepseekAI, Together AI, 阿里云通义千问, 腾讯混元, 讯飞星火
    *   **Embedding & Reranking**: Jina AI, DashScope
    *   **图像生成**: 阿里云通义万相
*   **数据处理**:
    *   **ORM**: Drizzle ORM
    *   **数据库**: MySQL
*   **网页抓取**: FireCrawl, Jina AI
*   **模板引擎**: EJS
*   **任务调度**: `npm:node-cron`

## 项目架构

项目采用模块化的分层架构，逻辑清晰，易于扩展。

1.  **入口 (`src/index.ts`)**:
    *   作为应用的起点，负责初始化配置管理器、启动定时任务调度器和启动 API 服务器。

2.  **控制器 (`src/controllers/`)**:
    *   **`cron.ts`**: 定义了所有定时任务。它根据设定的时间表达式（Cron Expression），在特定时间触发相应的工作流（Workflow）。例如，每天凌晨3点执行内容抓取和发布的任务。
    *   **`workflow.controller.ts`**: 提供了 JSON-RPC API 接口，允许用户通过 API 请求手动触发一个或多个工作流。

3.  **服务与工作流 (`src/services/`)**:
    *   这是项目的核心业务逻辑层。每个 `*.workflow.ts` 文件都定义了一个完整的工作流程，例如 `weixin-article.workflow.ts` 就详细编排了从数据抓取、去重、排序、AI处理、生成封面到最终发布的每一步。
    *   工作流的设计是原子化和可重试的，确保了流程的稳定性和可靠性。

4.  **功能模块 (`src/modules/`)**:
    *   将具体的功能实现封装成独立的模块，例如：
        *   `scrapers/`: 负责从不同数据源抓取内容。
        *   `summarizer/`: 负责调用 AI 服务进行内容总结。
        *   `content-rank/`: 负责对内容进行智能排序。
        *   `publishers/`: 负责将内容发布到不同平台。
        *   `notify/`: 负责发送通知。

5.  **服务提供者 (`src/providers/`)**:
    *   用于封装对第三方服务的调用，例如对不同厂商的 LLM、Embedding 模型、图像生成模型的 API 调用。工厂模式（Factory Pattern）的运用使得切换和添加新的服务提供商变得非常简单。

6.  **配置管理 (`src/utils/config/`)**:
    *   `ConfigManager` 负责从环境变量（`.env` 文件）和数据库中读取和管理应用的所有配置项，实现了配置的集中化管理。

## 快速开始

### 1. 环境准备

*   安装 [Deno](https://deno.land/) (v2.0.0 或更高版本)。

### 2. 安装与配置

1.  **克隆项目**:
    ```bash
    git clone https://github.com/OpenAISpace/ai-trend-publish.git
    cd ai-trend-publish
    ```

2.  **配置环境变量**:
    *   复制环境变量示例文件：
        ```bash
        cp .env.example .env
        ```
    *   编辑 `.env` 文件，填入必要的 API Keys 和配置信息。这是项目运行的关键，需要仔细填写，特别是各大 AI 平台的 `API_KEY`。

### 3. 运行与构建

*   **开发模式 (带热重载)**:
    ```bash
    deno task start
    ```

*   **运行测试**:
    ```bash
    deno task test
    ```

*   **构建可执行文件**:
    项目支持将应用编译为不同平台的独立可执行文件。
    ```bash
    # 构建 Windows 版本
    deno task build:win

    # 构建 macOS (Apple Silicon) 版本
    deno task build:mac-arm64
    ```

## 部署指南

### 方式一：服务器直接部署

1.  在服务器上安装 Deno。
2.  克隆项目并配置好 `.env` 文件。
3.  使用 `pm2` 等进程管理工具来运行和管理应用，以确保其在后台稳定运行：
    ```bash
    npm install -g pm2
    pm2 start --interpreter="deno" --interpreter-args="run --allow-all" src/index.ts --name ai-trend-publish
    ```

### 方式二：Docker 部署

1.  构建 Docker 镜像:
    ```bash
    docker build -t ai-trend-publish .
    ```
2.  运行 Docker 容器，并通过 `--env-file` 参数加载配置文件:
    ```bash
    docker run -d --env-file .env --name ai-trend-publish-container ai-trend-publish
    ```

## 开发者指南

### 如何贡献

欢迎对项目进行贡献！您可以：

*   修复 Bug。
*   添加新的数据源。
*   集成新的 AI 服务。
*   开发新的发布模板。
*   优化现有代码。

贡献流程请遵循标准的 `Fork -> Pull Request` 模式。

### 模板开发

若要为微信公众号文章创建新的排版模板：

1.  **了解数据结构**: 查看 `src/modules/render/interfaces/` 目录下的 TypeScript 类型定义，了解渲染模板时可以获取哪些数据。
2.  **开发 EJS 模板**: 在 `src/modules/render/templates/` 目录下创建或修改 `.ejs` 模板文件。
3.  **注册和测试**: 在对应的 `*.renderer.ts` 文件中注册新模板，并编写测试用例进行渲染测试。