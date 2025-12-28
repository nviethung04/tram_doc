require('dotenv').config();
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const FormData = require('form-data');


admin.initializeApp();
const db = admin.firestore();

/**
 * OCR.space API Configuration
 * ✅ Dùng process.env (chuẩn mới, không deprecated)
 */
const OCR_SPACE_API_KEY = process.env.OCRSPACE_API_KEY;
const OCR_SPACE_API_URL = 'https://api.ocr.space/parse/image';

/**
 * ============================
 * DAILY FLASHCARD REMINDER
 * ============================
 */
exports.sendDailyFlashcardReminder = functions.pubsub
    .schedule('0 8 * * *')
    .timeZone('Asia/Ho_Chi_Minh')
    .onRun(async () => {
      try {
        const usersSnapshot = await db
            .collection('users')
            .where('pushToken', '!=', null)
            .get();

        const notifications = [];

        for (const userDoc of usersSnapshot.docs) {
          const user = userDoc.data();
          const userId = userDoc.id;

          const now = admin.firestore.Timestamp.now();
          const flashcardsSnapshot = await db
              .collection('flashcards')
              .where('userId', '==', userId)
              .where('status', '==', 'due')
              .where('dueAt', '<=', now)
              .get();

          const dueCount = flashcardsSnapshot.size;

          if (dueCount > 0 && user.pushToken) {
            notifications.push({
              token: user.pushToken,
              notification: {
                title: 'Flashcards đến hạn ôn tập',
                body: `Bạn có ${dueCount} flashcard cần ôn tập hôm nay`,
              },
              data: {
                type: 'flashcard_reminder',
                count: dueCount.toString(),
              },
            });
          }
        }

        if (notifications.length > 0) {
          await admin.messaging().sendAll(notifications);
        }
        return null;
      } catch (error) {
        console.error('Daily reminder error:', error);
        return null;
      }
    });

/**
 * ============================
 * CLEAN OCR TEXT
 * ============================
 */
function cleanOCRText(text) {
  if (!text || typeof text !== 'string') return '';

  let cleaned = text.replace(/\s+/g, ' ');

  cleaned = cleaned
      .split('\n')
      .map((l) => l.trim())
      .filter((l) => l.length > 1)
      .join('\n');

  cleaned = cleaned
      .replace(/\s+([.,!?;:])/g, '$1')
      .replace(/\n{3,}/g, '\n\n');

  return cleaned.trim();
}

/**
 * ============================
 * OCR FUNCTION (VIETNAMESE OK)
 * ============================
 */
exports.performOCR = functions
    .region('asia-southeast1')
    .https.onCall(async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'Yêu cầu đăng nhập',
        );
      }

      if (!OCR_SPACE_API_KEY) {
        throw new functions.https.HttpsError(
            'internal',
            'Thiếu OCR API key',
        );
      }

      const {imageBase64, language = 'vnm'} = data;
      if (!imageBase64) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Thiếu imageBase64',
        );
      }

      // Validate language - only allow valid OCR.space language codes (3-letter codes)
      // According to OCR.space docs: Vietnamese=vnm, English=eng, Chinese(Simplified)=chs, etc.
      const validLanguages = ['vnm', 'eng', 'fre', 'ger', 'spa', 'por', 'chs', 'cht', 'jpn', 'kor', 'auto'];
      const ocrLanguage = validLanguages.includes(language) ? language : 'vnm';

      try {
        const base64WithPrefix = imageBase64.startsWith('data:') ?
         imageBase64 :
         `data:image/jpeg;base64,${imageBase64}`;

        const formData = new FormData();
        formData.append('apikey', OCR_SPACE_API_KEY);
        formData.append('language', ocrLanguage);
        formData.append('isOverlayRequired', 'false');
        formData.append('detectOrientation', 'true');
        formData.append('scale', 'true');

        // Use Engine 2 for all languages (Engine 2 has better support for Vietnamese)
        // According to OCR.space docs, Engine 2 supports Vietnamese and auto-detection
        formData.append('OCREngine', '2');

        formData.append('base64Image', base64WithPrefix);

        const response = await axios.post(OCR_SPACE_API_URL, formData, {
          headers: formData.getHeaders(),
          timeout: 30000,
        });

        if (
          response.data?.ParsedResults &&
        response.data.ParsedResults.length > 0
        ) {
          let text = response.data.ParsedResults[0].ParsedText || '';
          text = cleanOCRText(text);

          if (!text) {
            return {success: false, error: 'Không nhận diện được văn bản'};
          }

          return {
            success: true,
            text,
            confidence: 0.85,
          };
        }

        if (response.data?.ErrorMessage) {
          return {
            success: false,
            error: response.data.ErrorMessage.join(', '),
          };
        }

        return {success: false, error: 'Phản hồi OCR không hợp lệ'};
      } catch (err) {
        console.error('OCR error:', err);
        return {
          success: false,
          error: err.message || 'OCR thất bại',
        };
      }
    });

/**
 * ============================
 * KEY IDEAS EXTRACTION
 * ============================
 */
exports.extractKeyIdeas = functions
    .region('asia-southeast1')
    .https.onCall(async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'Yêu cầu đăng nhập',
        );
      }

      const {text, maxIdeas = 5} = data;
      if (!text) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Thiếu văn bản',
        );
      }

      const sentences = text
          .split(/[.!?]\s+/)
          .map((s) => s.trim())
          .filter((s) => s.length > 20);

      return {
        success: true,
        ideas: sentences.slice(0, maxIdeas),
      };
    });

