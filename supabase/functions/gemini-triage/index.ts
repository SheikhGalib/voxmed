import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type GeminiJsonResponse = {
  assistantMessage?: unknown;
  followUps?: unknown;
  triageResult?: {
    severity?: unknown;
    specialty?: unknown;
    suggested_doctors?: unknown;
    red_flags?: unknown;
    disclaimer?: unknown;
    suggested_doctor_cards?: unknown;
  };
};

type LoadedPrompts = {
  patient: string;
  doctor: string;
};

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const DEFAULT_DISCLAIMER =
  "I can help with triage guidance, but I am not a substitute for a licensed clinician. For chest pain, breathing difficulty, stroke symptoms, severe bleeding, seizures, or loss of consciousness, seek emergency care immediately.";

const DEFAULT_PATIENT_PROMPT =
  "You are a safety-first patient triage assistant. Help users identify appropriate doctors, hospitals, and tests. Do not prescribe medications or provide dosage instructions.";

const DEFAULT_DOCTOR_PROMPT =
  "You are a safety-first doctor workflow assistant. Help with patient summaries, analytics, scheduling priorities, and renewal workflows. Do not fabricate clinical facts.";

const DEFAULT_MODEL = "gemini-2.5-flash";
const GEMINI_ENDPOINT_BASE = "https://generativelanguage.googleapis.com/v1beta/models";

let promptCache: LoadedPrompts | null = null;

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });
}

async function loadSystemPrompts(): Promise<LoadedPrompts> {
  if (promptCache) return promptCache;

  try {
    const fileUrl = new URL("./system_prompts.json", import.meta.url);
    const raw = await Deno.readTextFile(fileUrl);
    const parsed = JSON.parse(raw) as Partial<LoadedPrompts>;

    promptCache = {
      patient:
        typeof parsed.patient === "string" && parsed.patient.trim().length > 0
          ? parsed.patient.trim()
          : DEFAULT_PATIENT_PROMPT,
      doctor:
        typeof parsed.doctor === "string" && parsed.doctor.trim().length > 0
          ? parsed.doctor.trim()
          : DEFAULT_DOCTOR_PROMPT,
    };
  } catch (error) {
    console.error("Failed to load system_prompts.json, using built-in defaults:", error);
    promptCache = {
      patient: DEFAULT_PATIENT_PROMPT,
      doctor: DEFAULT_DOCTOR_PROMPT,
    };
  }

  return promptCache;
}

function getGeminiKeys(): string[] {
  const keys: string[] = [];
  for (let i = 1; i <= 10; i += 1) {
    const key = Deno.env.get(`GEMINI_API_KEY_${i}`)?.trim();
    if (key) keys.push(key);
  }

  const fallback = Deno.env.get("GEMINI_API_KEY")?.trim();
  if (fallback) keys.push(fallback);

  // Deduplicate while preserving order.
  return [...new Set(keys)];
}

function isRateLimited(status: number, rawBody: string): boolean {
  const lower = rawBody.toLowerCase();
  return (
    status === 429 ||
    lower.includes("resource_exhausted") ||
    lower.includes("quota") ||
    lower.includes("rate limit")
  );
}

async function callGeminiWithFallback(
  model: string,
  payload: Record<string, unknown>,
  apiKeys: string[],
): Promise<Record<string, unknown>> {
  if (apiKeys.length === 0) {
    throw new Error("No Gemini API keys configured. Set GEMINI_API_KEY_1..N secrets.");
  }

  let lastError: Error | null = null;

  for (let i = 0; i < apiKeys.length; i += 1) {
    const key = apiKeys[i];
    const url = `${GEMINI_ENDPOINT_BASE}/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(key)}`;

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      const raw = await response.text();

      if (response.ok) {
        return JSON.parse(raw) as Record<string, unknown>;
      }

      if (isRateLimited(response.status, raw) && i < apiKeys.length - 1) {
        lastError = new Error(`Gemini rate-limited key #${i + 1}; falling back to next key.`);
        continue;
      }

      throw new Error(`Gemini request failed (${response.status}): ${raw}`);
    } catch (error) {
      const wrapped = error instanceof Error ? error : new Error(String(error));
      if (i < apiKeys.length - 1) {
        lastError = wrapped;
        continue;
      }
      throw wrapped;
    }
  }

  throw lastError ?? new Error("All Gemini keys failed.");
}

