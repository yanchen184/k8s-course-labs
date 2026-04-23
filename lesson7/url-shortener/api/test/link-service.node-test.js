const test = require('node:test');
const assert = require('node:assert/strict');
const {
  createCode,
  normalizeCode,
  normalizeUrl,
} = require('../link-service');

test('normalizeUrl accepts http and https URLs', () => {
  assert.equal(normalizeUrl('https://example.com/path?q=1'), 'https://example.com/path?q=1');
  assert.equal(normalizeUrl(' http://example.com/demo '), 'http://example.com/demo');
});

test('normalizeUrl rejects unsupported or invalid URLs', () => {
  assert.equal(normalizeUrl('javascript:alert(1)'), null);
  assert.equal(normalizeUrl('ftp://example.com/file'), null);
  assert.equal(normalizeUrl('not-a-url'), null);
  assert.equal(normalizeUrl(''), null);
});

test('normalizeCode allows only URL-safe short codes', () => {
  assert.equal(normalizeCode('Abc_123-'), 'Abc_123-');
  assert.equal(normalizeCode('bad code'), null);
  assert.equal(normalizeCode('../admin'), null);
  assert.equal(normalizeCode('abc'), null);
});

test('createCode returns fixed-length URL-safe codes', () => {
  const code = createCode(10);
  assert.equal(code.length, 10);
  assert.match(code, /^[A-Za-z0-9]+$/);
});
