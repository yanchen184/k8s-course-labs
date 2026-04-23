const crypto = require('crypto');

const CODE_PATTERN = /^[A-Za-z0-9_-]{4,32}$/;
const DEFAULT_CODE_LENGTH = 6;
const MAX_URL_LENGTH = 2048;
const LIST_LIMIT = 50;

function normalizeUrl(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  if (!trimmed || trimmed.length > MAX_URL_LENGTH) {
    return null;
  }

  let parsed;
  try {
    parsed = new URL(trimmed);
  } catch {
    return null;
  }

  if (!['http:', 'https:'].includes(parsed.protocol)) {
    return null;
  }

  return parsed.toString();
}

function normalizeCode(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  if (!CODE_PATTERN.test(trimmed)) {
    return null;
  }

  return trimmed;
}

function createCode(length = DEFAULT_CODE_LENGTH) {
  const alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const bytes = crypto.randomBytes(length);
  let code = '';

  for (const byte of bytes) {
    code += alphabet[byte % alphabet.length];
  }

  return code;
}

async function insertShortLink(pool, { originalUrl, code }) {
  const result = await pool.query(
    `INSERT INTO short_links (code, original_url)
     VALUES ($1, $2)
     RETURNING id, code, original_url, clicks, created_at, last_clicked_at`,
    [code, originalUrl]
  );

  return result.rows[0];
}

async function createShortLink(pool, { originalUrl, customCode }) {
  const normalizedUrl = normalizeUrl(originalUrl);
  if (!normalizedUrl) {
    return { ok: false, status: 400, code: 'INVALID_URL', message: 'A valid http or https URL is required.' };
  }

  if (customCode) {
    const normalizedCustomCode = normalizeCode(customCode);
    if (!normalizedCustomCode) {
      return { ok: false, status: 400, code: 'INVALID_CODE', message: 'Custom code must be 4-32 URL-safe characters.' };
    }

    try {
      const link = await insertShortLink(pool, { originalUrl: normalizedUrl, code: normalizedCustomCode });
      return { ok: true, link };
    } catch (err) {
      if (err && err.code === '23505') {
        return { ok: false, status: 409, code: 'CODE_TAKEN', message: 'This short code is already taken.' };
      }
      throw err;
    }
  }

  for (let attempt = 0; attempt < 5; attempt += 1) {
    try {
      const link = await insertShortLink(pool, { originalUrl: normalizedUrl, code: createCode() });
      return { ok: true, link };
    } catch (err) {
      if (!err || err.code !== '23505') {
        throw err;
      }
    }
  }

  return { ok: false, status: 503, code: 'CODE_GENERATION_FAILED', message: 'Could not allocate a short code. Please retry.' };
}

async function listShortLinks(pool) {
  const result = await pool.query(
    `SELECT id, code, original_url, clicks, created_at, last_clicked_at
     FROM short_links
     ORDER BY created_at DESC
     LIMIT $1`,
    [LIST_LIMIT]
  );

  return result.rows;
}

async function resolveShortLink(pool, code) {
  const normalizedCode = normalizeCode(code);
  if (!normalizedCode) {
    return null;
  }

  const result = await pool.query(
    `UPDATE short_links
     SET clicks = clicks + 1, last_clicked_at = NOW()
     WHERE code = $1
     RETURNING original_url`,
    [normalizedCode]
  );

  return result.rows[0] || null;
}

module.exports = {
  CODE_PATTERN,
  LIST_LIMIT,
  createCode,
  createShortLink,
  listShortLinks,
  normalizeCode,
  normalizeUrl,
  resolveShortLink,
};
