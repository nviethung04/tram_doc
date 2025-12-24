const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/**
 * Scheduled function chạy mỗi sáng để gửi notification về flashcards đến hạn
 * Chạy lúc 8:00 AM mỗi ngày (có thể config timezone)
 */
exports.sendDailyFlashcardReminder = functions.pubsub
  .schedule('0 8 * * *') // 8:00 AM mỗi ngày (UTC)
  .timeZone('Asia/Ho_Chi_Minh')
  .onRun(async (context) => {
    console.log('Running daily flashcard reminder...');

    try {
      // Lấy tất cả users có pushToken
      const usersSnapshot = await db
        .collection('users')
        .where('pushToken', '!=', null)
        .where('pushToken', '!=', '')
        .get();

      const notifications = [];

      for (const userDoc of usersSnapshot.docs) {
        const user = userDoc.data();
        const userId = userDoc.id;

        // Lấy flashcards đến hạn của user
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
              body: `Bạn có ${dueCount} flashcard${dueCount > 1 ? 's' : ''} cần ôn tập hôm nay`,
            },
            data: {
              type: 'flashcard_reminder',
              count: dueCount.toString(),
            },
          });
        }
      }

      // Gửi tất cả notifications
      if (notifications.length > 0) {
        const responses = await admin.messaging().sendAll(notifications);
        console.log(`Sent ${responses.successCount} notifications`);
        console.log(`Failed ${responses.failureCount} notifications`);
      } else {
        console.log('No notifications to send');
      }

      return null;
    } catch (error) {
      console.error('Error sending daily reminders:', error);
      return null;
    }
  });

/**
 * HTTP function để test gửi notification (optional)
 */
exports.testNotification = functions.https.onRequest(async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) {
      res.status(400).send('Missing userId');
      return;
    }

    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      res.status(404).send('User not found');
      return;
    }

    const user = userDoc.data();
    if (!user.pushToken) {
      res.status(400).send('User has no push token');
      return;
    }

    const message = {
      token: user.pushToken,
      notification: {
        title: 'Test Notification',
        body: 'Đây là notification test từ Cloud Functions',
      },
    };

    const response = await admin.messaging().send(message);
    res.json({ success: true, messageId: response });
  } catch (error) {
    console.error('Error sending test notification:', error);
    res.status(500).send(`Error: ${error.message}`);
  }
});

