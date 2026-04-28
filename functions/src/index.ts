/**
 * Firebase Functions — VocabAI AI Proxy
 *
 * Proxy Claude API calls từ Flutter app.
 * API key được bảo vệ trong Firebase Secret Manager.
 *
 * Deploy:
 *   firebase functions:secrets:set CLAUDE_API_KEY
 *   firebase deploy --only functions
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { initializeApp } from 'firebase-admin/app';
import Anthropic from '@anthropic-ai/sdk';

initializeApp();
const db = getFirestore();

const claudeApiKey = defineSecret('CLAUDE_API_KEY');

// ── Constants ──────────────────────────────────────────────────

const FREE_DAILY_LIMIT = 10;
const PREMIUM_DAILY_LIMIT = 50;
const MAX_INPUT_LENGTH = 8000;   // tokens ~ 2000 words
const DEFAULT_MODEL = 'claude-3-5-haiku-20241022';

// ── Type definitions ───────────────────────────────────────────

interface MessageContent {
  type: 'text' | 'image';
  text?: string;
  source?: {
    type: 'base64';
    media_type: string;
    data: string;
  };
}

interface Message {
  role: 'user' | 'assistant';
  content: string | MessageContent[];
}

interface CallClaudeRequest {
  messages: Message[];
  isPremium?: boolean;
  model?: string;
  maxTokens?: number;
  systemPrompt?: string;
}

// ── Callable Function: callClaude ──────────────────────────────

export const callClaude = onCall(
  {
    secrets: [claudeApiKey],
    region: 'asia-southeast1',
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  async (request) => {
    // 1. Auth check
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Cần đăng nhập để dùng tính năng này');
    }

    const uid = request.auth.uid;
    const data = request.data as CallClaudeRequest;

    // 2. Validate input
    if (!data.messages || !Array.isArray(data.messages) || data.messages.length === 0) {
      throw new HttpsError('invalid-argument', 'messages không hợp lệ');
    }

    // 3. Rate limiting — đếm theo ngày
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const usageRef = db.doc(`usage/${uid}/daily/${today}`);

    const isPremium = data.isPremium ?? false;
    const dailyLimit = isPremium ? PREMIUM_DAILY_LIMIT : FREE_DAILY_LIMIT;

    // Atomic increment + check
    let currentCount = 0;
    try {
      const usageSnap = await usageRef.get();
      currentCount = (usageSnap.data()?.count as number) ?? 0;
    } catch {
      currentCount = 0;
    }

    if (currentCount >= dailyLimit) {
      throw new HttpsError(
        'resource-exhausted',
        `Đã đạt giới hạn ${dailyLimit} lần/ngày. ${isPremium ? 'Thử lại ngày mai.' : 'Upgrade Premium để tăng giới hạn.'}`
      );
    }

    // 4. Gọi Claude API
    const client = new Anthropic({ apiKey: claudeApiKey.value() });

    const model = data.model ?? DEFAULT_MODEL;
    const maxTokens = data.maxTokens ?? 1024;

    try {
      const response = await client.messages.create({
        model,
        max_tokens: maxTokens,
        system: data.systemPrompt,
        messages: data.messages as Anthropic.MessageParam[],
      });

      // 5. Cập nhật usage counter
      await usageRef.set(
        {
          count: FieldValue.increment(1),
          lastUsed: FieldValue.serverTimestamp(),
          uid,
        },
        { merge: true }
      );

      // 6. Trả về kết quả
      const content = response.content[0];
      if (content.type !== 'text') {
        throw new HttpsError('internal', 'Unexpected response type from Claude');
      }

      return {
        text: content.text,
        model: response.model,
        inputTokens: response.usage.input_tokens,
        outputTokens: response.usage.output_tokens,
      };
    } catch (err: unknown) {
      if (err instanceof HttpsError) throw err;

      const error = err as Error;
      console.error('[callClaude] Claude API error:', error.message);
      throw new HttpsError('internal', `Claude API lỗi: ${error.message}`);
    }
  }
);

// ── Callable Function: getRateLimit ────────────────────────────
// Trả về usage hiện tại của user (dùng để hiển thị UI)

export const getRateLimit = onCall(
  { region: 'asia-southeast1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Cần đăng nhập');
    }

    const uid = request.auth.uid;
    const today = new Date().toISOString().split('T')[0];
    const usageRef = db.doc(`usage/${uid}/daily/${today}`);

    const snap = await usageRef.get();
    const count = (snap.data()?.count as number) ?? 0;
    const isPremium = (request.data as { isPremium?: boolean }).isPremium ?? false;
    const limit = isPremium ? PREMIUM_DAILY_LIMIT : FREE_DAILY_LIMIT;

    return {
      used: count,
      limit,
      remaining: Math.max(0, limit - count),
      resetAt: `${today}T23:59:59Z`,
    };
  }
);
