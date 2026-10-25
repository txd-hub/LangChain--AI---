# 最小本地流式 AI 问答

一个仅包含流式聊天的本地 Demo：Vue 3 前端 + Next.js App Router 后端 SSE + LangChain-JS。

- 无 RAG、无向量库、无文件上传、无 Python 依赖。
- 默认适合低配电脑的中文模型：`Qwen2.5-0.5B-Instruct` 的 GGUF Q4_K_M 量化版。
- 后端使用 OpenAI 兼容协议，修改一个环境变量即可接入 llama.cpp、LocalAI、vLLM 或云端兼容服务。

## 项目目录

```text
AI/
├─ ai-backend-nextjs/
│  ├─ src/app/api/chat/route.ts   # POST SSE 打字机流
│  ├─ src/app/api/health/route.ts # 模型服务健康检查
│  ├─ src/lib/chat.ts             # LangChain ChatOpenAI 客户端
│  └─ .env.local                  # OpenAI 兼容服务配置
├─ ai-frontend-vue3/
│  ├─ src/App.vue                 # 极简聊天页面
│  └─ src/api.ts                  # POST SSE 读取器
└─ README.md
```

## 前置条件

安装 Node.js 20 LTS 或更高版本，并确认：

```powershell
node -v
npm -v
```

## 安装依赖

```powershell
cd .\ai-backend-nextjs
npm install

cd ..\ai-frontend-vue3
npm install
```

## 启动本地模型（llama.cpp）

1. 从 llama.cpp 的 [Release 页面](https://github.com/ggml-org/llama.cpp/releases) 下载 Windows 版，解压后确保有 `llama-server.exe`。
2. 从 Hugging Face 下载 `Qwen2.5-0.5B-Instruct-Q4_K_M.gguf`，例如 [bartowski/Qwen2.5-0.5B-Instruct-GGUF](https://huggingface.co/bartowski/Qwen2.5-0.5B-Instruct-GGUF)。这是中文表现较好且约 0.5 GB 的量化模型。
3. 在模型文件和 `llama-server.exe` 所在目录运行：

```powershell
.\llama-server.exe -m .\Qwen2.5-0.5B-Instruct-Q4_K_M.gguf --alias qwen2.5-0.5b-instruct --port 8080 -c 2048 -ngl 0
```

`--alias` 与后端模型名一致；`-ngl 0` 表示纯 CPU，适合没有独显的电脑。服务启动后提供 OpenAI 兼容接口：`http://127.0.0.1:8080/v1`。

## 启动应用

保留 llama.cpp 窗口运行，再打开两个 PowerShell 窗口：

```powershell
# 窗口 1：Next.js 后端
cd .\ai-backend-nextjs
npm run dev
```

```powershell
# 窗口 2：Vue 前端
cd .\ai-frontend-vue3
npm run dev
```

访问 `http://localhost:5173`。后端健康检查：`http://localhost:3000/api/health`。

## 切换 OpenAI 兼容服务

编辑 `ai-backend-nextjs/.env.local` 后重启 Next.js：

```dotenv
OPENAI_BASE_URL=http://127.0.0.1:8080/v1
CHAT_MODEL=qwen2.5-0.5b-instruct
OPENAI_API_KEY=not-needed
CORS_ORIGIN=http://localhost:5173
```

对于其他兼容服务，只需改 `OPENAI_BASE_URL`、`CHAT_MODEL`，并在需要鉴权时填入 `OPENAI_API_KEY`。例如 LocalAI 常用地址为 `http://127.0.0.1:8080/v1`；云端兼容服务填写其 `/v1` 地址和 API Key 即可。

## API

`POST /api/chat` 请求：

```json
{ "message": "用一句话介绍你自己" }
```

响应为 `text/event-stream`，依次发送 `token`、`done`，异常时发送 `error`。前端用 `fetch` 读取 POST 响应流，因此不需要 EventSource。
