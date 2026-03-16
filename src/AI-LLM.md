# 本地安装

## 分析

### 优点

- 比较好的隐私和数据安全 可以离线不依赖外网
- 没有 tokens 焦虑 可以无负担的并行跑任务
- 可以微调模型针对特化任务,可以使用无审查的模型

### 缺点

- 硬件成本 首先你需要有一个还算可以的显卡

    (5090 吐 tokens 的速度已经比阅读速度快很多了)

- 本地模型的参数也是比云上跑的要低的,推理上会更笨

- 通用知识库建设几乎没有,缺少缓存层,联网查询最新消息比较难搞

----

对于联网查询局限性展开讲一下

本地的大模型我们可以通过配置插件的方式让大模型在推理的时候支持联网

比如使用基于`DuckDuckGo`的`Web Search`

当模型发现自己不知道答案（比如“今天的天气”）时

它会输出一个特殊的指令调用搜索工具

插件执行搜索后，把结果返还给模型做汇总和回答

然后衍生出这些问题:

1. 需要先查网络,然后抓取信息,不如云端直接命中缓存快

   大量的问题都是被重复提问的

   云端的大模型有时候都没有走到推理这一步

   在中间就找到已经分析好的答案提前返回了

2. 搜索结果信息密度很差,消息没有经过过滤筛选,没有结构化

3. 算力会浪费在网页数据处理上,还会让`context`爆炸导致幻觉

4. 国内寡头都倾向做私域 大量结构化知识不互通 通用搜索工具搜不到 知识割裂

需要大模型兼具推理以外的内容搜索功能 综合下来体验就很差了

通用提问个人体感体验最好的还是`Gemini`

## [ollama](https://github.com/ollama/ollama)

> ollama 是一个大模型管理和配置工具 会自动帮你搞定下载,环境配置,显卡加速等功能

```bash
brew install ollama
# 检查安装情况
ollama --version

# 启动服务（推荐：后台运行，不占用命令行）
brew services start ollama
# 或者临时启动（会占用当前终端）
ollama serve

# 管理服务
brew services stop ollama    # 停止服务
brew services restart ollama # 重启服务
brew services list          # 查看服务状态

# 安装对应的模型
ollama run qwen2.5:14b # 约 9 GB
# 安装完成启动之后,可以在终端看到一个交互框 输入 /bye 可以退出

# 下载文件的位置 -partial标识文件在下载中
ls -al ~/.ollama/models/blobs

# 或者使用更小的模型（下载更快）
ollama run qwen2.5:7b       # 约 4.4 GB
ollama run qwen2.5:1.5b     # 约 1 GB
```

### 模型和推荐配置

| 模型规格 | 平台 | 内存/显存安全线 | 推荐配置                                                   | 速度(预估) | 核心评价                               |
| -------- | ---- | --------------- | ---------------------------------------------------------- | ---------- | -------------------------------------- |
| 7B       | Mac  | ≥ 8GB           | M3/M4<br>内存: 16GB<small>(8GB 仅能勉强跑)</small>         | 55~70 t/s  | 入门首选<br>Mac 16GB 极其流畅          |
| 7B       | PC   | ≥ 8GB           | RTX 3060 (12GB)<br>RTX 4060 (8GB)                          | 80~110 t/s | PC 端 3060 12G 是性价比之神            |
| 14B      | Mac  | ≥ 12GB          | M3/M4<br>内存: 16GB (底线)<br>内存: 24GB (推荐)            | 40~55 t/s  | 开发者的黄金档<br>M4 16GB 的完美甜点区 |
| 14B      | PC   | ≥ 12GB          | RTX 4070 Super (12GB)<br>RTX 4060 Ti (16GB 版)             | 70~90 t/s  | PC 端显存必须 ≥12GB，否则爆显存        |
| 32B      | Mac  | ≥ 24GB          | M3/M4 Max<br>内存: 36GB (勉强)<br>内存: 48GB / 64GB (推荐) | 30~45 t/s  | 显存决定生死<br>Mac 优势在于大内存便宜 |
| 32B      | PC   | ≥ 24GB          | RTX 3090 (24GB)<br>RTX 4090 (24GB)                         | 50~80 t/s  | PC 端只有 24G 卡能全速跑，4080 都不行  |

### 跨机器接入

server 机