/**
 * ============================
 * FRIEND REQUEST NOTIFICATION
 * ============================
 */
exports.sendFriendRequestNotification = functions.firestore
    .document('friendships/{friendshipId}')
    .onCreate(async (snap, context) => {
      try {
        const data = snap.data();
        if (!data || data.status !== 'pending') return null;

        const {userId1, userId2, requestedBy} = data;
        if (!userId1 || !userId2 || !requestedBy) return null;

        const recipientId = requestedBy === userId1 ? userId2 : userId1;

        const recipientDoc = await db.collection('users').doc(recipientId).get();
        if (!recipientDoc.exists) return null;

        const recipient = recipientDoc.data();
        const pushToken = recipient?.pushToken;
        if (!pushToken) return null;

        const requesterDoc = await db.collection('users').doc(requestedBy).get();
        const requester = requesterDoc.exists ? requesterDoc.data() : null;
        const requesterName = requester?.displayName || 'Người dùng';

        const message = {
          token: pushToken,
          notification: {
            title: 'Lời mời kết bạn mới',
            body: `${requesterName} đã gửi lời mời kết bạn`,
          },
          data: {
            type: 'friend_request',
            friendshipId: context.params.friendshipId,
            requesterId: requestedBy,
          },
        };

        await admin.messaging().send(message);
        return null;
      } catch (error) {
        console.error('Friend request notification error:', error);
        return null;
      }
    });

/**
 * ============================
 * FRIEND REQUEST ACCEPTED
 * ============================
 */
exports.sendFriendAcceptedNotification = functions.firestore
    .document('friendships/{friendshipId}')
    .onUpdate(async (change, context) => {
      try {
        const before = change.before.data();
        const after = change.after.data();
        if (!before || !after) return null;
        if (before.status === after.status) return null;
        if (after.status !== 'accepted') return null;

        const {userId1, userId2, requestedBy} = after;
        if (!userId1 || !userId2 || !requestedBy) return null;

        const requesterId = requestedBy;
        const accepterId = requestedBy === userId1 ? userId2 : userId1;

        const requesterDoc = await db.collection('users').doc(requesterId).get();
        if (!requesterDoc.exists) return null;
        const requester = requesterDoc.data();
        const pushToken = requester?.pushToken;
        if (!pushToken) return null;

        const accepterDoc = await db.collection('users').doc(accepterId).get();
        const accepter = accepterDoc.exists ? accepterDoc.data() : null;
        const accepterName = accepter?.displayName || 'Người dùng';

        const message = {
          token: pushToken,
          notification: {
            title: 'Lời mời đã được chấp nhận',
            body: `${accepterName} đã chấp nhận lời mời kết bạn`,
          },
          data: {
            type: 'friend_request_accepted',
            friendshipId: context.params.friendshipId,
            accepterId,
          },
        };

        await admin.messaging().send(message);
        return null;
      } catch (error) {
        console.error('Friend accepted notification error:', error);
        return null;
      }
    });

/**
 * ============================
 * SHARE BOOK IN-APP NOTIFICATION
 * ============================
 */
exports.createShareBookNotification = functions.firestore
    .document('activities/{activityId}')
    .onCreate(async (snap, context) => {
      try {
        const data = snap.data();
        if (!data) return null;

        const type = data.type || data.kind;
        const visibility = data.visibility || (data.isPublic ? 'public' : 'private');
        if (type !== 'bookAdded') return null;
        if (visibility !== 'public') return null;

        const actorId = data.userId;
        if (!actorId) return null;

        const actorDoc = await db.collection('users').doc(actorId).get();
        const actorData = actorDoc.exists ? actorDoc.data() : null;
        const actorName = actorData?.displayName || 'Người dùng';

        const [snap1, snap2] = await Promise.all([
          db.collection('friendships')
              .where('userId1', '==', actorId)
              .where('status', '==', 'accepted')
              .get(),
          db.collection('friendships')
              .where('userId2', '==', actorId)
              .where('status', '==', 'accepted')
              .get(),
        ]);

        const friendIds = new Set();
        snap1.docs.forEach((doc) => {
          const friendship = doc.data();
          if (friendship.userId2) friendIds.add(friendship.userId2);
        });
        snap2.docs.forEach((doc) => {
          const friendship = doc.data();
          if (friendship.userId1) friendIds.add(friendship.userId1);
        });

        if (friendIds.size === 0) return null;

        const batch = db.batch();
        friendIds.forEach((recipientId) => {
          const ref = db.collection('notifications').doc();
          batch.set(ref, {
            recipientId,
            actorId,
            actorName,
            type: 'friend_share',
            bookId: data.bookId || null,
            bookTitle: data.bookTitle || 'Sách mới',
            activityId: context.params.activityId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        await batch.commit();
        return null;
      } catch (error) {
        console.error('Create in-app notification error:', error);
        return null;
      }
    });

/**
 * ============================
 * TEST NOTIFICATION
 * ============================
 */
exports.testNotification = functions.https.onRequest(async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) return res.status(400).send('Missing userId');

    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return res.status(404).send('User not found');

    const {pushToken} = userDoc.data();
    if (!pushToken) return res.status(400).send('No push token');

    const message = {
      token: pushToken,
      notification: {
        title: 'Thông báo thử',
        body: 'Đây là thông báo thử',
      },
    };

    const response = await admin.messaging().send(message);
    res.json({success: true, response});
  } catch (err) {
    console.error(err);
    res.status(500).send(err.message);
  }
});

