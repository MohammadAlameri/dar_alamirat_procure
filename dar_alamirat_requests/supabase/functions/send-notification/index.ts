// deno-lint-ignore-file
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { encode as base64url } from "https://deno.land/std@0.168.0/encoding/base64url.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Firebase project ID from google-services.json
const FIREBASE_PROJECT_ID = "dar-alamirat-employee";

// Service account credentials (set via supabase secrets)
const SERVICE_ACCOUNT_EMAIL = Deno.env.get("FCM_SERVICE_ACCOUNT_EMAIL")!;
const SERVICE_ACCOUNT_PRIVATE_KEY = Deno.env.get("FCM_SERVICE_ACCOUNT_PRIVATE_KEY")!;

interface NotificationPayload {
  user_ids: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  if (!pem) {
    throw new Error("FCM_SERVICE_ACCOUNT_PRIVATE_KEY environment variable is not set");
  }

  // Aggressive cleaning: 
  // 1. Remove PEM headers and footers
  // 2. Remove any literal "\n" strings that might be in the env var
  // 3. Remove EVERY character that is not a valid base64 character (A-Z, a-z, 0-9, +, /, =)
  const base64Data = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\\n/g, "") // remove literal \n strings
    .replace(/[^A-Za-z0-9+/=]/g, ""); // remove all non-base64 chars (including spaces, actual newlines, quotes, etc.)

  try {
    const binaryDer = Uint8Array.from(atob(base64Data), (c) => c.charCodeAt(0));

    return await crypto.subtle.importKey(
      "pkcs8",
      binaryDer,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"]
    );
  } catch (err) {
    console.error("Failed to decode FCM_SERVICE_ACCOUNT_PRIVATE_KEY aggressive cleaning failed.");
    throw new Error(`Invalid private key format: ${err}`);
  }
}

/**
 * Create a signed JWT for Google OAuth2 token exchange.
 */
async function createSignedJwt(
  email: string,
  privateKey: CryptoKey
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600, // 1 hour
  };

  const textEncoder = new TextEncoder();
  const headerB64 = base64url(textEncoder.encode(JSON.stringify(header)));
  const payloadB64 = base64url(textEncoder.encode(JSON.stringify(payload)));

  const unsignedToken = `${headerB64}.${payloadB64}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    textEncoder.encode(unsignedToken)
  );

  const signatureB64 = base64url(new Uint8Array(signature));
  return `${unsignedToken}.${signatureB64}`;
}

/**
 * Get an OAuth2 access token using a service account JWT.
 */
async function getAccessToken(): Promise<string> {
  const privateKey = await importPrivateKey(SERVICE_ACCOUNT_PRIVATE_KEY);
  const jwt = await createSignedJwt(SERVICE_ACCOUNT_EMAIL, privateKey);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await response.json();
  if (!data.access_token) {
    console.error("Failed to get access token:", data);
    throw new Error("Failed to get access token");
  }

  return data.access_token;
}

/**
 * Send a notification to a single FCM token using FCM v1 API.
 */
async function sendFcmMessage(
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<{ success: boolean; error?: string }> {
  try {
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data: data || {},
            android: {
              priority: "HIGH",
              notification: {
                channel_id: "dar_alamirat_notifications",
                sound: "default",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                },
              },
            },
          },
        }),
      }
    );

    if (response.ok) {
      return { success: true };
    }

    const errorData = await response.json();
    const errorCode = errorData?.error?.details?.[0]?.errorCode;

    // Token is invalid or unregistered
    if (
      errorCode === "UNREGISTERED" ||
      errorCode === "INVALID_ARGUMENT" ||
      response.status === 404
    ) {
      return { success: false, error: "INVALID_TOKEN" };
    }

    console.error(`FCM error for token ${token.substring(0, 20)}...:`, errorData);
    return { success: false, error: JSON.stringify(errorData) };
  } catch (err) {
    console.error(`Network error sending to ${token.substring(0, 20)}...:`, err);
    return { success: false, error: String(err) };
  }
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload: NotificationPayload = await req.json();
    const { user_ids, branch_id, role, roles, title, body, data } = payload;

    // Create Supabase client with service role (bypasses RLS)
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    let targetUserIds: string[] = user_ids || [];

    // If no specific user IDs, find users by branch and role
    if (targetUserIds.length === 0 && branch_id) {
      console.log(`Finding users for branch ${branch_id} with role ${role || roles}`);
      
      let query = supabase
        .from('user_branches')
        .select('user_id, profiles!inner(role)')
        .eq('branch_id', branch_id);

      if (role) {
        query = query.eq('profiles.role', role);
      } else if (roles && roles.length > 0) {
        query = query.in('profiles.role', roles);
      }

      const { data: branchUsers, error: branchError } = await query;

      if (branchError) {
        console.error("Error fetching branch users:", branchError);
      } else if (branchUsers) {
        targetUserIds = branchUsers.map((u: any) => u.user_id);
      }

      // If it's a central role and still no users found, search profiles globally
      const centralRoles = ['finance', 'it_procurement', 'general_manager', 'accountant', 'admin'];
      const targetRoles = roles || (role ? [role] : []);
      const hasCentralRole = targetRoles.some(r => centralRoles.includes(r));

      if (targetUserIds.length === 0 && hasCentralRole) {
        console.log("No branch users found, searching globally for roles:", targetRoles);
        const { data: globalUsers, error: globalError } = await supabase
          .from('profiles')
          .select('id')
          .in('role', targetRoles);
        
        if (globalError) {
          console.error("Error fetching global users:", globalError);
        } else if (globalUsers) {
          targetUserIds = globalUsers.map((u: any) => u.id);
        }
      }
    }

    if (targetUserIds.length === 0) {
      console.log("No target users found for notification");
      return new Response(
        JSON.stringify({ message: "No target users found", sent: 0 }),
        { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Remove duplicates
    targetUserIds = [...new Set(targetUserIds)];
    console.log(`Target users: ${targetUserIds}`);

    // Fetch FCM tokens for the target users
    const { data: tokenRecords, error } = await supabase
      .from("fcm_tokens")
      .select("token")
      .in("user_id", targetUserIds);

    if (error) {
      console.error("Error fetching tokens:", error);
      return new Response(
        JSON.stringify({ error: "Failed to fetch tokens" }),
        { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    if (!tokenRecords || tokenRecords.length === 0) {
      console.log("No FCM tokens found for users:", targetUserIds);
      return new Response(
        JSON.stringify({ message: "No tokens found", sent: 0 }),
        { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const tokens = tokenRecords.map((r: { token: string }) => r.token);
    console.log(`Sending notification to ${tokens.length} devices`);

    // Get OAuth2 access token
    const accessToken = await getAccessToken();

    // Send to each device
    const results = await Promise.allSettled(
      tokens.map(async (token: string) => {
        const result = await sendFcmMessage(accessToken, token, title, body, data);

        // Remove invalid tokens from database
        if (!result.success && result.error === "INVALID_TOKEN") {
          console.log(`Removing invalid token: ${token.substring(0, 20)}...`);
          await supabase.from("fcm_tokens").delete().eq("token", token);
        }

        return result;
      })
    );

    const successCount = results.filter(
      (r) => r.status === "fulfilled" && (r.value as any).success
    ).length;

    return new Response(
      JSON.stringify({
        message: "Notifications processed",
        sent: successCount,
        total: tokens.length,
      }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  } catch (err) {
    console.error("Error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }
});


