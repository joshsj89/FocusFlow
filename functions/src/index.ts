import {onSchedule} from "firebase-functions/v2/scheduler";
import {logger} from "firebase-functions/v2";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

initializeApp();

const TIMEZONE = "America/Los_Angeles";

function dateString(tz: string, offsetDays = 0): string {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + offsetDays);
  // en-CA gives YYYY-MM-DD, matching StreakModel.fmt on the client.
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: tz,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(d);
}

export const streakReminderNudge = onSchedule(
  {
    schedule: "0 20 * * *", // 8pm daily
    timeZone: TIMEZONE,
    region: "us-central1",
  },
  async () => {
    const db = getFirestore();
    const messaging = getMessaging();
    const today = dateString(TIMEZONE, 0);
    const yesterday = dateString(TIMEZONE, -1);

    const streaksSnap = await db.collection("streaks").get();
    let candidates = 0;
    let delivered = 0;

    for (const streakDoc of streaksSnap.docs) {
      const activeDays: string[] = streakDoc.data().activeDays ?? [];
      if (activeDays.includes(today)) continue;
      // Streak is already broken no nudge.
      if (!activeDays.includes(yesterday)) continue;

      candidates++;
      const uid = streakDoc.id;
      const userRef = db.collection("users").doc(uid);
      const userSnap = await userRef.get();
      const tokens: string[] = userSnap.get("fcmTokens") ?? [];
      if (tokens.length === 0) continue;

      const response = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "Keep your streak alive",
          body: "You haven't sat today — a quick session keeps it going.",
        },
        data: {type: "streak_reminder"},
      });

      delivered += response.successCount;

      const stale: string[] = [];
      response.responses.forEach((r, i) => {
        if (r.success) return;
        const code = r.error?.code ?? "";
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          stale.push(tokens[i]);
        }
      });
      if (stale.length > 0) {
        await userRef.update({fcmTokens: FieldValue.arrayRemove(...stale)});
      }
    }

    logger.info("Streak reminders run complete", {
      today,
      yesterday,
      candidates,
      delivered,
    });
  }
);
