const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const FormData = require('form-data');

admin.initializeApp();

const db = admin.firestore();

// OCR.space API Configuration
// Get API key from environment variables or Firebase config
const ocrSpaceConfig = functions.config().ocrspace || {};
const OCR_SPACE_API_KEY = ocrSpaceConfig.apikey || process.env.OCR_SPACE_API_KEY || 'helloworld'; // Free tier default
const OCR_SPACE_API_URL = 'https://api.ocr.space/parse/image';

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
 * Clean OCR text - Remove noise, broken lines, and format text
 * @param {string} text - Raw OCR text
 * @returns {string} - Cleaned text
 */
function cleanOCRText(text) {
  if (!text || typeof text !== 'string') return '';

  let cleaned = text;

  // Remove excessive whitespace
  cleaned = cleaned.replace(/\s+/g, ' ');

  // Remove broken lines that are just single characters or very short
  cleaned = cleaned
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.length > 1 || /[a-zA-Z0-9]/.test(line))
      .join('\n');

  // Fix common OCR errors
  cleaned = cleaned
      .replace(/l\s+/g, ' ') // Fix 'l' mistaken for 'I'
      .replace(/\s+([.,!?;:])/g, '$1') // Remove space before punctuation
      .replace(/([.,!?;:])\s*([.,!?;:])/g, '$1') // Remove duplicate punctuation
      .replace(/\n{3,}/g, '\n\n'); // Max 2 consecutive newlines

  // Remove lines that are mostly special characters
  cleaned = cleaned
      .split('\n')
      .filter((line) => {
        const specialCharRegex =
            /[^a-zA-Z0-9\sàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]/g;
        const specialCharRatio = (line.match(specialCharRegex) || []).length;
        return specialCharRatio / Math.max(line.length, 1) < 0.5;
      })
      .join('\n');

  return cleaned.trim();
}

/**
 * OCR Function - Extract text from image using OCR.space API
 * Security: API key is kept on server, client only sends image
 *
 * Request body:
 * {
 *   imageBase64: string (base64 encoded image),
 *   language?: string (default: 'vie' for Vietnamese)
 * }
 *
 * Response:
 * {
 *   success: boolean,
 *   text?: string,
 *   confidence?: number,
 *   error?: string
 * }
 */
exports.performOCR = functions
    .region('asia-southeast1')
    .https.onCall(async (data, context) => {
    // Verify authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated',
        );
      }

      const {imageBase64, language = 'vie'} = data;

      if (!imageBase64) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Missing imageBase64 parameter',
        );
      }

      try {
        // Prepare form data for OCR.space API
        const formData = new FormData();
        formData.append('base64Image', `data:image/jpeg;base64,${imageBase64}`);
        formData.append('language', language); // 'vie' for Vietnamese, 'eng' for English
        formData.append('isOverlayRequired', 'false');
        formData.append('detectOrientation', 'true');
        formData.append('scale', 'true');
        formData.append('OCREngine', '2'); // Engine 2 is better for documents

        // Call OCR.space API
        const response = await axios.post(OCR_SPACE_API_URL, formData, {
          headers: {
            ...formData.getHeaders(),
            'apikey': OCR_SPACE_API_KEY,
          },
          timeout: 30000, // 30 seconds timeout
        });

        // Parse OCR.space response
        if (response.data && response.data.ParsedResults && response.data.ParsedResults.length > 0) {
          const parsedResult = response.data.ParsedResults[0];
          let extractedText = parsedResult.ParsedText || '';

          // Clean the extracted text
          extractedText = cleanOCRText(extractedText);

          // Calculate confidence (OCR.space doesn't provide confidence, estimate based on text quality)
          const confidence = extractedText.length > 10 ? 0.85 : 0.5;

          // Log for monitoring (without sensitive data)
          console.log(`OCR completed for user ${context.auth.uid}, text length: ${extractedText.length}`);

          if (extractedText.trim().length === 0) {
            return {
              success: false,
              error: 'No text detected in image or text is empty after cleaning',
            };
          }

          return {
            success: true,
            text: extractedText,
            confidence: confidence,
          };
        } else if (response.data && response.data.ErrorMessage) {
        // OCR.space returned an error
          const errorMsg = response.data.ErrorMessage[0] || 'OCR processing failed';
          console.error('OCR.space API error:', errorMsg);
          return {
            success: false,
            error: errorMsg,
          };
        } else {
        // Unexpected response format
          console.error('Unexpected OCR.space response:', response.data);
          return {
            success: false,
            error: 'Unexpected response from OCR service',
          };
        }
      } catch (error) {
        console.error('OCR Error:', error);

        // Handle specific error cases
        if (error.response) {
        // API returned error status
          const status = error.response.status;
          const errorMsg = error.response.data?.ErrorMessage?.[0] || error.message;

          if (status === 401 || status === 403) {
            return {
              success: false,
              error: 'OCR API authentication failed. Please check API key configuration.',
            };
          } else if (status === 429) {
            return {
              success: false,
              error: 'OCR API rate limit exceeded. Please try again later.',
            };
          } else {
            return {
              success: false,
              error: `OCR API error: ${errorMsg}`,
            };
          }
        } else if (error.code === 'ECONNABORTED') {
          return {
            success: false,
            error: 'OCR request timeout. Please try again.',
          };
        } else {
          return {
            success: false,
            error: `OCR processing failed: ${error.message}`,
          };
        }
      }
    });

