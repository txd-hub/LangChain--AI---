function required(name: string, fallback?: string): string {
  const value = process.env[name] ?? fallback;
  if (!value) throw new Error(`Missing environment variable: ${name}`);
  return value;
}

export const env = {
  openaiBaseUrl: required("OPENAI_BASE_URL", "http://127.0.0.1:8080/v1"),
  chatModel: required("CHAT_MODEL", "qwen2.5-0.5b-instruct"),
  openaiApiKey: required("OPENAI_API_KEY", "not-needed"),
  corsOrigin: required("CORS_ORIGIN", "http://localhost:5173")
} as const;
