# Notifications — Push Notification Implementation Guide

This document covers everything needed to add push notifications to Safar.
The in-app notification system (UI + DB) is already implemented. This guide
covers the iOS scaffolding and Supabase Edge Function needed to deliver
notifications to users' devices when a contact joins.

---

## Overview of What's Already Done

| Piece | Status |
|-------|--------|
| `notifications` table in Supabase | ✅ Done |
| `contact_hashes` table + reverse-lookup trigger | ✅ Done |
| `NotificationsView` (in-app feed) | ✅ Done |
| `NotificationsViewModel` | ✅ Done |
| Notifications tab in `HomeView` (red dot badge) | ✅ Done |

**Missing for push:** device token storage, iOS registration code, and the
`notify-contact-joined` Edge Function that reads tokens and fires APNs pushes.

---

## Step 1: Supabase — device_tokens Table

Run in Supabase SQL Editor:

```sql
CREATE TABLE device_tokens (
    id bigserial PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token text NOT NULL,
    platform text NOT NULL DEFAULT 'ios',
    updated_at timestamptz DEFAULT now(),
    UNIQUE(user_id)  -- one row per user; upsert replaces in place
);
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users manage own device tokens" ON device_tokens
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
```

---

## Step 2: DatabaseManager Extension — saveDeviceToken

Add to `Safar/Data/DatabaseManager.swift` (inside the Find Friends & Notifications extension):

```swift
private struct DeviceTokenUpsert: Encodable {
    let user_id: String
    let token: String
    let platform: String
    let updated_at: String
}

func saveDeviceToken(_ token: String) async throws {
    let currentUser = try await getCurrentUser()
    let payload = DeviceTokenUpsert(
        user_id: currentUser.id.uuidString,
        token: token,
        platform: "ios",
        updated_at: ISO8601DateFormatter().string(from: Date())
    )
    do {
        try await supabase
            .from("device_tokens")
            .upsert(payload, onConflict: "user_id")
            .execute()
    } catch {
        Log.data.error("saveDeviceToken failed: \(error)")
        throw DatabaseError.networkError("Failed to save device token: \(error.localizedDescription)")
    }
}
```

---

## Step 3: iOS — NotificationManager

Create `Safar/Data/NotificationManager.swift`:

```swift
//
//  NotificationManager.swift
//  Safar
//
import Foundation
import UserNotifications
import UIKit

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    /// Request alert/badge/sound permission. Returns whether the user granted it.
    func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, _ in
                cont.resume(returning: granted)
            }
        }
    }

    /// Must be called on MainActor. Triggers the APNs registration flow;
    /// the token is delivered to AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken.
    @MainActor
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
}
```

---

## Step 4: iOS — AppDelegate for Device Token Handling

Add an `AppDelegate` to `Safar/App/safarApp.swift`:

```swift
// AppDelegate — receives the APNs device token after registration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            try? await DatabaseManager.shared.saveDeviceToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Log.data.error("APNs registration failed: \(error)")
    }
}
```

Add the adaptor property to `safarApp`:

```swift
@main
struct safarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // ... rest of struct unchanged
```

---

## Step 5: iOS — Request Permission at the Right Time

The best moment to ask for push permission is contextually — after a user
takes an action that makes the value of notifications obvious. A good candidate
is a "Find Friends" screen accessible post-onboarding (e.g. from Profile or
Settings), or a standalone "Turn on notifications" prompt shown after the user
follows someone from the Find Friends step.

**Example — add to a future FindFriendsView (post-onboarding version):**

```swift
Button("Get notified when contacts join") {
    Task {
        let granted = await NotificationManager.shared.requestPermission()
        if granted {
            await NotificationManager.shared.registerForRemoteNotifications()
        }
    }
}
```

---

## Step 6: Supabase Edge Function — notify-contact-joined

Create `supabase/functions/notify-contact-joined/index.ts`.

This function is triggered by a Supabase **Database Webhook** on the
`profiles` table (INSERT and UPDATE on `phone_hash`).

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// APNs JWT signing using Deno Web Crypto (no external packages needed)
async function signApnsJwt(
  authKey: string,
  keyId: string,
  teamId: string
): Promise<string> {
  const header = { alg: "ES256", kid: keyId };
  const payload = { iss: teamId, iat: Math.floor(Date.now() / 1000) };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const message = `${encode(header)}.${encode(payload)}`;

  // Import the p8 private key
  const pemBody = authKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");
  const keyData = Uint8Array.from(atob(pemBody), c => c.charCodeAt(0));
  const privateKey = await crypto.subtle.importKey(
    "pkcs8", keyData.buffer,
    { name: "ECDSA", namedCurve: "P-256" },
    false, ["sign"]
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    privateKey,
    new TextEncoder().encode(message)
  );

  const sigBase64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  return `${message}.${sigBase64}`;
}

