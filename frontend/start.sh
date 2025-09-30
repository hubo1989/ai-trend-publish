#!/bin/bash

# 数据源管理前端启动脚本

echo "🚀 启动数据源管理前端服务..."

# 检查端口是否被占用
PORT=8080
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  端口 $PORT 已被占用，尝试使用端口 8081..."
    PORT=8081
fi

# 检查Python是否可用
if command -v python3 &> /dev/null; then
    echo "📦 使用 Python3 启动服务..."
    echo "🌐 前端服务将在 http://localhost:$PORT 启动"
    echo "📋 请确保后端服务运行在 http://localhost:8000"
    echo ""
    echo "💡 配置提示："
    echo "   1. 在浏览器中打开 http://localhost:$PORT"
    echo "   2. 在API配置面板中输入您的API密钥"
    echo "   3. 点击'测试连接'验证配置"
    echo "   4. 开始管理您的数据源！"
    echo ""
    echo "按 Ctrl+C 停止服务"
    echo "----------------------------------------"
    
    cd "$(dirname "$0")"
    python3 -m http.server $PORT
    
elif command -v python &> /dev/null; then
    echo "📦 使用 Python 启动服务..."
    echo "🌐 前端服务将在 http://localhost:$PORT 启动"
    echo "📋 请确保后端服务运行在 http://localhost:8000"
    echo ""
    echo "💡 配置提示："
    echo "   1. 在浏览器中打开 http://localhost:$PORT"
    echo "   2. 在API配置面板中输入您的API密钥"
    echo "   3. 点击'测试连接'验证配置"
    echo "   4. 开始管理您的数据源！"
    echo ""
    echo "按 Ctrl+C 停止服务"
    echo "----------------------------------------"
    
    cd "$(dirname "$0")"
    python -m SimpleHTTPServer $PORT
    
elif command -v node &> /dev/null; then
    echo "📦 使用 Node.js serve 启动服务..."
    
    # 检查是否安装了serve
    if ! command -v serve &> /dev/null; then
        echo "📥 安装 serve 包..."
        npm install -g serve
    fi
    
    echo "🌐 前端服务将在 http://localhost:$PORT 启动"
    echo "📋 请确保后端服务运行在 http://localhost:8000"
    echo ""
    echo "💡 配置提示："
    echo "   1. 在浏览器中打开 http://localhost:$PORT"
    echo "   2. 在API配置面板中输入您的API密钥"
    echo "   3. 点击'测试连接'验证配置"
    echo "   4. 开始管理您的数据源！"
    echo ""
    echo "按 Ctrl+C 停止服务"
    echo "----------------------------------------"
    
    cd "$(dirname "$0")"
    serve -p $PORT
    
else
    echo "❌ 错误: 未找到 Python 或 Node.js"
    echo ""
    echo "请安装以下任一工具："
    echo "  - Python 3: https://www.python.org/downloads/"
    echo "  - Node.js: https://nodejs.org/"
    echo ""
    echo "或者手动将 frontend 目录配置到您的Web服务器中"
    exit 1
fi
