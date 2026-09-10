/**
 * Khushi Dua — Cloud Functions
 *
 * Purpose: send FCM push notifications WITHOUT ever putting a service-account
 * private key in the admin panel's JavaScript bundle.
 *
 * The function runs on Google's servers using the runtime's own service
 * identity, so no credentials are shipped to the browser. Every call is gated
 * on the caller being a real admin (a signed-in user with a doc in
 * /Management/{uid}), which mirrors firestore.rules isAdmin().
 */

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({region: "us-central1", maxInstances: 10});

const db = admin.firestore();
const messaging = admin.messaging();

/** Throws unless the caller is signed in and listed in /Management. */
async function assertAdmin(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in as an admin first.");
  }
  const doc = await db.collection("Management").doc(uid).get();
  if (!doc.exists) {
    throw new HttpsError("permission-denied", "Not an admin account.");
  }
  return uid;
}

/** Trim, require a non-empty string, and cap length. */
function requireText(value, field, max) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  const text = value.trim();
  if (text.length > max) {
    throw new HttpsError("invalid-argument", `${field} exceeds ${max} chars.`);
  }
  return text;
}

/**
 * Send to every user that has an FCM token, then record one Notifications doc.
 * Data: { title, message }
 */
exports.sendGlobalNotification = onCall(async (request) => {
  await assertAdmin(request);

  const title = requireText(request.data.title, "title", 200);
  const message = requireText(request.data.message, "message", 1000);

  const notificationId = db.collection("Notifications").doc().id;

  // Collect tokens. Deduplicated, because a reinstall can leave stale copies.
  const usersSnap = await db.collection("Users").get();
  const tokens = [
    ...new Set(
        usersSnap.docs
            .map((d) => d.get("fcmToken"))
            .filter((t) => typeof t === "string" && t.length > 0),
    ),
  ];

  let successCount = 0;
  let failureCount = 0;
  const staleTokens = [];

  // sendEachForMulticast caps at 500 tokens per call.
  for (let i = 0; i < tokens.length; i += 500) {
    const batch = tokens.slice(i, i + 500);
    const response = await messaging.sendEachForMulticast({
      tokens: batch,
      notification: {title, body: message},
      data: {notificationId},
    });
    successCount += response.successCount;
    failureCount += response.failureCount;

    response.responses.forEach((result, index) => {
      if (result.success) return;
      const code = result.error && result.error.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token" ||
        code === "messaging/invalid-argument"
      ) {
        staleTokens.push(batch[index]);
      }
    });
  }

  await db.collection("Notifications").doc(notificationId).set({
    id: notificationId,
    title,
    message,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    sentTo: null,
  });

  await clearStaleTokens(staleTokens);

  return {
    notificationId,
    recipients: tokens.length,
    successCount,
    failureCount,
    staleTokensCleared: staleTokens.length,
  };
});

/**
 * Send to one user and record a targeted Notifications doc.
 * Data: { userId, title, message }
 */
exports.sendIndividualNotification = onCall(async (request) => {
  await assertAdmin(request);

  const userId = requireText(request.data.userId, "userId", 200);
  const title = requireText(request.data.title, "title", 200);
  const message = requireText(request.data.message, "message", 1000);

  const userSnap = await db.collection("Users").doc(userId).get();
  if (!userSnap.exists) {
    throw new HttpsError("not-found", "No such user.");
  }

  const token = userSnap.get("fcmToken");
  const notificationId = db.collection("Notifications").doc().id;

  let delivered = false;
  if (typeof token === "string" && token.length > 0) {
    try {
      await messaging.send({
        token,
        notification: {title, body: message},
        data: {notificationId},
      });
      delivered = true;
    } catch (error) {
      const code = error && error.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token" ||
        code === "messaging/invalid-argument"
      ) {
        await clearStaleTokens([token]);
      } else {
        throw new HttpsError("internal", `FCM send failed: ${code}`);
      }
    }
  }

  // The in-app inbox entry is written whether or not push reached the device,
  // so the user still sees the message next time they open the app.
  await db.collection("Notifications").doc(notificationId).set({
    id: notificationId,
    title,
    message,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    sentTo: userId,
  });

  return {notificationId, delivered};
});

/** Blank out tokens FCM rejected, so they aren't retried forever. */
async function clearStaleTokens(tokens) {
  if (tokens.length === 0) return;

  const unique = [...new Set(tokens)];
  for (let i = 0; i < unique.length; i += 10) {
    const chunk = unique.slice(i, i + 10);
    const snap = await db
        .collection("Users")
        .where("fcmToken", "in", chunk)
        .get();
    if (snap.empty) continue;

    const batch = db.batch();
    snap.docs.forEach((doc) => batch.update(doc.ref, {fcmToken: ""}));
    await batch.commit();
  }
}
