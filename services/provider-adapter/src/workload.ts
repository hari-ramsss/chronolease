import { createHash } from "node:crypto";
import { createServer, type Server } from "node:http";
import type { WorkloadClient, WorkloadInput, WorkloadResponse } from "./types.ts";

/**
 * Deterministic workload client for unit tests. No network calls.
 */
export class DeterministicWorkloadClient implements WorkloadClient {
  private failureEvery: number;
  private latencyMs: number;
  calls = 0;

  constructor(options: { failureEvery?: number; latencyMs?: number } = {}) {
    this.failureEvery = options.failureEvery ?? 0;
    this.latencyMs = options.latencyMs ?? 5;
  }

  async execute(input: WorkloadInput): Promise<WorkloadResponse> {
    this.calls += 1;
    const ok = this.failureEvery === 0 || this.calls % this.failureEvery !== 0;
    const outputHash = createHash("sha256")
      .update(`${input.jobId}:${input.serviceType}:${input.index}:${ok}`)
      .digest("hex");
    return {
      ok,
      statusCode: ok ? 200 : 503,
      latencyMs: this.latencyMs + (input.index % 3),
      outputHash,
    };
  }
}

/**
 * Minimal local OpenAI-compatible mock service. It accepts POST
 * /v1/chat/completions and returns a deterministic document-extraction result.
 * No cloud GPU or real LLM inference is involved.
 */
export function createOpenAICompatServer(options: { failureEvery?: number } = {}): Server {
  const failureEvery = options.failureEvery ?? 0;
  let calls = 0;
  return createServer((req, res) => {
    if (req.method !== "POST" || !req.url?.startsWith("/v1/chat/completions")) {
      res.writeHead(404, { "content-type": "application/json" });
      res.end(JSON.stringify({ error: "not found" }));
      return;
    }
    const chunks: Buffer[] = [];
    req.on("data", (chunk: Buffer) => chunks.push(chunk));
    req.on("end", () => {
      calls += 1;
      let jobId = "unknown";
      try {
        const body = JSON.parse(Buffer.concat(chunks).toString("utf8")) as {
          messages?: Array<{ content?: string }>;
        };
        const content = body.messages?.[0]?.content ?? "";
        const marker = content.match(/job_id=([^\s]+)/);
        if (marker) jobId = marker[1];
      } catch {
        // Keep the deterministic fallback id for malformed local requests.
      }
      const failed = failureEvery > 0 && calls % failureEvery === 0;
      res.writeHead(failed ? 503 : 200, { "content-type": "application/json" });
      res.end(
        JSON.stringify({
          id: `chatcmpl-local-${calls}`,
          object: "chat.completion",
          created: 1_750_000_000,
          model: "local-document-extraction-mock",
          choices: failed
            ? []
            : [
                {
                  index: 0,
                  message: {
                    role: "assistant",
                    content: JSON.stringify({
                      job_id: jobId,
                      document_type: "invoice",
                      fields: { vendor: "acme", total: "42.00" },
                      status: "extracted",
                    }),
                  },
                  finish_reason: "stop",
                },
              ],
          usage: { prompt_tokens: 8, completion_tokens: 12, total_tokens: 20 },
        }),
      );
    });
  });
}

/** HTTP client for the local OpenAI-compatible workload endpoint. */
export class HttpWorkloadClient implements WorkloadClient {
  private readonly endpoint: string;

  constructor(endpoint: string) {
    this.endpoint = endpoint;
  }

  async execute(input: WorkloadInput): Promise<WorkloadResponse> {
    const started = performance.now();
    const response = await fetch(this.endpoint, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        model: "local-document-extraction-mock",
        messages: [
          {
            role: "user",
            content: `Extract structured fields. job_id=${input.jobId} service=${input.serviceType} index=${input.index}`,
          },
        ],
        temperature: 0,
      }),
    });
    const latencyMs = Math.round((performance.now() - started) * 100) / 100;
    const body = (await response.json()) as { id?: string };
    return {
      ok: response.ok,
      statusCode: response.status,
      latencyMs,
      outputHash: createHash("sha256")
        .update(`${body.id ?? "none"}:${input.jobId}:${input.index}`)
        .digest("hex"),
    };
  }
}
