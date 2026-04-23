const express = require('express');
const { Pool } = require('pg');
const {
  createShortLink,
  listShortLinks,
  resolveShortLink,
} = require('./link-service');

const app = express();
app.use(express.json({ limit: '16kb' }));

function createTraceId(req) {
  const existing = req.get('x-request-id');
  if (existing && /^[A-Za-z0-9_.:-]{8,128}$/.test(existing)) {
    return existing;
  }
  return cryptoRandomUUID();
}

function cryptoRandomUUID() {
  return require('crypto').randomUUID();
}

function sendError(req, res, status, code, message) {
  const traceId = createTraceId(req);
  console.error(JSON.stringify({
    level: 'error',
    trace_id: traceId,
    code,
    path: req.path,
    method: req.method,
  }));
  res.status(status).json({ error: message, code, trace_id: traceId });
}

const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432', 10),
  database: process.env.POSTGRES_DB || 'shortlinks',
  user: process.env.POSTGRES_USER || 'postgres',
  password: process.env.POSTGRES_PASSWORD,
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/ready', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ready' });
  } catch {
    sendError(req, res, 503, 'DATABASE_UNAVAILABLE', 'Service is not ready.');
  }
});

app.get('/api/links', async (req, res) => {
  try {
    const links = await listShortLinks(pool);
    res.json({ links });
  } catch {
    sendError(req, res, 500, 'LIST_LINKS_FAILED', 'Unable to load links.');
  }
});

app.post('/api/links', async (req, res) => {
  try {
    const result = await createShortLink(pool, {
      originalUrl: req.body?.url,
      customCode: req.body?.custom_code,
    });

    if (!result.ok) {
      return sendError(req, res, result.status, result.code, result.message);
    }

    res.status(201).json({ link: result.link });
  } catch {
    sendError(req, res, 500, 'CREATE_LINK_FAILED', 'Unable to create the short link.');
  }
});

app.get('/r/:code', async (req, res) => {
  try {
    const link = await resolveShortLink(pool, req.params.code);
    if (!link) {
      return sendError(req, res, 404, 'LINK_NOT_FOUND', 'Short link was not found.');
    }

    res.redirect(302, link.original_url);
  } catch {
    sendError(req, res, 500, 'RESOLVE_LINK_FAILED', 'Unable to resolve the short link.');
  }
});

const port = parseInt(process.env.PORT || '3000', 10);
app.listen(port, () => {
  console.log(JSON.stringify({ level: 'info', message: 'url-shortener-api started', port }));
});
