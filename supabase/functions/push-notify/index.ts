import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type WebhookPayload = {
  type?: string;
  table?: string;
  record?: Record<string, unknown>;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-webhook-secret",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const webhookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
    if (webhookSecret.length > 0) {
      const incomingSecret = req.headers.get("x-webhook-secret") ?? "";
      if (incomingSecret !== webhookSecret) {
        return new Response(JSON.stringify({ error: "Unauthorized webhook" }), {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    const body = (await req.json()) as WebhookPayload;
    const record = body.record ?? {};

    const chatId = (record["chatid"] ?? record["chatId"] ?? "") as string;
    const senderId = (record["senderid"] ?? record["senderId"] ?? "") as string;
    const senderName = (record["sendername"] ?? record["senderName"] ?? "Someone") as string;
    const messageText = (record["text"] as string | null) ?? "New message";

    if (chatId.length === 0 || senderId.length === 0) {
      return new Response(JSON.stringify({ skipped: true, reason: "Missing sender/chat context" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in function secrets");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: chat, error: chatError } = await supabase
      .from("chats")
      .select("participants")
      .eq("id", chatId)
      .maybeSingle();

    if (chatError) {
      throw chatError;
    }

    const participants = (chat?.participants ?? []) as string[];
    const recipientIds = participants.filter((id) => id !== senderId);
    if (recipientIds.length === 0) {
      return new Response(JSON.stringify({ sent: 0, reason: "No recipients" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: users, error: usersError } = await supabase
      .from("users")
      .select("id")
      .in("id", recipientIds);

    if (usersError) {
      throw usersError;
    }

    const recipients = (users ?? []).map((u) => u.id as string);
    if (recipients.length === 0) {
      return new Response(JSON.stringify({ created: 0, reason: "No recipients" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const notifications = recipients.map((recipientId) => ({
      recipient_id: recipientId,
      sender_id: senderId,
      chat_id: chatId,
      type: "new_message",
      title: senderName,
      body: messageText.length > 160 ? `${messageText.slice(0, 160)}...` : messageText,
      is_read: false,
    }));

    const { error: insertError } = await supabase
      .from("notifications")
      .insert(notifications);

    if (insertError) {
      throw insertError;
    }

    return new Response(JSON.stringify({ created: notifications.length, recipients }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
