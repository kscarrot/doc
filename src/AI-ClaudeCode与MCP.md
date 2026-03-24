# 安装

## cli安装

```bash
# 检查node安装情况 最好使用最新的node环境 依赖的npm版本过低安装会出错
node --version
npm --version

# 全局安装 claude-code 本体
npm install -g @anthropic-ai/claude-code

# 检查安装情况
claude --version
claude update
```

## 秘钥配置

```bash
# 查看当前环境变量
env | grep ANTHROPIC

# 有配置文件需要清理一下对应地址的配置
sed -i '' '/ANTHROPIC_/d' ~/.zshrc 2>/dev/null; \
unset ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_BASE_URL; \
source ~/.zshrc 2>/dev/null; \
echo "✅ Claude 环境变量清理完成"

# 写入新配置

{
  echo 'export ANTHROPIC_BASE_URL=https://<your-url>'
  echo 'export ANTHROPIC_API_KEY=sk-xxx'
  echo 'export ANTHROPIC_AUTH_TOKEN=sk-xxx'
} | tee -a ~/.zshrc && source ~/.zshrc

# 检查设置情况
env | grep ANTHROPIC
```

# 使用

## 基本功能

```bash
# 检查当前状态
/status
# 切换模型
/models
# 初始化项目
/init
```

也可以直接使用各种`IDE`里的`ClaudeCode`插件

## 语言

切换中文可以直接在命令行输入

```markdown
Please set the default response language to Simplified Chinese for all future interactions.
```

然后要求写如全局配置 claude 会申请权限创建全局配置文件 目录在 `~/.claude/CLAUDE.md` 后续即可直接读取

也可以配置项目级别的偏好设置 配置在 `.claude/instructions`即可

在执行过程中会需要授权 可以在启动的时候增加 `--dangerously-skip-permissions` 的参数

## 计划模式

按 `Shift + Tab` 切换到计划模式。

### 好处

1. **降低「幻觉」与错误率**  
   `AI` 有时会「急于求成」，直接修改代码可能会忽略复杂的逻辑依赖。在计划阶段，`AI` 会先扫描相关文件、理解函数调用链；通过先写出步骤，它能自我检查逻辑漏洞。

2. **节省 `Token` 与成本**  
   如果你使用的是顶级模型，每一行代码的写入都是昂贵的。计划通常只有几百个 `Token`。如果你发现 `AI` 理解错了你的意图，可以在它正式开始大规模重构（消耗数万 `Token`）之前，通过 `Ctrl+C` 或拒绝计划来及时止损。

3. **提供「人工审核」的机会**  
   计划模式会列出：
   - 修改哪些文件
   - 新增哪些依赖
   - 核心逻辑变更

   这是对开发者最友好的地方：发现与意图不完全匹配时，可以提前中断修改或补充条件。

## MCP配置


> MCP(Model Context Protocol) 是AI调用的一种通用接口 通过绑定技能描述于接口让大模型在推理过程中可以调用拓展能力

### 为什么需要 `MCP`？

   在没有 `MCP` 之前，如果你想让 `Cursor` 访问你的 `GitHub`、`Notion` 或本地数据库，开发者必须为每个工具编写特定的插件或代码。

   **痛点**：由于每家 AI 工具（`Cursor`、`Windsurf`、`Claude Desktop`）的接口都不一样，导致集成非常零碎且难以维护。

   **解决**：`MCP` 提供了通用标准。开发者只需写一个 `MCP Server`（连接器），任何支持 `MCP` 的 AI 编程工具（`Host`）就都能直接调用它。

### `MCP` 的核心架构

   `MCP` 系统由三个角色组成：
   - **`Host`（宿主）**：你使用的 AI 软件（如 `Cursor`、`Windsurf`、`Claude Desktop`、`VS Code`）。
   - **`Client`（客户端）**：`Host` 内部集成的协议处理器，负责与 `Server` 通信。
   - **`Server`（服务器）**：提供具体能力的「插件」（如 `Google Search Server`、`GitHub Server`、本地文件系统 `Server`）。

### 在编程工具中它能做什么？

   有了 `MCP`，你的 `AI` 助手不再只是一个「聊天框」，它拥有了手和眼：
   - **读取实时数据**：让 `AI` 访问最新的 `API` 文档、查询实时天气或搜索网页（如通过 `Brave` / `Tavily` 的 `MCP`）。
   - **操作外部工具**：直接让 `AI` 在 `GitHub` 上提 `PR`、在 `Linear` 上创建任务，或在数据库里运行 `SQL` 查询。
   - **深度的本地上下文**：`AI` 可以读取你指定的本地目录、分析代码依赖，而不受限于 `IDE` 自带的索引功能。

### 实现一个MCP

先写一个简单的url转二维码的工具函数

```typescript
// qr.mts
import qrcode from "qrcode";
import clipboardy from "clipboardy";

async function generateAndCopy(url: string) {
  try {
    // 生成二维码的 Data URL (Base64)
    const dataUrl = await qrcode.toDataURL(url);

    // 注意：clipboardy 主要支持文本。
    // 如果要将“图片文件”存入剪贴板，通常需要根据 OS 调用不同的原生指令。
    // 这里我们先实现“生成并提示”，如果是纯文本 MCP，直接返回 base64 或路径。
    await clipboardy.write(dataUrl);

    console.log(`✅ 二维码已生成并以 Base64 格式写入剪贴板！`);
    return dataUrl;
  } catch (err) {
    console.error("错误:", err);
  }
}

const inputUrl = process.argv[2] || "https://google.com";
generateAndCopy(inputUrl);
```

验证通过后让`claude`把工具函数封装成一个`MCP` 要求使用最新版本的接口

```typescript
// index.mts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { generateQrAndCopy } from "./qr.mts";

const server = new McpServer({
  name: "qr-generator",
  version: "1.0.0",
});

// 注册工具
server.registerTool(
  "url_to_qr",
  {
    description: "将 URL 转换为二维码 Base64 字符串并复制到系统剪贴板",
    inputSchema: { url: z.string().describe("需要转换的链接") },
  },
  async ({ url }) => {
    try {
      const dataUrl = await generateQrAndCopy(url);
      return {
        content: [{ type: "text", text: `✅ 二维码已生成并复制到剪贴板！\n${dataUrl}` }],
      };
    } catch (err) {
      return {
        content: [{ type: "text", text: `❌ 生成失败：${err}` }],
        isError: true,
      };
    }
  },
);

// 启动（使用标准输入输出通信）
const transport = new StdioServerTransport();
await server.connect(transport);
```

等`claude`写完代码安装完依赖 命令claude写本地的配置注册`MCP`

会在`.claude/settings.local.json`补充配置

```json
{
  "mcpServers": {
    "qr-generator": {
      "command": "node",
      "args": ["--experimental-strip-types", "/Users/ksm/Code/url-to-qr/index.mts"]
    }
  }
}
```

然后让`cluade`在命令行里打印出百度主页的二维码 正常的话会显示一个二维码扫码验证即可
