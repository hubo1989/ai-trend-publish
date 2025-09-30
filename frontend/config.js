// 前端配置文件
const CONFIG = {
    // 根据运行环境自动检测API地址
    getApiUrl: function() {
        // Docker环境：直接访问后端服务
        if (window.location.hostname === 'localhost' && window.location.port === '8080') {
            return 'http://127.0.0.1:8000/api/workflow';
        }
        
        // 开发环境：直接访问后端
        if (window.location.hostname === 'localhost' && window.location.port !== '8080') {
            return 'http://localhost:8000/api/workflow';
        }
        
        // 生产环境：直接访问后端
        return 'http://127.0.0.1:8000/api/workflow';
    },
    
    // 默认配置
    DEFAULT_API_KEY: '',
    
    // 调试模式
    DEBUG: window.location.hostname === 'localhost',
    
    // 其他配置
    APP_NAME: '数据源管理系统',
    VERSION: '1.0.0'
};

// 导出配置
window.CONFIG = CONFIG;

