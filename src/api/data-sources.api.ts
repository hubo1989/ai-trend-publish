import { ConfigManager } from "@src/utils/config/config-manager.ts";
import db from "@src/db/db.ts";
import { dataSources } from "@src/db/schema.ts";
import { eq } from "drizzle-orm";
import { Logger } from "@zilla/logger";

const log = new Logger("DataSourcesAPI");

// 数据验证函数
function validateDataSource(data: any): { platform: string; identifier: string } {
  if (!data.platform || typeof data.platform !== 'string') {
    throw new Error('platform 字段是必需的，且必须是字符串');
  }
  
  if (!data.identifier || typeof data.identifier !== 'string') {
    throw new Error('identifier 字段是必需的，且必须是字符串');
  }
  
  // 验证平台类型
  const validPlatforms = ['firecrawl', 'twitter'];
  if (!validPlatforms.includes(data.platform)) {
    throw new Error(`platform 必须是以下值之一: ${validPlatforms.join(', ')}`);
  }
  
  return {
    platform: data.platform.trim(),
    identifier: data.identifier.trim()
  };
}

// 检查数据库是否启用
async function checkDatabaseEnabled(): Promise<void> {
  const configManager = ConfigManager.getInstance();
  const enableDb = await configManager.get("ENABLE_DB");
  
  if (!enableDb) {
    throw new Error("数据库未启用，请设置 ENABLE_DB=true 以启用数据库功能");
  }
}

// 获取所有数据源
export async function getDataSources(params: Record<string, any>): Promise<any> {
  try {
    log.info("获取所有数据源");
    
    await checkDatabaseEnabled();
    
    const sources = await db.select().from(dataSources);
    
    log.info(`成功获取 ${sources.length} 个数据源`);
    
    return {
      success: true,
      data: sources,
      count: sources.length
    };
  } catch (error) {
    log.error("获取数据源失败:", error);
    throw new Error(error instanceof Error ? error.message : String(error));
  }
}

// 创建新数据源
export async function createDataSource(params: Record<string, any>): Promise<any> {
  try {
    log.info("创建新数据源:", params);
    
    await checkDatabaseEnabled();
    
    const validatedData = validateDataSource(params);
    
    // 检查是否已存在相同的数据源
    const existing = await db.select()
      .from(dataSources)
      .where(eq(dataSources.platform, validatedData.platform))
      .where(eq(dataSources.identifier, validatedData.identifier));
    
    if (existing.length > 0) {
      throw new Error(`平台 ${validatedData.platform} 上的标识符 ${validatedData.identifier} 已存在`);
    }
    
    const result = await db.insert(dataSources).values(validatedData);
    
    log.info("数据源创建成功:", { id: result.insertId, ...validatedData });
    
    return {
      success: true,
      data: {
        id: result.insertId,
        ...validatedData
      },
      message: "数据源创建成功"
    };
  } catch (error) {
    log.error("创建数据源失败:", error);
    throw new Error(error instanceof Error ? error.message : String(error));
  }
}

// 更新数据源
export async function updateDataSource(params: Record<string, any>): Promise<any> {
  try {
    const { id, ...updateData } = params;
    
    log.info(`更新数据源 ID ${id}:`, updateData);
    
    if (!id || isNaN(parseInt(id))) {
      throw new Error("ID 必须是有效的数字");
    }
    
    const numericId = parseInt(id);
    
    await checkDatabaseEnabled();
    
    const validatedData = validateDataSource(updateData);
    
    // 检查数据源是否存在
    const existing = await db.select()
      .from(dataSources)
      .where(eq(dataSources.id, numericId));
    
    if (existing.length === 0) {
      throw new Error(`ID 为 ${numericId} 的数据源不存在`);
    }
    
    await db.update(dataSources)
      .set(validatedData)
      .where(eq(dataSources.id, numericId));
    
    log.info("数据源更新成功:", { id: numericId, ...validatedData });
    
    return {
      success: true,
      data: {
        id: numericId,
        ...validatedData
      },
      message: "数据源更新成功"
    };
  } catch (error) {
    log.error("更新数据源失败:", error);
    throw new Error(error instanceof Error ? error.message : String(error));
  }
}

// 删除数据源
export async function deleteDataSource(params: Record<string, any>): Promise<any> {
  try {
    const { id } = params;
    
    log.info(`删除数据源 ID ${id}`);
    
    if (!id || isNaN(parseInt(id))) {
      throw new Error("ID 必须是有效的数字");
    }
    
    const numericId = parseInt(id);
    
    await checkDatabaseEnabled();
    
    // 检查数据源是否存在
    const existing = await db.select()
      .from(dataSources)
      .where(eq(dataSources.id, numericId));
    
    if (existing.length === 0) {
      throw new Error(`ID 为 ${numericId} 的数据源不存在`);
    }
    
    await db.delete(dataSources)
      .where(eq(dataSources.id, numericId));
    
    log.info("数据源删除成功:", { id: numericId });
    
    return {
      success: true,
      message: "数据源删除成功"
    };
  } catch (error) {
    log.error("删除数据源失败:", error);
    throw new Error(error instanceof Error ? error.message : String(error));
  }
}

// 批量创建数据源
export async function batchCreateDataSources(params: Record<string, any>): Promise<any> {
  try {
    log.info("批量创建数据源:", params);
    
    if (!Array.isArray(params.dataSources)) {
      throw new Error("请求体必须包含 dataSources 数组");
    }
    
    await checkDatabaseEnabled();
    
    const validatedSources = [];
    const errors = [];
    
    // 验证所有数据源
    for (let i = 0; i < params.dataSources.length; i++) {
      try {
        const validatedData = validateDataSource(params.dataSources[i]);
        validatedSources.push(validatedData);
      } catch (error) {
        errors.push({
          index: i,
          data: params.dataSources[i],
          error: error instanceof Error ? error.message : String(error)
        });
      }
    }
    
    if (errors.length > 0) {
      throw new Error(`数据验证失败: ${JSON.stringify(errors)}`);
    }
    
    // 批量插入
    const results = [];
    for (const source of validatedSources) {
      try {
        // 检查是否已存在
        const existing = await db.select()
          .from(dataSources)
          .where(eq(dataSources.platform, source.platform))
          .where(eq(dataSources.identifier, source.identifier));
        
        if (existing.length === 0) {
          const result = await db.insert(dataSources).values(source);
          results.push({
            success: true,
            id: result.insertId,
            ...source
          });
        } else {
          results.push({
            success: false,
            error: "已存在",
            ...source
          });
        }
      } catch (error) {
        results.push({
          success: false,
          error: error instanceof Error ? error.message : String(error),
          ...source
        });
      }
    }
    
    const successCount = results.filter(r => r.success).length;
    
    log.info(`批量创建完成: ${successCount}/${results.length} 成功`);
    
    return {
      success: true,
      data: results,
      summary: {
        total: results.length,
        success: successCount,
        failed: results.length - successCount
      },
      message: `批量创建完成: ${successCount}/${results.length} 成功`
    };
  } catch (error) {
    log.error("批量创建数据源失败:", error);
    throw new Error(error instanceof Error ? error.message : String(error));
  }
}