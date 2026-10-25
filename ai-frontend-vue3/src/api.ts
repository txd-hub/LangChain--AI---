const API_BASE = (import.meta.env.VITE_API_BASE_URL || "http://localhost:3000").replace(/\/$/, "");

async function errorMessage(response: Response): Promise<string> {
  const body = await response.json().catch(() => ({}));
  return typeof body.error === "string" ? body.error : `Request failed (${response.status})`;
}

export async function streamChat(
  message: string,
  handlers: { onToken: (token: string) => void; onError: (message: string) => void }
): Promise<void> {
  const response = await fetch(`${API_BASE}/api/chat`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ message })
  });
  if (!response.ok || !response.body) throw new Error(await errorMessage(response));

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let pending = "";
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    pending += decoder.decode(value, { stream: true });
    const events = pending.split("\n\n");
    pending = events.pop() ?? "";
    for (const rawEvent of events) {
      const type = rawEvent.match(/^event:\s*(.+)$/m)?.[1];
      const rawData = rawEvent.match(/^data:\s*(.+)$/m)?.[1];
      if (!type || !rawData) continue;
      try {
        const data: unknown = JSON.parse(rawData);
        if (type === "token" && typeof data === "string") handlers.onToken(data);
        if (type === "error" && data && typeof data === "object" && "message" in data) {
          handlers.onError(String(data.message));
        }
      } catch {
        // A malformed event does not prevent later tokens from rendering.
      }
    }
  }
}
