import { env } from "@/lib/env";
import { json, optionsResponse } from "@/lib/http";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function OPTIONS() {
  return optionsResponse();
}

export async function GET() {
  const modelServer = await fetch(`${env.openaiBaseUrl}/models`)
    .then((response) => response.ok)
    .catch(() => false);
  return json(
    { status: modelServer ? "ok" : "degraded", modelServer, model: env.chatModel },
    { status: modelServer ? 200 : 503 }
  );
}
