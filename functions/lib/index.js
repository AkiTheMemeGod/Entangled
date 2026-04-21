"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onAuthUserCreate = exports.onNewMessage = void 0;
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const fcm = admin.messaging();
/**
 * Triggered whenever a new message document is created in:
 *   /chats/{chatId}/messages/{messageId}
 *
 * It looks up the recipient's FCM token from their user document
 * and sends them a push notification.
 */
exports.onNewMessage = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
    var _a, _b, _c;
    const message = snapshot.data();
    if (!message)
        return null;
    const { chatId } = context.params;
    const senderId = message.senderId;
    const senderName = (_a = message.senderName) !== null && _a !== void 0 ? _a : "Someone";
    const text = (_b = message.text) !== null && _b !== void 0 ? _b : "📷 Sent an image";
    // Get the chat document to find the other participant
    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists)
        return null;
    const chatData = chatDoc.data();
    const participants = (_c = chatData.participants) !== null && _c !== void 0 ? _c : [];
    // Find the recipient (anyone who isn't the sender)
    const recipientIds = participants.filter((uid) => uid !== senderId);
    if (recipientIds.length === 0)
        return null;
    // Send a notification to each recipient
    const sendPromises = recipientIds.map(async (recipientId) => {
        var _a, _b;
        // Fetch recipient's FCM token
        const userDoc = await db.collection("users").doc(recipientId).get();
        if (!userDoc.exists)
            return;
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        if (!fcmToken) {
            console.log(`No FCM token for user: ${recipientId}`);
            return;
        }
        // Check unread count — skip notification if recipient is actively reading (count already 0)
        // This is a simple heuristic; a more robust solution tracks online status
        const unreadCount = (_b = (_a = chatData.unreadCount) === null || _a === void 0 ? void 0 : _a[recipientId]) !== null && _b !== void 0 ? _b : 0;
        // We still send — the app handles suppressing if the chat is open
        const payload = {
            token: fcmToken,
            notification: {
                title: senderName,
                body: text.length > 100 ? text.substring(0, 100) + "…" : text,
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "entangled_messages",
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    sound: "default",
                },
            },
            data: {
                chatId: chatId,
                senderId: senderId,
                senderName: senderName,
                // Pass unreadCount so app can badge
                unreadCount: String(unreadCount + 1),
                // Type used by Flutter to route the notification tap
                type: "new_message",
            },
        };
        try {
            await fcm.send(payload);
            console.log(`Notification sent to ${recipientId}`);
        }
        catch (err) {
            const error = err;
            // Clean up stale tokens
            if (error.code === "messaging/registration-token-not-registered" ||
                error.code === "messaging/invalid-registration-token") {
                console.warn(`Stale FCM token for ${recipientId}, removing...`);
                await db.collection("users").doc(recipientId).update({ fcmToken: admin.firestore.FieldValue.delete() });
            }
            else {
                console.error(`Failed to send notification to ${recipientId}:`, err);
            }
        }
    });
    return Promise.all(sendPromises);
});
/**
 * Create a Firestore profile document whenever a user signs up in Firebase Auth.
 * This keeps /users in sync even if the client write is delayed or denied.
 */
exports.onAuthUserCreate = functions.auth.user().onCreate(async (user) => {
    var _a, _b, _c, _d, _e;
    const now = admin.firestore.Timestamp.fromDate(new Date());
    const displayName = (_c = (_a = user.displayName) !== null && _a !== void 0 ? _a : (_b = user.email) === null || _b === void 0 ? void 0 : _b.split("@")[0]) !== null && _c !== void 0 ? _c : "User";
    await db.collection("users").doc(user.uid).set({
        uid: user.uid,
        email: ((_d = user.email) !== null && _d !== void 0 ? _d : "").trim().toLowerCase(),
        displayName,
        photoUrl: (_e = user.photoURL) !== null && _e !== void 0 ? _e : null,
        lastSeen: now,
        isOnline: true,
        createdAt: now,
    }, { merge: true });
});
//# sourceMappingURL=index.js.map