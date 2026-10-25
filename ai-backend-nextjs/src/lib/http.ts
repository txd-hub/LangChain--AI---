import { env } from "@/lib/env";

export const corsHeaders = {
  "Access-Control-Allow-Origin": env.corsOrigin,
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Max-Age": "86400",
  Vary: "Origin"
};

export function optionsResponse(): Response {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export function json(data: unknown, init: ResponseInit = {}): Response {
  return Response.json(data, {
    ...init,
    headers: { ...corsHeaders, ...init.headers }
  });
}
