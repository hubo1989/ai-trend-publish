#!/usr/bin/env -S deno run --allow-net --allow-env

/**
 * 数据源API测试脚本
 * 
 * 使用方法：
 * 1. 确保服务器正在运行
 * 2. 设置环境变量 SERVER_API_KEY
 * 3. 运行: deno run --allow-net --allow-env scripts/test-data-sources-api.ts
 */

// 声明全局类型
declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
  args: string[];
  exit(code: number): never;
};

interface JsonRpcRequest {
  jsonrpc: string;
  method: string;
  params: any;
  id: number;
}

interface JsonRpcResponse {
  jsonrpc: string;
  result?: any;
  error?: {
    code: number;
    message: string;
  };
  id: number;
}

class DataSourceApiTester {
  private baseUrl: string;
  private apiKey: string;

  constructor(baseUrl: string = "http://localhost:8000", apiKey?: string) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey || Deno.env.get("SERVER_API_KEY") || "";
    
    if (!this.apiKey) {
      console.error("❌ 错误: 请设置 SERVER_API_KEY 环境变量");
      Deno.exit(1);
    }
  }

  private async makeRequest(method: string, params: any = {}): Promise<JsonRpcResponse> {
    const request: JsonRpcRequest = {
      jsonrpc: "2.0",
      method,
      params,
      id: Date.now()
    };

    try {
      const response = await fetch(`${this.baseUrl}/api/workflow`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${this.apiKey}`
        },
        body: JSON.stringify(request)
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error(`❌ 请求失败:`, error.message);
      throw error;
    }
  }

  private logResponse(title: string, response: JsonRpcResponse) {
    console.log(`\n📋 ${title}`);
    console.log("=" .repeat(50));
    
    if (response.error) {
      console.log(`❌ 错误: ${response.error.message}`);
      console.log(`   代码: ${response.error.code}`);
    } else {
      console.log("✅ 成功");
      console.log(JSON.stringify(response.result, null, 2));
    }
  }

  async testGetDataSources() {
    const response = await this.makeRequest("getDataSources");
    this.logResponse("获取所有数据源", response);
    return response;
  }

  async testCreateDataSource(platform: string, identifier: string) {
    const response = await this.makeRequest("createDataSource", {
      platform,
      identifier
    });
    this.logResponse(`创建数据源: ${platform} - ${identifier}`, response);
    return response;
  }

  async testBatchCreateDataSources(dataSources: Array<{platform: string, identifier: string}>) {
    const response = await this.makeRequest("batchCreateDataSources", {
      dataSources
    });
    this.logResponse("批量创建数据源", response);
    return response;
  }

  async runQuickTest() {
    console.log("🚀 开始数据源API快速测试");
    console.log(`📡 服务器地址: ${this.baseUrl}`);
    console.log(`🔑 API密钥: ${this.apiKey.substring(0, 8)}...`);

    try {
      // 1. 获取数据源列表
      await this.testGetDataSources();

      // 2. 创建测试数据源
      await this.testCreateDataSource("firecrawl", "https://test-example.com");

      // 3. 批量创建数据源
      await this.testBatchCreateDataSources([
        { platform: "twitter", identifier: "@test_user" },
        { platform: "firecrawl", identifier: "https://batch-test.com" }
      ]);

      // 4. 再次获取数据源列表
      await this.testGetDataSources();

      console.log("\n🎉 快速测试完成!");

    } catch (error) {
      console.error("\n💥 测试过程中发生错误:", error.message);
    }
  }
}

// 主函数
async function main() {
  const args = Deno.args;
  
  // 过滤出非选项参数作为baseUrl
  const nonOptionArgs = args.filter(arg => !arg.startsWith("--"));
  const baseUrl = nonOptionArgs[0] || "http://localhost:8000";
  
  console.log("🔧 数据源API测试工具");
  console.log("=" .repeat(50));

  const tester = new DataSourceApiTester(baseUrl);

  if (args.includes("--get-only")) {
    await tester.testGetDataSources();
  } else {
    await tester.runQuickTest();
  }
}

// 运行主函数
main().catch(console.error);

export { DataSourceApiTester };