/**
 * Extract Key Ideas from text using improved algorithm
 * Better than simple sentence length - uses multiple heuristics
 *
 * Request body:
 * {
 *   text: string,
 *   maxIdeas?: number (default: 5)
 * }
 *
 * Response:
 * {
 *   success: boolean,
 *   ideas?: string[],
 *   error?: string
 * }
 */
exports.extractKeyIdeas = functions
    .region('asia-southeast1')
    .https.onCall(async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated',
        );
      }

      const {text, maxIdeas = 5} = data;

      if (!text || typeof text !== 'string' || text.trim().length === 0) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Text is required and must be non-empty',
        );
      }

      try {
        const ideas = extractKeyIdeasFromText(text, maxIdeas);

        return {
          success: true,
          ideas: ideas,
        };
      } catch (error) {
        console.error('Key Ideas Extraction Error:', error);
        throw new functions.https.HttpsError(
            'internal',
            `Key ideas extraction failed: ${error.message}`,
        );
      }
    });

/**
 * Improved Key Ideas Extraction Algorithm
 * Uses multiple heuristics for better accuracy:
 * 1. Sentence length (longer = more important)
 * 2. Keyword density (important terms)
 * 3. Position in text (first/last sentences often important)
 * 4. Question marks (questions are often key ideas)
 * 5. Numbered/bulleted items
 */
function extractKeyIdeasFromText(text, maxIdeas = 5) {
  if (!text || text.trim().length === 0) return [];

  // Normalize text
  const normalizedText = text
      .replace(/\s+/g, ' ')
      .trim();

  // Split into sentences (Vietnamese and English)
  const sentenceRegex = /[.!?。！？]\s+|[\n\r]+/;
  let sentences = normalizedText
      .split(sentenceRegex)
      .map((s) => s.trim())
      .filter((s) => s.length > 15); // Minimum sentence length

  if (sentences.length === 0) {
    // Fallback: split by line breaks if no sentence delimiters
    sentences = normalizedText
        .split(/[\n\r]+/)
        .map((s) => s.trim())
        .filter((s) => s.length > 15);
  }

  if (sentences.length === 0) {
    // Last resort: return the whole text if it's short enough
    if (normalizedText.length <= 200) {
      return [normalizedText];
    }
    return [];
  }

  // Score each sentence
  const scoredSentences = sentences.map((sentence, index) => {
    let score = 0;

    // 1. Length score (longer sentences often contain more information)
    // Normalize: longer = higher score, but not too long (might be rambling)
    const lengthScore = Math.min(sentence.length / 100, 1.5);
    score += lengthScore * 0.3;

    // 2. Position score (first and last sentences are often important)
    const totalSentences = sentences.length;
    const positionRatio = index / totalSentences;
    if (positionRatio < 0.2 || positionRatio > 0.8) {
      score += 0.2; // Boost first 20% and last 20%
    }

    // 3. Question mark score (questions are often key ideas)
    if (sentence.includes('?') || sentence.includes('？')) {
      score += 0.3;
    }

    // 4. Numbered/bulleted items (often key points)
    if (/^[\d-*•]\s/.test(sentence) || /^\d+[.)]\s/.test(sentence)) {
      score += 0.4;
    }

    // 5. Keyword indicators (Vietnamese and English)
    const keywords = [
      'quan trọng',
      'chính',
      'điểm',
      'ý',
      'tóm lại',
      'kết luận',
      'important',
      'key',
      'main',
      'conclusion',
      'summary',
      'định nghĩa',
      'definition',
      'ví dụ',
      'example',
    ];
    const lowerSentence = sentence.toLowerCase();
    const keywordCount = keywords.filter((kw) =>
      lowerSentence.includes(kw),
    ).length;
    score += keywordCount * 0.1;

    // 6. Avoid very short sentences
    if (sentence.length < 30) {
      score -= 0.2;
    }

    return {
      text: sentence,
      score: score,
      index: index,
    };
  });

  // Sort by score (highest first)
  scoredSentences.sort((a, b) => b.score - a.score);

  // Take top N, but ensure diversity (don't take all from same area)
  const selectedIdeas = [];
  const usedIndices = new Set();

  for (const item of scoredSentences) {
    if (selectedIdeas.length >= maxIdeas) break;

    // Check if this sentence is too close to already selected ones
    const isTooClose = Array.from(usedIndices).some((usedIdx) => {
      return Math.abs(item.index - usedIdx) < 2;
    });

    if (!isTooClose || selectedIdeas.length === 0) {
      selectedIdeas.push(item.text);
      usedIndices.add(item.index);
    }
  }

  // If we don't have enough, fill with remaining high-scored sentences
  if (selectedIdeas.length < maxIdeas) {
    for (const item of scoredSentences) {
      if (selectedIdeas.length >= maxIdeas) break;
      if (!selectedIdeas.includes(item.text)) {
        selectedIdeas.push(item.text);
      }
    }
  }

  // Sort selected ideas by original position in text
  const finalIdeas = selectedIdeas
      .map((idea) => {
        const originalIndex = sentences.indexOf(idea);
        return {text: idea, index: originalIndex};
      })
      .sort((a, b) => a.index - b.index)
      .map((item) => item.text);

  return finalIdeas.slice(0, maxIdeas);
}

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
    res.json({success: true, messageId: response});
  } catch (error) {
    console.error('Error sending test notification:', error);
    res.status(500).send(`Error: ${error.message}`);
  }
});