function stripCodeFence(text: string): string {
  const trimmed = text.trim();
  if (!trimmed.startsWith("```") || !trimmed.endsWith("```")) {
    return trimmed;
  }

  const withoutFirstFence = trimmed.replace(/^```[a-zA-Z]*\s*/, "");
  return withoutFirstFence.replace(/\s*```$/, "").trim();
}

function safeJsonParse(text: string): GeminiJsonResponse | null {
  try {
    return JSON.parse(stripCodeFence(text)) as GeminiJsonResponse;
  } catch {
    return null;
  }
}

function toStringArray(input: unknown): string[] {
  if (!Array.isArray(input)) return [];
  return input
    .map((item) => String(item).trim())
    .filter((item) => item.length > 0);
}

function normalizeSeverity(input: unknown): "low" | "medium" | "high" | "emergency" {
  const value = String(input ?? "medium").toLowerCase();
  if (value === "low" || value === "medium" || value === "high" || value === "emergency") {
    return value;
  }
  return "medium";
}

function sanitizeModelResponse(raw: GeminiJsonResponse, fallbackText: string) {
  const assistantMessage =
    typeof raw.assistantMessage === "string" && raw.assistantMessage.trim().length > 0
      ? raw.assistantMessage.trim()
      : fallbackText;

  const followUps = toStringArray(raw.followUps).slice(0, 6);

  const triageResult = {
    severity: normalizeSeverity(raw.triageResult?.severity),
    specialty:
      typeof raw.triageResult?.specialty === "string" && raw.triageResult.specialty.trim().length > 0
        ? raw.triageResult.specialty.trim()
        : "General Medicine",
    suggested_doctors: toStringArray(raw.triageResult?.suggested_doctors).slice(0, 8),
    red_flags: toStringArray(raw.triageResult?.red_flags).slice(0, 8),
    disclaimer:
      typeof raw.triageResult?.disclaimer === "string" && raw.triageResult.disclaimer.trim().length > 0
        ? raw.triageResult.disclaimer.trim()
        : DEFAULT_DISCLAIMER,
  };

  return {
    assistantMessage,
    followUps,
    triageResult,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { success: false, error: "Method not allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")?.trim();

  if (!supabaseUrl || !supabaseAnonKey) {
    return jsonResponse(500, {
      success: false,
      error: "Missing Supabase environment variables (SUPABASE_URL/SUPABASE_ANON_KEY).",
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse(401, { success: false, error: "Missing Authorization header." });
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  });

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    return jsonResponse(401, { success: false, error: "Unauthorized user." });
  }

  let payload: Record<string, unknown>;
  try {
    payload = (await req.json()) as Record<string, unknown>;
  } catch {
    return jsonResponse(400, { success: false, error: "Invalid JSON payload." });
  }

  const message = String(payload.message ?? "").trim();
  if (message.length === 0) {
    return jsonResponse(400, { success: false, error: "Message is required." });
  }

  const requestedConversationId = String(payload.conversationId ?? "").trim();

  try {
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();

    if (profileError) {
      throw new Error(`Failed to load profile role: ${profileError.message}`);
    }

    const role = profile?.role === "doctor" ? "doctor" : "patient";
    let conversationId = requestedConversationId;

    if (conversationId.length > 0) {
      const { data: found, error: lookupError } = await supabase
        .from("ai_conversations")
        .select("id")
        .eq("id", conversationId)
        .eq("patient_id", user.id)
        .maybeSingle();

      if (lookupError) {
        throw new Error(`Failed to verify conversation: ${lookupError.message}`);
      }

      if (!found) {
        return jsonResponse(404, {
          success: false,
          error: "Conversation not found for current user.",
        });
      }
    } else {
      const title = message.length > 70 ? `${message.slice(0, 70)}...` : message;
      const { data: created, error: createError } = await supabase
        .from("ai_conversations")
        .insert({
          patient_id: user.id,
          title,
        })
        .select("id")
        .single();

      if (createError || !created) {
        throw new Error(`Failed to create conversation: ${createError?.message ?? "unknown"}`);
      }

      conversationId = String(created.id);
    }

    const { error: insertUserMessageError } = await supabase
      .from("ai_messages")
      .insert({
        conversation_id: conversationId,
        role: "user",
        content: message,
      });

    if (insertUserMessageError) {
      throw new Error(`Failed to store user message: ${insertUserMessageError.message}`);
    }

    const { data: historyRows, error: historyError } = await supabase
      .from("ai_messages")
      .select("role, content")
      .eq("conversation_id", conversationId)
      .order("created_at", { ascending: false })
      .limit(20);

    if (historyError) {
      throw new Error(`Failed to read message history: ${historyError.message}`);
    }

    const prompts = await loadSystemPrompts();
    const basePrompt = role === "doctor" ? prompts.doctor : prompts.patient;

    const outputInstruction = [
      "Output must be strict JSON only (no markdown, no code fences).",
      "Use this schema:",
      "{",
      "  \"assistantMessage\": string,",
      "  \"followUps\": string[],",
      "  \"triageResult\": {",
      "    \"severity\": \"low\" | \"medium\" | \"high\" | \"emergency\",",
      "    \"specialty\": string,",
      "    \"suggested_doctors\": string[],",
      "    \"red_flags\": string[],",
      "    \"disclaimer\": string",
      "  }",
      "}",
      "Never provide medication dosage instructions.",
    ].join("\n");

    const history = [...(historyRows ?? [])].reverse();
    const geminiPayload = {
      systemInstruction: {
        parts: [{ text: `${basePrompt}\n\n${outputInstruction}` }],
      },
      contents: history.map((row) => ({
        role: row.role === "assistant" ? "model" : "user",
        parts: [{ text: String(row.content ?? "") }],
      })),
      generationConfig: {
        temperature: 0.25,
        responseMimeType: "application/json",
      },
    };

    const model = Deno.env.get("GEMINI_MODEL")?.trim() || DEFAULT_MODEL;
    const keys = getGeminiKeys();
    const geminiResult = await callGeminiWithFallback(model, geminiPayload, keys);

    const candidateText = (
      ((geminiResult.candidates as Array<Record<string, unknown>> | undefined)?.[0]?.content as
        | Record<string, unknown>
        | undefined)?.parts as Array<Record<string, unknown>> | undefined
    )
      ?.map((part) => String(part.text ?? ""))
      .join("\n")
      .trim() ?? "";

    const parsed = safeJsonParse(candidateText);
    const sanitized = sanitizeModelResponse(
      parsed ?? { assistantMessage: candidateText },
      "I can help triage your concern. Could you share symptom duration, severity, and any known conditions?",
    );

    if (sanitized.triageResult.specialty.length > 0) {
      const specialty = sanitized.triageResult.specialty;
      const { data: doctors, error: doctorsError } = await supabase
        .from("doctors")
        .select(
          "id, specialty, rating, consultation_fee, hospital_id, profiles!doctors_profile_id_fkey(full_name), hospitals(name, city)",
        )
        .ilike("specialty", `%${specialty}%`)
        .order("rating", { ascending: false })
        .limit(5);

      if (!doctorsError && doctors && doctors.length > 0) {
        if (sanitized.triageResult.suggested_doctors.length === 0) {
          sanitized.triageResult.suggested_doctors = doctors
            .map((doctor) => String((doctor as Record<string, unknown>).id ?? ""))
            .filter((id) => id.length > 0);
        }
      }
    }

    const { error: insertAssistantMessageError } = await supabase
      .from("ai_messages")
      .insert({
        conversation_id: conversationId,
        role: "assistant",
        content: sanitized.assistantMessage,
        metadata: {
          follow_ups: sanitized.followUps,
          triage_result_preview: sanitized.triageResult,
        },
      });

    if (insertAssistantMessageError) {
      throw new Error(`Failed to store assistant message: ${insertAssistantMessageError.message}`);
    }

    const { error: updateConversationError } = await supabase
      .from("ai_conversations")
      .update({
        triage_result: sanitized.triageResult,
      })
      .eq("id", conversationId)
      .eq("patient_id", user.id);

    if (updateConversationError) {
      throw new Error(`Failed to update conversation triage result: ${updateConversationError.message}`);
    }

    return jsonResponse(200, {
      success: true,
      data: {
        conversationId,
        assistantMessage: sanitized.assistantMessage,
        followUps: sanitized.followUps,
        triageResult: sanitized.triageResult,
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse(500, {
      success: false,
      error: message,
    });
  }
});
