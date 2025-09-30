import { triggerWorkflow } from "./controllers/workflow.controller.ts";
import { WorkflowType } from "./controllers/cron.ts";
import { ConfigManager } from "@src/utils/config/config-manager.ts";
import { 
  getDataSources, 
  createDataSource, 
  updateDataSource, 
  deleteDataSource, 
  batchCreateDataSources 
} from "./api/data-sources.api.ts";


export interface JSONRPCRequest {
  jsonrpc: string;
  method: string;
  params: Record<string, any>;
  id: string | number;
}

export interface JSONRPCResponse {
  jsonrpc: string;
  result?: any;
  error?: {
    code: number;
    message: string;
    data?: any;
  };
  id: string | number;
}

export class JSONRPCServer {
  private routes: Record<string, (params: Record<string, any>) => Promise<any>>;

  constructor() {
    this.routes = {};
  }


  registerRoute(method: string, handler: (params: Record<string, any>) => Promise<any>) {
    this.routes[method] = handler;
  }

  async handleRequest(request: Request): Promise<Response> {
    try {
      if (request.method !== "POST") {
        throw new Error("Only POST requests are supported");
      }

      const body = await request.json() as JSONRPCRequest;

      if (!body.jsonrpc || body.jsonrpc !== "2.0") {
        throw new Error("Invalid JSON-RPC request");
      }

      if (!body.method) {
        throw new Error("Missing method name");
      }

      const handler = this.routes[body.method];
      if (!handler) {
        throw new Error(`Method ${body.method} not found`);
      }

      const result = await handler(body.params || {});
      
      return new Response(
        JSON.stringify({
          jsonrpc: "2.0",
          result,
          id: body.id,
        }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization",
          },
        }
      );
    } catch (error) {
      const isClientError = error instanceof Error && (
        error.message.includes("Invalid") ||
        error.message.includes("not found") ||
        error.message.includes("Missing")
      );

      return new Response(
        JSON.stringify({
          jsonrpc: "2.0",
          error: {
            code: isClientError ? -32600 : -32603,
            message: isClientError ? error.message : "Internal server error",
            data: {
              error: error instanceof Error ? error.message : String(error),
            },
          },
          id: "unknown",
        }),
        {
          status: isClientError ? 400 : 500,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization",
          },
        }
      );
    }
  }
}

// 创建 JSON-RPC 服务器实例
const rpcServer = new JSONRPCServer();
rpcServer.registerRoute("triggerWorkflow", triggerWorkflow);
rpcServer.registerRoute("getDataSources", getDataSources);
rpcServer.registerRoute("createDataSource", createDataSource);
rpcServer.registerRoute("updateDataSource", updateDataSource);
rpcServer.registerRoute("deleteDataSource", deleteDataSource);
rpcServer.registerRoute("batchCreateDataSources", batchCreateDataSources);

// CORS 头部设置
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Max-Age": "86400",
};

// 请求处理器
const handler = async (req: Request): Promise<Response> => {
  // 处理 OPTIONS 预检请求
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    // 验证 Authorization 请求头
    const configManager = ConfigManager.getInstance();
    const API_KEY = await configManager.get("SERVER_API_KEY");

    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ") || authHeader.split(" ")[1] !==  API_KEY) {
      return new Response(
        JSON.stringify({
          jsonrpc: "2.0",
          error: {
            code: -32001,
            message: "Unauthorized access",
            data: {
              error: "Missing valid Authorization header"
            }
          },
        }),
        {
          status: 401,
          headers: {
            "Content-Type": "application/json",
            ...corsHeaders,
          }
        }
      );
    }

    const url = new URL(req.url);
    
    // 规范化路径（移除开头和结尾的斜杠，处理可能的错误格式）
    const normalizedPath = url.pathname.replace(/^\/+|\/+$/g, "");
    
    // 只处理 api/workflow 路径的请求
    if (normalizedPath === "api/workflow") {
      return await rpcServer.handleRequest(req);
    }

    // 处理其他请求
    return new Response(
      JSON.stringify({
        jsonrpc: "2.0",
        error: {
          code: -32601,
          message: "Invalid API path",
          data: {
            path: normalizedPath,
            expectedPath: "api/workflow"
          }
        },
      }),
      {
        status: 404,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders,
        }
      }
    );
  } catch (error) {
    console.error("请求处理错误:", error);
    return new Response(
      JSON.stringify({
        jsonrpc: "2.0",
        error: {
          code: -32603,
          message: "Internal server error",
          data: {
            error: error instanceof Error ? error.message : String(error)
          }
        },
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders,
        }
      }
    );
  }
};

export default function startServer(port = 8000) {
  Deno.serve({ port }, handler);
  console.log(`JSON-RPC 服务器运行在 http://localhost:${port}`);
  console.log("支持的方法:");
  console.log("- triggerWorkflow");
  console.log("- getDataSources");
  console.log("- createDataSource");
  console.log("- updateDataSource");
  console.log("- deleteDataSource");
  console.log("- batchCreateDataSources");
  console.log(`可用的工作流类型: ${Object.values(WorkflowType).join(", ")}`);
}
