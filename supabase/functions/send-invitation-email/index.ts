import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      { ok: false, message: "Metodo non consentito." },
      405,
    );
  }

  try {
    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const resendApiKey = Deno.env.get("RESEND_API_KEY") ?? "";
    const fromEmail =
      Deno.env.get("INVITATION_FROM_EMAIL") ??
      "ClubManager Sport <onboarding@resend.dev>";
    const inviteBaseUrl =
      Deno.env.get("APP_INVITE_BASE_URL") ?? "clubmanager-sport://invite";

    if (resendApiKey.trim().length === 0) {
      return jsonResponse(
        {
          ok: false,
          message:
            "Provider email non configurato. Imposta RESEND_API_KEY nei secrets Supabase.",
        },
        500,
      );
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "").trim();

    if (jwt.length === 0) {
      return jsonResponse(
        { ok: false, message: "Utente non autenticato." },
        401,
      );
    }

    const body = await req.json().catch(() => ({}));
    const invitationId = String(body.invitation_id ?? "").trim();

    if (invitationId.length === 0) {
      return jsonResponse(
        { ok: false, message: "Invito non valido." },
        400,
      );
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const { data: authUser, error: authError } =
      await adminClient.auth.getUser(jwt);

    if (authError || !authUser.user) {
      return jsonResponse(
        { ok: false, message: "Sessione non valida." },
        401,
      );
    }

    const userId = authUser.user.id;

    const { data: invitation, error: invitationError } = await adminClient
      .from("invitations")
      .select(
        "id, club_id, team_id, email, role, token, status, expires_at, email_send_attempts, teams(name)",
      )
      .eq("id", invitationId)
      .maybeSingle();

    if (invitationError) {
      throw invitationError;
    }

    if (!invitation) {
      return jsonResponse(
        { ok: false, message: "Invito non trovato." },
        404,
      );
    }

    if (invitation.status !== "sent") {
      return jsonResponse(
        { ok: false, message: "Solo gli inviti inviati possono essere spediti via email." },
        409,
      );
    }

    const expiresAt = new Date(invitation.expires_at);

    if (Number.isNaN(expiresAt.getTime()) || expiresAt.getTime() < Date.now()) {
      return jsonResponse(
        { ok: false, message: "Invito scaduto." },
        409,
      );
    }

    const { data: membership, error: membershipError } = await adminClient
      .from("club_memberships")
      .select("role, status")
      .eq("club_id", invitation.club_id)
      .eq("user_id", userId)
      .eq("status", "active")
      .maybeSingle();

    if (membershipError) {
      throw membershipError;
    }

    const canSendInviteEmail =
      membership?.role === "owner" || membership?.role === "admin";

    if (!canSendInviteEmail) {
      return jsonResponse(
        {
          ok: false,
          message:
            "Solo proprietario o amministratore del club può inviare email di invito.",
        },
        403,
      );
    }

    const { data: club, error: clubError } = await adminClient
      .from("clubs")
      .select("name, sport_primary, city")
      .eq("id", invitation.club_id)
      .maybeSingle();

    if (clubError) {
      throw clubError;
    }

    const clubName = club?.name ?? "il club";
    const teamName = invitation.teams?.name ?? "";
    const inviteUrl = buildInviteUrl(inviteBaseUrl, invitation.token);
    const roleLabel = roleLabelFor(invitation.role);

    const subject = `Invito a ${clubName} su ClubManager Sport`;

    const text = [
      `Hai ricevuto un invito per accedere a ${clubName} su ClubManager Sport.`,
      "",
      `Ruolo: ${roleLabel}`,
      teamName.length > 0 ? `Squadra: ${teamName}` : "",
      "",
      `Apri questo link per completare l'accesso:`,
      inviteUrl,
      "",
      `Codice invito: ${invitation.token}`,
      "",
      `L'invito scade il ${formatDate(expiresAt)}.`,
    ]
      .filter((line) => line !== "")
      .join("\n");

    const html = `
      <div style="font-family: Arial, sans-serif; color: #102A43; line-height: 1.5;">
        <h2 style="margin-bottom: 8px;">Invito a ${escapeHtml(clubName)}</h2>
        <p>Hai ricevuto un invito per accedere a <strong>${escapeHtml(clubName)}</strong> su ClubManager Sport.</p>
        <p><strong>Ruolo:</strong> ${escapeHtml(roleLabel)}</p>
        ${
          teamName.length > 0
            ? `<p><strong>Squadra:</strong> ${escapeHtml(teamName)}</p>`
            : ""
        }
        <p style="margin: 24px 0;">
          <a href="${escapeAttribute(inviteUrl)}"
             style="background:#176B87;color:#ffffff;padding:12px 18px;border-radius:10px;text-decoration:none;display:inline-block;">
            Accetta invito
          </a>
        </p>
        <p>Se il pulsante non funziona, copia e incolla questo link:</p>
        <p style="word-break: break-all;">${escapeHtml(inviteUrl)}</p>
        <p><strong>Codice invito:</strong></p>
        <p style="font-family: monospace; word-break: break-all;">${escapeHtml(invitation.token)}</p>
        <p>L'invito scade il ${escapeHtml(formatDate(expiresAt))}.</p>
      </div>
    `;

    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [invitation.email],
        subject,
        html,
        text,
      }),
    });

    const resendBody = await resendResponse.text();
    const nextAttempts = Number(invitation.email_send_attempts ?? 0) + 1;

    if (!resendResponse.ok) {
      await adminClient
        .from("invitations")
        .update({
          email_send_attempts: nextAttempts,
          email_last_error: resendBody.slice(0, 1000),
        })
        .eq("id", invitation.id);

      return jsonResponse(
        {
          ok: false,
          message: "Invio email non riuscito.",
          provider_response: resendBody,
        },
        502,
      );
    }

    await adminClient
      .from("invitations")
      .update({
        email_sent_at: new Date().toISOString(),
        email_send_attempts: nextAttempts,
        email_last_error: null,
      })
      .eq("id", invitation.id);

    return jsonResponse({
      ok: true,
      message: "Email invito inviata.",
      invitation_url: inviteUrl,
    });
  } catch (error) {
    console.error(error);

    return jsonResponse(
      {
        ok: false,
        message: "Errore imprevisto durante l'invio email.",
      },
      500,
    );
  }
});

function jsonResponse(payload: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);

  if (!value) {
    throw new Error(`Missing environment variable: ${name}`);
  }

  return value;
}

function buildInviteUrl(baseUrl: string, token: string) {
  const cleanBase = baseUrl.trim().replace(/\/+$/, "");
  const encodedToken = encodeURIComponent(token);

  if (cleanBase.endsWith("/invite")) {
    return `${cleanBase}/${encodedToken}`;
  }

  return `${cleanBase}/invite/${encodedToken}`;
}

function roleLabelFor(role: string) {
  switch (role) {
    case "owner":
      return "Proprietario";
    case "admin":
      return "Admin club";
    case "team_manager":
      return "Manager squadra";
    case "coach":
      return "Allenatore";
    case "staff":
      return "Staff";
    case "athlete":
      return "Atleta";
    case "parent":
      return "Genitore/Tutore";
    default:
      return role;
  }
}

function formatDate(value: Date) {
  return new Intl.DateTimeFormat("it-IT", {
    dateStyle: "medium",
    timeStyle: "short",
    timeZone: "Europe/Rome",
  }).format(value);
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function escapeAttribute(value: string) {
  return escapeHtml(value);
}