async function sendApnsPush(
  token: string,
  payload: object,
  jwt: string,
  bundleId: string,
  sandbox: boolean
) {
  const host = sandbox
    ? "https://api.sandbox.push.apple.com"
    : "https://api.push.apple.com";

  const res = await fetch(`${host}/3/device/${token}`, {
    method: "POST",
    headers: {
      "Authorization": `bearer ${jwt}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const body = await res.text();
    console.error(`APNs error for token ${token.slice(0, 8)}…: ${body}`);
  }
}

Deno.serve(async (req) => {
  try {
    const { record } = await req.json(); // webhook payload
    const newPhoneHash = record?.phone_hash;
    const actorId = record?.id;

    if (!newPhoneHash || !actorId) {
      return new Response("ok", { status: 200 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Find users who have this number in their contacts
    const { data: matches } = await supabase
      .from("contact_hashes")
      .select("user_id")
      .eq("contact_hash", newPhoneHash)
      .neq("user_id", actorId);

    if (!matches?.length) return new Response("ok", { status: 200 });

    // Get actor's display name
    const { data: actor } = await supabase
      .from("profiles")
      .select("full_name, username")
      .eq("id", actorId)
      .single();

    const actorName = actor?.full_name ?? actor?.username ?? "Someone you know";

    // Get device tokens for matched users
    const userIds = matches.map((m: { user_id: string }) => m.user_id);
    const { data: tokens } = await supabase
      .from("device_tokens")
      .select("user_id, token")
      .in("user_id", userIds);

    if (!tokens?.length) return new Response("ok", { status: 200 });

    // Sign APNs JWT (valid for 60 minutes — reuse across requests in production)
    const jwt = await signApnsJwt(
      Deno.env.get("APNS_AUTH_KEY")!,
      Deno.env.get("APNS_KEY_ID")!,
      Deno.env.get("APNS_TEAM_ID")!
    );

    const bundleId = Deno.env.get("APNS_BUNDLE_ID")!;
    const sandbox = Deno.env.get("APNS_SANDBOX") === "true";

    // Send push to each device
    await Promise.all(
      tokens.map(({ token }: { token: string }) =>
        sendApnsPush(
          token,
          {
            aps: {
              alert: {
                title: "New traveler on Safar!",
                body: `${actorName} just joined Safar`,
              },
              badge: 1,
              sound: "default",
            },
          },
          jwt,
          bundleId,
          sandbox
        )
      )
    );

    return new Response("ok", { status: 200 });
  } catch (err) {
    console.error("notify-contact-joined error:", err);
    return new Response("error", { status: 500 });
  }
});
```

---

## Step 7: Supabase — Database Webhook

In the Supabase Dashboard → **Database → Webhooks → Create new webhook**:

| Field | Value |
|-------|-------|
| Name | `on-phone-hash-saved` |
| Table | `profiles` |
| Events | `INSERT`, `UPDATE` |
| Type | Supabase Edge Function |
| Function | `notify-contact-joined` |

Filter condition (optional but recommended to avoid firing on unrelated updates):
```
phone_hash IS NOT NULL
```

---

## Step 8: Supabase — Edge Function Secrets

In Supabase Dashboard → **Edge Functions → Manage secrets**, add:

| Secret | Value |
|--------|-------|
| `APNS_AUTH_KEY` | Contents of your `.p8` file (from Apple Developer → Keys) |
| `APNS_KEY_ID` | The 10-character Key ID |
| `APNS_TEAM_ID` | Your Apple Team ID |
| `APNS_BUNDLE_ID` | `com.armankassam.safar` |
| `APNS_SANDBOX` | `true` for development, `false` for production |

The `.p8` key is generated in **Apple Developer → Certificates, Identifiers & Profiles → Keys → Create a new key** with APNs capability checked. Store it securely — Apple only lets you download it once.

---

## Testing

1. **Simulator:** `registerForRemoteNotifications()` will fail (expected) — `didFailToRegisterForRemoteNotificationsWithError` fires and logs, no crash.
2. **Real device:** After permission grant + registration, verify a row appears in `device_tokens` in Supabase.
3. **End-to-end:** 
   - Create user A, sync contacts (adds user B's hash to `contact_hashes`)
   - Create user B, add their phone number in onboarding (sets `phone_hash`)
   - Verify `notifications` table gets a `contact_joined` row for user A
   - If push is wired: verify user A's device receives the APNs notification