```bash
pkill ollama
# 默认 127.0.0.1 只对本机可访问
OLLAMA_HOST=0.0.0.0 ollama serve


lsof -i :11434
# NAME 输出  *:11434 (LISTEN)

curl -v http://127.0.0.1:11434
# 输出 Ollama is running

# 获取本地ip地址
ipconfig getifaddr en1 | xargs -I {} echo "http://{}:11434" | pbcopy && echo "已复制到剪贴板"
```

client 机

```bash
export OLLAMA_HOST="http://10.10.20.203:11434"
ollama run qwen2.5:14b
```

# 云服务接入

## 火山引擎接入

### 第一步：注册与实名认证（必须）

1. **访问官网：** 前往 [火山引擎官网 (volcengine.com)](https://www.volcengine.com/)。
2. **注册账号：** 点击右上角注册并登录。
3. **实名认证：** 使用云服务必须进行实名认证

### 第二步：进入“火山方舟”控制台

火山引擎的大模型服务平台叫做**“火山方舟” (Ark)**。

1. 登录后，在顶部的搜索栏输入 **“火山方舟”** 或 **“大模型服务”**。
2. 点击进入控制台。如果是第一次进入，可能需要点击“开通服务”（通常是免费开通，按量付费）。

### 第三步：创建 API Key

这是你用来通过身份验证的钥匙。

1. 在火山方舟控制台左侧菜单栏，找到 **“API Key 管理”**。
2. 点击 **“创建 API Key”**。
3. 创建成功后，复制这个长字符串。

- _注意：请妥善保存，它只会出现一次。_

### 第四步：创建推理接入点

1. 在左侧菜单栏，找到 **“在线推理”** -> **“推理接入点”**。
2. 点击 **“创建推理接入点”** 或者直接使用预制推理接入点
3. **配置接入点：**

- **名称：** 随便起（例如 `my-doubao-app`）。
- **模型版本：** 选择你想要用的模型，例如 `Doubao-pro-4k` 或 `Doubao-lite-32k`（推荐先用 lite 或 pro 测试）。

4. 点击确认创建。
5. 在列表中，你会看到一个 **接入点 ID (Endpoint ID)**，格式通常是 `ep-202406...`。

- **请复制这个 ID，代码里要用！**

---

### 第五步：在代码中使用

#### Curl 验证

```bash
curl https://ark.cn-beijing.volces.com/api/v3/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ARK_API_KEY" \
  -d $'{
    "model": "doubao-seed-1-6-lite-251015",
    "max_completion_tokens": 65535,
    "reasoning_effort": "medium",
    "messages": [
        {
            "content": [
                {
                    "text": "今天天气怎么样?",
                    "type": "text"
                }
            ],
            "role": "user"
        }
    ]
}'

```

火山引擎现在的 API 已经**兼容 OpenAI 格式**了，这让集成变得非常简单。

#### Vercel AI SDK

你需要使用 `openai` 的适配器，但是把 `baseURL` 改成火山引擎的地址。

1. **安装：** `npm install @ai-sdk/openai`
2. **配置 `.env`：**

```env
VOLCENGINE_API_KEY=你的APIkey

```

3. **代码示例：**

```typescript
import { createOpenAI } from "@ai-sdk/openai";
import { streamText } from "ai";

// 1. 创建自定义的 OpenAI 实例指向火山引擎
const volcengine = createOpenAI({
  baseURL: "https://ark.cn-beijing.volces.com/api/v3", // 火山引擎的标准接入地址
  apiKey: process.env.VOLCENGINE_API_KEY,
});

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = await streamText({
    // 2. 这里填你在第四步获得的【接入点 ID】，不是模型名！
    model: volcengine("ep-2024060401xxxx-xxxxx"),
    messages,
  });

  return result.toDataStreamResponse();
}
```

#### LangChain

同样使用 OpenAI 的类，但修改 Base URL。

```typescript
import { ChatOpenAI } from "@langchain/openai";

const model = new ChatOpenAI({
  openAIApiKey: "你的sk-xxxx",
  // 这里的 modelName 必须填 Endpoint ID
  modelName: "ep-2024060401xxxx-xxxxx",
  configuration: {
    baseURL: "https://ark.cn-beijing.volces.com/api/v3",
  },
});
```


#### 交互式命令行

使用[lobe-chat](https://github.com/lobehub/lobe-chat) 或者 [llm](https://github.com/simonw/llm) 简单接入即可

