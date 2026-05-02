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

import { onRequest } from 'firebase-functions/v2/https';
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
const DEFAULT_MODEL = 'claude-3-5-haiku-20241022';

// App secret — Flutter gửi header này để xác thực request
// Không cần Firebase Auth, không phụ thuộc GMS
const APP_SECRET = 'vocabai-proxy-2024';

// ── Type definitions ───────────────────────────────────────────

interface Message {
  role: 'user' | 'assistant';
  content: string | object[];
}

interface CallClaudeRequest {
  messages: Message[];
  isPremium?: boolean;
  model?: string;
  maxTokens?: number;
  systemPrompt?: string;
}

// ── HTTPS Function: callClaude ─────────────────────────────────
// Dùng onRequest thay vì onCall để tránh phụ thuộc Firebase Auth

export const callClaude = onRequest(
  {
    secrets: [claudeApiKey],
    region: 'asia-southeast1',
    timeoutSeconds: 60,
    memory: '256MiB',
    cors: true,
  },
  async (req, res) => {
    // 1. Chỉ chấp nhận POST
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    // 2. Kiểm tra app secret
    const secret = req.headers['x-app-secret'];
    if (secret !== APP_SECRET) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    // 3. Lấy uid từ header (Firebase Auth UID nếu có) hoặc dùng IP
    const uid = (req.headers['x-user-id'] as string | undefined)
      ?? (req.headers['x-forwarded-for'] as string | undefined)?.split(',')[0].trim()
      ?? req.ip
      ?? 'anonymous';

    const data = req.body as CallClaudeRequest;

    // 4. Validate input
    if (!data.messages || !Array.isArray(data.messages) || data.messages.length === 0) {
      res.status(400).json({ error: 'messages không hợp lệ' });
      return;
    }

    // 5. Rate limiting theo ngày
    const today = new Date().toISOString().split('T')[0];
    const usageRef = db.doc(`usage/${uid}/daily/${today}`);

    const isPremium = data.isPremium ?? false;
    const dailyLimit = isPremium ? PREMIUM_DAILY_LIMIT : FREE_DAILY_LIMIT;

    let currentCount = 0;
    try {
      const usageSnap = await usageRef.get();
      currentCount = (usageSnap.data()?.count as number) ?? 0;
    } catch {
      currentCount = 0;
    }

    if (currentCount >= dailyLimit) {
      res.status(429).json({
        error: `Đã đạt giới hạn ${dailyLimit} lần/ngày. ${isPremium ? 'Thử lại ngày mai.' : 'Upgrade Premium để tăng giới hạn.'}`,
        code: 'rate-limit-exceeded',
      });
      return;
    }

    // 6. Gọi Claude API
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

      // 7. Cập nhật usage counter
      await usageRef.set(
        {
          count: FieldValue.increment(1),
          lastUsed: FieldValue.serverTimestamp(),
          uid,
        },
        { merge: true }
      );

      // 8. Trả về kết quả
      const content = response.content[0];
      if (content.type !== 'text') {
        res.status(500).json({ error: 'Unexpected response type from Claude' });
        return;
      }

      res.status(200).json({
        text: content.text,
        model: response.model,
        inputTokens: response.usage.input_tokens,
        outputTokens: response.usage.output_tokens,
      });
    } catch (err: unknown) {
      const error = err as Error;
      console.error('[callClaude] Claude API error:', error.message);
      res.status(500).json({ error: `Claude API lỗi: ${error.message}` });
    }
  }
);

// ── HTTPS Function: getRateLimit ───────────────────────────────

export const getRateLimit = onRequest(
  { region: 'asia-southeast1', cors: true },
  async (req, res) => {
    const secret = req.headers['x-app-secret'];
    if (secret !== APP_SECRET) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const uid = (req.headers['x-user-id'] as string | undefined)
      ?? req.ip
      ?? 'anonymous';

    const today = new Date().toISOString().split('T')[0];
    const usageRef = db.doc(`usage/${uid}/daily/${today}`);

    const snap = await usageRef.get();
    const count = (snap.data()?.count as number) ?? 0;
    const isPremium = (req.body as { isPremium?: boolean }).isPremium ?? false;
    const limit = isPremium ? PREMIUM_DAILY_LIMIT : FREE_DAILY_LIMIT;

    res.status(200).json({
      used: count,
      limit,
      remaining: Math.max(0, limit - count),
      resetAt: `${today}T23:59:59Z`,
    });
  }
);
