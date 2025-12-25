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
            'Authentication required',
        );
      }

      if (!OCR_SPACE_API_KEY) {
        throw new functions.https.HttpsError(
            'internal',
            'OCR API key missing',
        );
      }

      const {imageBase64, language = 'vie'} = data;
      if (!imageBase64) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'imageBase64 is required',
        );
      }

      // Validate language - only allow valid OCR.space language codes
      const validLanguages = ['vie', 'eng', 'fra', 'deu', 'spa', 'por', 'chi_sim', 'chi_tra', 'jpn', 'kor'];
      const ocrLanguage = validLanguages.includes(language) ? language : 'vie';

      try {
        const base64WithPrefix = imageBase64.startsWith('data:') ?
         imageBase64 :
         `data:image/jpeg;base64,${imageBase64}`;

        const formData = new FormData();
        formData.append('apikey', OCR_SPACE_API_KEY);
        formData.append('language', ocrLanguage); // Use validated language
        formData.append('isOverlayRequired', 'false');
        formData.append('detectOrientation', 'true');
        formData.append('scale', 'true');
        // ❌ KHÔNG DÙNG Engine 2 – gây lỗi tiếng Việt
        // formData.append('OCREngine', '2');
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
            return {success: false, error: 'No text detected'};
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

        return {success: false, error: 'Unexpected OCR response'};
      } catch (err) {
        console.error('OCR error:', err);
        return {
          success: false,
          error: err.message || 'OCR failed',
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
            'Authentication required',
        );
      }

      const {text, maxIdeas = 5} = data;
      if (!text) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Text is required',
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
        title: 'Test Notification',
        body: 'Đây là notification test',
      },
    };

    const response = await admin.messaging().send(message);
    res.json({success: true, response});
  } catch (err) {
    console.error(err);
    res.status(500).send(err.message);
  }
});
