import { ChatOpenAI } from "@langchain/openai";
import { env } from "@/lib/env";

// Works with llama.cpp, LocalAI, vLLM, and other OpenAI-compatible servers.
export const chatModel = new ChatOpenAI({
  apiKey: env.openaiApiKey,
  model: env.chatModel,
  configuration: { baseURL: env.openaiBaseUrl },
  temperature: 0.7,
  streaming: true
});
