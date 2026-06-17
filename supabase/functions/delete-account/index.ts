// delete-account — Supabase Edge Function
//
// Permanently deletes the calling user's account and associated data.
// Required by App Store Review Guideline 5.1.1(v): apps that let users create
// an account must let them delete it from within the app.
//
// The iOS app calls this via `supabase.functions.invoke("delete-account")`,
// which forwards the user's access token in the Authorization header. We verify
// that token to identify the user, then use the service-role key to delete their
// rows and the auth user itself.
//
// Deploy:   supabase functions deploy delete-account
// Secrets:  SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY are
//           injected automatically by the Supabase runtime — no manual setup needed.

import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "Missing authorization header" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return json({ error: "Server is not configured" }, 500);
  }

  // Identify the caller from their JWT.
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const {
    data: { user },
    error: userErr,
  } = await userClient.auth.getUser();

  if (userErr || !user) {
    return json({ error: "Invalid or expired session" }, 401);
  }

  // Admin client (service role) to remove data and the auth user.
  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Remove app data first. If you add more user-owned tables (food_logs,
  // workout_sessions, water_logs, …), delete them here too — or rely on
  // ON DELETE CASCADE foreign keys to auth.users.
  await admin.from("goals").delete().eq("user_id", user.id);
  await admin.from("profiles").delete().eq("id", user.id);

  const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
  if (delErr) {
    return json({ error: delErr.message }, 500);
  }

  return json({ success: true }, 200);
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
