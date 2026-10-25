import { chatModel } from "@/lib/chat";
import { corsHeaders, json, optionsResponse } from "@/lib/http";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type ChatRequest = { message?: unknown };
const encoder = new TextEncoder();

function sse(event: string, data: unknown): Uint8Array {
  return encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
}

export async function OPTIONS() {
  return optionsResponse();
}

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as ChatRequest;
    const message = typeof body.message === "string" ? body.message.trim() : "";
    if (!message) return json({ error: "message cannot be empty" }, { status: 400 });
    if (message.length > 4000) return json({ error: "message is limited to 4000 characters" }, { status: 400 });

    const modelStream = await chatModel.stream([
      ["system", "You are a concise, helpful assistant. Reply in the user's language."],
      ["human", message]
    ]);
    const stream = new ReadableStream<Uint8Array>({
      async start(controller) {
        try {
          for await (const chunk of modelStream) {
            const text = typeof chunk.content === "string" ? chunk.content : "";
            if (text) controller.enqueue(sse("token", text));
          }
          controller.enqueue(sse("done", { ok: true }));
        } catch (error) {
          controller.enqueue(sse("error", { message: error instanceof Error ? error.message : "Model generation failed" }));
        } finally {
          controller.close();
        }
      }
    });

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream; charset=utf-8",
        "Cache-Control": "no-cache, no-transform",
        Connection: "keep-alive",
        "X-Accel-Buffering": "no"
      }
    });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "Chat request failed" }, { status: 500 });
  }
}
