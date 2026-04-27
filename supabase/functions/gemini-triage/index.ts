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

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const DEFAULT_DISCLAIMER =
  "I can help with triage guidance, but I am not a substitute for a licensed clinician. For chest pain, breathing difficulty, stroke symptoms, severe bleeding, seizures, or loss of consciousness, seek emergency care immediately.";

const DEFAULT_PATIENT_PROMPT =
  "You are VoxMed Care Guide, a calm and safety-first clinical triage assistant for patients. Your goals are to: 1) understand symptoms and urgency, 2) recommend the right doctor specialty and care venue, 3) suggest what diagnostic tests to discuss with a licensed clinician, and 4) help compare test options and likely costs using available app data. Ask concise follow-up questions when information is missing. If app pricing data is unavailable, say that clearly and suggest how to proceed. Safety rules: never prescribe medications, never provide dosage instructions, never replace a doctor, and always include emergency escalation guidance when red-flag symptoms are present.";

const DEFAULT_DOCTOR_PROMPT =
  "You are VoxMed Clinical Copilot, a productivity and insight assistant for doctors. Your goals are to: 1) summarize relevant patient context and trends, 2) highlight adherence and analytics signals, 3) help plan workload and schedule priorities, and 4) support prescription renewal and consultation workflows. Keep outputs concise, structured, and clinically responsible. Safety rules: do not fabricate patient facts, do not provide final diagnosis claims without uncertainty language, and do not generate treatment dosage decisions autonomously. Recommend clinical verification steps and document assumptions clearly.";

const DEFAULT_MODEL = "gemini-2.5-flash";
const GEMINI_ENDPOINT_BASE = "https://generativelanguage.googleapis.com/v1beta/models";

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });
}

function getSystemPrompt(role: "patient" | "doctor"): string {
  return role === "doctor" ? DEFAULT_DOCTOR_PROMPT : DEFAULT_PATIENT_PROMPT;
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

    const basePrompt = getSystemPrompt(role);

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

    // Extend the triage result with a mutable object so we can attach doctor cards.
    const triageResultWithCards: Record<string, unknown> = { ...sanitized.triageResult };

    if (sanitized.triageResult.specialty.length > 0) {
      // Normalize Gemini specialty names to actual DB values.
      // Gemini often returns "Family Medicine", "General Practitioner", "PCP" etc.
      // but our DB uses "General Medicine", "Internal Medicine", "ENT", etc.
      const normalizeSpecialty = (s: string): string[] => {
        const lower = s.toLowerCase();
        if (lower.includes("family") || lower.includes("general pract") || lower.includes("primary care") || lower.includes("pcp")) {
          return ["General Medicine", "Internal Medicine"];
        }
        if (lower.includes("ent") || lower.includes("otolar") || lower.includes("ear") || lower.includes("throat")) {
          return ["ENT"];
        }
        if (lower.includes("gynae") || lower.includes("gyneco") || lower.includes("obstet") || lower.includes("ob/gyn")) {
          return ["Gynaecology & Obstetrics", "Obstetrics"];
        }
        if (lower.includes("ortho")) return ["Orthopedics"];
        if (lower.includes("cardio")) return ["Cardiology"];
        if (lower.includes("neuro")) return ["Neurology"];
        if (lower.includes("pediatr") || lower.includes("paediatr")) return ["Pediatrics"];
        if (lower.includes("derma") || lower.includes("skin")) return ["Dermatology"];
        if (lower.includes("ophthal") || lower.includes("eye")) return ["Ophthalmology"];
        if (lower.includes("radio")) return ["Radiology"];
        if (lower.includes("surg")) return ["General Surgery"];
        if (lower.includes("internal") || lower.includes("general med")) return ["General Medicine", "Internal Medicine"];
        // Return original as-is for other specialties
        return [s];
      };

      const specialtyTerms = normalizeSpecialty(sanitized.triageResult.specialty);

      // Try each normalized specialty term until we get results.
      let doctors: Record<string, unknown>[] | null = null;
      let doctorsError: unknown = null;

      for (const term of specialtyTerms) {
        const result = await supabase
          .from("doctors")
          .select(
            "id, specialty, rating, consultation_fee, profiles!doctors_profile_id_fkey(full_name), hospitals(name, city)",
          )
          .ilike("specialty", `%${term}%`)
          .eq("status", "approved")
          .order("rating", { ascending: false })
          .limit(5);

        doctorsError = result.error;
        if (!result.error && result.data && result.data.length > 0) {
          doctors = result.data as Record<string, unknown>[];
          break;
        }
      }

      // Fallback: if still no results, return top-rated approved doctors regardless of specialty.
      if (!doctorsError && (!doctors || doctors.length === 0)) {
        const fallback = await supabase
          .from("doctors")
          .select(
            "id, specialty, rating, consultation_fee, profiles!doctors_profile_id_fkey(full_name), hospitals(name, city)",
          )
          .eq("status", "approved")
          .order("rating", { ascending: false })
          .limit(5);

        if (!fallback.error && fallback.data && fallback.data.length > 0) {
          doctors = fallback.data as Record<string, unknown>[];
        }
      }

      if (doctors && doctors.length > 0) {
        sanitized.triageResult.suggested_doctors = doctors
          .map((d) => String(d.id ?? ""))
          .filter((id) => id.length > 0);

        triageResultWithCards["suggested_doctor_cards"] = doctors.map((d) => {
          const profile = d.profiles as Record<string, unknown> | null;
          const hospital = d.hospitals as Record<string, unknown> | null;
          return {
            id: d.id,
            name: profile?.full_name ?? "Unknown Doctor",
            specialty: d.specialty ?? sanitized.triageResult.specialty,
            hospital: hospital?.name ?? "",
            city: hospital?.city ?? "",
            fee: d.consultation_fee,
            rating: d.rating,
          };
        });
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
          triage_result_preview: triageResultWithCards,
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
