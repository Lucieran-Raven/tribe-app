import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const oneSignalRestKey = defineSecret("ONESIGNAL_REST_API_KEY");
const ONE_SIGNAL_APP_ID = "e98051a2-ef46-43f2-bf9d-90e2f9180263";

function requireAuth(request: any): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Authentication required.");
  return uid;
}

function requireSuperAdmin(request: any): string {
  const uid = requireAuth(request);
  if (request.auth.token.superAdmin !== true) {
    throw new HttpsError("permission-denied", "Super Admin access required.");
  }
  return uid;
}

async function sendOneSignal(title: string, body: string, data: Record<string, unknown>, playerIds: string[]) {
  if (!playerIds.length) return;
  const response = await fetch("https://api.onesignal.com/notifications", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Basic ${oneSignalRestKey.value()}`,
    },
    body: JSON.stringify({
      app_id: ONE_SIGNAL_APP_ID,
      include_player_ids: playerIds.slice(0, 2000),
      headings: { en: title },
      contents: { en: body },
      small_icon: "ic_notification",
      data,
    }),
  });
  if (!response.ok) throw new Error(`OneSignal error ${response.status}`);
}

export const moderatePost = onCall(async (request) => {
  requireSuperAdmin(request);
  const rantId = String(request.data?.rantId ?? "");
  if (!rantId) throw new HttpsError("invalid-argument", "rantId is required.");
  const ref = db.collection("rants").doc(rantId);
  const snap = await ref.get();
  if (!snap.exists) return { deleted: false };
  await ref.update({ isVisible: false, moderatedAt: admin.firestore.FieldValue.serverTimestamp(), moderatedBy: request.auth!.uid });
  return { deleted: false, hidden: true };
});

export const deletePost = onCall(async (request) => {
  const adminUid = requireSuperAdmin(request);
  const rantId = String(request.data?.rantId ?? "");
  if (!rantId) throw new HttpsError("invalid-argument", "rantId is required.");
  const rantRef = db.collection("rants").doc(rantId);
  const rant = await rantRef.get();
  if (!rant.exists) return { deleted: false };

  const replies = await rantRef.collection("replies").get();
  const votes = await rantRef.collection("votes").get();
  const batch = db.batch();
  [...replies.docs, ...votes.docs].forEach((d) => batch.delete(d.ref));
  batch.delete(rantRef);
  await batch.commit();

  await db.collection("moderationHistory").add({
    action: "deletePost", targetId: rantId, actorId: adminUid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { deleted: true };
});

export const deleteReply = onCall(async (request) => {
  const adminUid = requireSuperAdmin(request);
  const rantId = String(request.data?.rantId ?? "");
  const replyId = String(request.data?.replyId ?? "");
  if (!rantId || !replyId) throw new HttpsError("invalid-argument", "rantId and replyId are required.");
  const ref = db.collection("rants").doc(rantId).collection("replies").doc(replyId);
  if (!(await ref.get()).exists) return { deleted: false };
  await ref.delete();
  await db.collection("rants").doc(rantId).update({ replyCount: admin.firestore.FieldValue.increment(-1) });
  await db.collection("moderationHistory").add({
    action: "deleteReply", targetId: replyId, parentId: rantId, actorId: adminUid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { deleted: true };
});

export const banUser = onCall(async (request) => {
  const adminUid = requireSuperAdmin(request);
  const userId = String(request.data?.userId ?? "");
  const banned = request.data?.banned === true;
  if (!userId || userId === adminUid) throw new HttpsError("invalid-argument", "Invalid user.");
  await admin.auth().updateUser(userId, { disabled: banned });
  await db.collection("users").doc(userId).set({
    isBanned: banned,
    moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
    moderatedBy: adminUid,
  }, { merge: true });
  await db.collection("moderationHistory").add({
    action: banned ? "banUser" : "unbanUser", targetId: userId, actorId: adminUid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { banned };
});

export const createAnnouncement = onCall({ secrets: [oneSignalRestKey] }, async (request) => {
  const adminUid = requireSuperAdmin(request);
  const title = String(request.data?.title ?? "").trim();
  const body = String(request.data?.body ?? "").trim();
  if (!title || !body) throw new HttpsError("invalid-argument", "Title and body are required.");

  const ref = db.collection("announcements").doc();
  await ref.set({
    announcementId: ref.id, type: "announcement", title, body,
    createdBy: adminUid, timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  const users = await db.collection("users").select("oneSignalPlayerId").get();
  const ids = users.docs.map(d => String(d.data().oneSignalPlayerId ?? "")).filter(Boolean);
  for (let i = 0; i < ids.length; i += 2000) {
    await sendOneSignal(title, body, { type: "announcement", announcementId: ref.id }, ids.slice(i, i + 2000));
  }
  await db.collection("moderationHistory").add({
    action: "announcement", targetId: ref.id, actorId: adminUid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { announcementId: ref.id };
});

export const setSuperAdmin = onCall(async (request) => {
  const uid = requireAuth(request);
  const bootstrapUid = process.env.SUPER_ADMIN_UID;
  if (!bootstrapUid || uid !== bootstrapUid) {
    throw new HttpsError("permission-denied", "Bootstrap authorization failed.");
  }
  await admin.auth().setCustomUserClaims(uid, { superAdmin: true });
  return { superAdmin: true };
});

export const getAdminData = onCall(async (request) => {
  requireSuperAdmin(request);
  const [users, reports, history] = await Promise.all([
    db.collection("users").select("handle", "displayName", "email", "isBanned", "createdAt").limit(100).get(),
    db.collection("reports").orderBy("timestamp", "desc").limit(100).get().catch(() => ({ docs: [] as any[] })),
    db.collection("moderationHistory").orderBy("timestamp", "desc").limit(100).get().catch(() => ({ docs: [] as any[] })),
  ]);
  return {
    users: users.docs.map(d => ({ id: d.id, ...d.data() })),
    reports: reports.docs.map(d => ({ id: d.id, ...d.data() })),
    history: history.docs.map(d => ({ id: d.id, ...d.data() })),
  };
});
