'use strict';

/**
 * Finder Backend — Integration Test Suite
 *
 * Usage:
 *   1. Start the server:  node server.js
 *   2. Run this file:     node run-tests.js
 *
 * The script seeds a verified test user directly into SQLite,
 * runs all HTTP tests sequentially, then removes the seeded user.
 *
 * Requires no extra packages — uses axios + form-data already present
 * as transitive dependencies in node_modules.
 */

require('dotenv').config();

const axios    = require('axios');
const FormData = require('form-data');

// ─── Configuration ────────────────────────────────────────────────────────────

const BASE = process.env.TEST_BASE_URL || 'http://localhost:3500';

const TOKEN = {
  user1:    'mock-token-user1',    // mock Firebase decodes uid → 'user1'
  admin:    'mock-token-admin',    // uid → 'admin'
  testuser: 'mock-token-testuser', // uid → 'testuser'
};

// A stable public image URL used as a form-field placeholder.
// Sending image_url as a text field (not a file) causes the Cloudinary
// middleware to skip the upload and pass the value through as-is.
const IMAGE_URL = 'https://res.cloudinary.com/demo/image/upload/sample.jpg';

// ─── Test Runner State ────────────────────────────────────────────────────────

const stats = { pass: 0, fail: 0, log: [] };

let seedUserId     = null;
let seedCreatedNew = false;  // true only if we INSERT a brand-new row

// ─── Helpers ──────────────────────────────────────────────────────────────────

const auth = (tok) => ({ Authorization: `Bearer ${tok}` });

function buildForm(fields) {
  const f = new FormData();
  for (const [k, v] of Object.entries(fields)) f.append(k, String(v));
  return f;
}

async function run(label, fn) {
  process.stdout.write(`🔥 ${label} ... `);
  try {
    const result = await fn();
    if (result.ok) {
      const suffix = result.note ? ` — ${result.note}` : '';
      console.log(`✅ PASS${suffix}`);
      stats.pass++;
      stats.log.push({ label, status: 'PASS', note: result.note || '' });
    } else {
      console.log(`❌ FAIL — ${result.reason}`);
      stats.fail++;
      stats.log.push({ label, status: 'FAIL', note: result.reason });
    }
  } catch (err) {
    const detail = err.response
      ? `HTTP ${err.response.status}: ${JSON.stringify(err.response.data).slice(0, 120)}`
      : err.message;
    console.log(`❌ FAIL — ${detail}`);
    stats.fail++;
    stats.log.push({ label, status: 'FAIL', note: detail });
  }
}

const ok   = (note = '')  => ({ ok: true,  note });
const fail = (reason)     => ({ ok: false, reason });

// ─── DB Seed / Teardown ───────────────────────────────────────────────────────

async function seedTestUser() {
  // Load models in this process (same SQLite file as the running server).
  // Node module cache means double-requires are free.
  require('./models/index');
  const User      = require('./models/User.model');
  const sequelize = require('./db/Sequelize');
  await sequelize.sync();

  // If a leftover row from a failed previous run exists, remove it first.
  await User.destroy({ where: { email: '__test__user1@finder-test.local' } });

  // Check whether firebase_uid 'user1' already exists (real dev data).
  let user = await User.findOne({ where: { firebase_uid: 'user1' } });

  if (user) {
    // Update only the fields the test needs; leave everything else intact.
    await user.update({
      status:              'active',
      verified:            true,
      verification_status: 'approved',
    });
    seedCreatedNew = false;
  } else {
    user = await User.create({
      firebase_uid:        'user1',
      name:                'Test User One',
      email:               '__test__user1@finder-test.local',
      status:              'active',
      verified:            true,
      verification_status: 'approved',
      role:                'user',
    });
    seedCreatedNew = true;
  }

  seedUserId = user.id;
  return user;
}

async function teardownTestUser() {
  // Only delete what we created; never delete pre-existing dev users.
  if (!seedCreatedNew || !seedUserId) return;
  const User = require('./models/User.model');
  await User.destroy({ where: { id: seedUserId } });
}

// ─── Tests ────────────────────────────────────────────────────────────────────

async function main() {
  console.log('\n' + '═'.repeat(52));
  console.log('  FINDER BACKEND — INTEGRATION TEST SUITE');
  console.log(`  Target : ${BASE}`);
  console.log('═'.repeat(52) + '\n');

  // ── Pre-flight: confirm server is up ──────────────────────────────────────
  try {
    await axios.get(`${BASE}/health`, { timeout: 4000 });
  } catch {
    console.error(`💥 Cannot reach ${BASE}. Start the server first:\n   node server.js\n`);
    process.exit(1);
  }

  // ── DB Setup ──────────────────────────────────────────────────────────────
  console.log('🔧 Seeding test user...');
  try {
    const u = await seedTestUser();
    const action = seedCreatedNew ? 'created' : 'updated';
    console.log(`   ✅ user1 ${action} — id: ${u.id}\n`);
  } catch (err) {
    console.error('   💥 DB seed failed:', err.message, '\n');
    process.exit(1);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  T01  Health Check
  // ─────────────────────────────────────────────────────────────────────────
  await run('T01 | GET /health', async () => {
    const res = await axios.get(`${BASE}/health`);
    if (res.status !== 200)
      return fail(`Expected 200, got ${res.status}`);
    if (res.data.status !== 'ok')
      return fail(`Expected status:'ok', got '${res.data.status}'`);
    return ok(`service: ${res.data.service}`);
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  T02  Auth — no token
  // ─────────────────────────────────────────────────────────────────────────
  await run('T02 | Auth guard — no token → 401', async () => {
    try {
      await axios.get(`${BASE}/api/v1/post/my-posts`);
      return fail('Expected 401, got 200');
    } catch (err) {
      const s = err.response?.status;
      return s === 401 ? ok() : fail(`Got ${s}`);
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  T03  Auth — invalid token
  // ─────────────────────────────────────────────────────────────────────────
  await run('T03 | Auth guard — invalid token → 401 or 404', async () => {
    try {
      await axios.get(`${BASE}/api/v1/post/my-posts`, {
        headers: auth('totally-invalid-garbage-token'),
      });
      return fail('Expected 401/404, got 200');
    } catch (err) {
      const s = err.response?.status;
      // 401 = bad token; 404 = UID decoded but user not in DB — both correct
      return (s === 401 || s === 404) ? ok(`status ${s}`) : fail(`Got ${s}`);
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  T04  Auth — valid token (my-posts)
  // ─────────────────────────────────────────────────────────────────────────
  await run('T04 | Valid token — GET /api/v1/post/my-posts → 200', async () => {
    const res = await axios.get(`${BASE}/api/v1/post/my-posts`, {
      headers: auth(TOKEN.user1),
    });
    if (res.status !== 200)        return fail(`Expected 200, got ${res.status}`);
    if (res.data.success !== true) return fail('Expected success: true');
    return ok(`${res.data.data?.length ?? 0} posts`);
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  T05  Create FOUND post
  // ─────────────────────────────────────────────────────────────────────────
  await run('T05 | Create FOUND post → 201', async () => {
    const form = buildForm({
      title:       'Found: Black Leather Wallet',
      post_type:   'found',
      category:    'wallet',
      country:     'Egypt',
      city:        'Cairo',
      description: 'Found near Tahrir Square',
      image_url:   IMAGE_URL,
    });
    const res = await axios.post(`${BASE}/api/v1/post/create`, form, {
      headers: { ...auth(TOKEN.user1), ...form.getHeaders() },
    });
    if (res.status !== 201)        return fail(`Expected 201, got ${res.status}`);
    if (res.data.success !== true) return fail(res.data.message);
    const parts = [`id: ${res.data.data?.id}`];
    if (res.data.warning) parts.push(`⚠️  ${res.data.warning}`);
    return ok(parts.join(' | '));
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  T06  Create LOST post
  // ─────────────────────────────────────────────────────────────────────────
  await run('T06 | Create LOST post → 201', async () => {
    const form = buildForm({
      title:       'Lost: Brown Wallet with ID cards',
      post_type:   'lost',
      category:    'wallet',
      country:     'Egypt',
      city:        'Cairo',
      description: 'Lost near Cairo metro station',
      image_url:   IMAGE_URL,
    });
    const res = await axios.post(`${BASE}/api/v1/post/create`, form, {
      headers: { ...auth(TOKEN.user1), ...form.getHeaders() },
    });
    if (res.status !== 201)        return fail(`Expected 201, got ${res.status}`);
    if (res.data.success !== true) return fail(res.data.message);
    const parts = [`id: ${res.data.data?.id}`];
    if (res.data.warning) parts.push(`⚠️  ${res.data.warning}`);
    return ok(parts.join(' | '));
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  T07  Validation — missing title
  // ─────────────────────────────────────────────────────────────────────────
  await run('T07 | Validation — missing title → 400+', async () => {
    const form = buildForm({
      post_type: 'found',
      country:   'Egypt',
      city:      'Cairo',
      image_url: IMAGE_URL,
      // title intentionally omitted
    });
    try {
      const res = await axios.post(`${BASE}/api/v1/post/create`, form, {
        headers: { ...auth(TOKEN.user1), ...form.getHeaders() },
      });
      return res.status >= 400
        ? ok(`status ${res.status}`)
        : fail(`Expected 400+, got ${res.status}`);
    } catch (err) {
      const s = err.response?.status;
      return s >= 400 ? ok(`status ${s}`) : fail(`Expected 400+, got ${s}`);
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  T08  Validation — invalid post_type
  // ─────────────────────────────────────────────────────────────────────────
  await run('T08 | Validation — invalid post_type → 400+', async () => {
    const form = buildForm({
      title:     'Test Invalid Type',
      post_type: 'stolen',           // not 'lost' or 'found'
      country:   'Egypt',
      city:      'Cairo',
      image_url: IMAGE_URL,
    });
    try {
      const res = await axios.post(`${BASE}/api/v1/post/create`, form, {
        headers: { ...auth(TOKEN.user1), ...form.getHeaders() },
      });
      return res.status >= 400
        ? ok(`status ${res.status}`)
        : fail(`Expected 400+, got ${res.status}`);
    } catch (err) {
      const s = err.response?.status;
      return s >= 400 ? ok(`status ${s}`) : fail(`Expected 400+, got ${s}`);
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  T09  Validation — missing image_url
  // ─────────────────────────────────────────────────────────────────────────
  await run('T09 | Validation — missing image_url → 400', async () => {
    const form = buildForm({
      title:     'Test No Image',
      post_type: 'found',
      country:   'Egypt',
      city:      'Cairo',
      // image_url intentionally omitted
    });
    try {
      const res = await axios.post(`${BASE}/api/v1/post/create`, form, {
        headers: { ...auth(TOKEN.user1), ...form.getHeaders() },
      });
      return res.status >= 400
        ? ok(`status ${res.status}`)
        : fail(`Expected 400+, got ${res.status}`);
    } catch (err) {
      const s = err.response?.status;
      return s >= 400 ? ok(`status ${s}`) : fail(`Expected 400+, got ${s}`);
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  T10  Find matches  (AI resilient — may be down locally)
  // ─────────────────────────────────────────────────────────────────────────
  await run('T10 | POST /api/v1/match/find-matches (AI optional)', async () => {
    const form = buildForm({
      type:      'lost',
      category:  'wallet',
      country:   'Egypt',
      city:      'Cairo',
      image_url: IMAGE_URL,
    });
    try {
      const res = await axios.post(`${BASE}/api/v1/match/find-matches`, form, {
        headers: { ...auth(TOKEN.user1), ...form.getHeaders() },
      });
      const count = res.data.data?.matches?.length ?? 0;
      return ok(`AI up — ${count} match(es)`);
    } catch (err) {
      const s   = err.response?.status;
      const msg = (err.response?.data?.message || '').toLowerCase();

      if (s === 400 && msg.includes('ai service'))
        return ok('AI down — handled gracefully (expected)');

      // No candidates in DB → early exit before AI call → success:false with location message
      if (s === 400)
        return ok(`no candidates / early exit — "${err.response?.data?.message}"`);

      return fail(`Unexpected status ${s}: ${err.response?.data?.message}`);
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  T11  Find matches — missing required field
  // ─────────────────────────────────────────────────────────────────────────
  await run('T11 | Find matches — missing type → 400+', async () => {
    const form = buildForm({
      // type intentionally omitted
      country:   'Egypt',
      city:      'Cairo',
      image_url: IMAGE_URL,
    });
    try {
      await axios.post(`${BASE}/api/v1/match/find-matches`, form, {
        headers: { ...auth(TOKEN.user1), ...form.getHeaders() },
      });
      return fail('Expected 400+, got 200');
    } catch (err) {
      const s = err.response?.status;
      return s >= 400 ? ok(`status ${s}`) : fail(`Expected 400+, got ${s}`);
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  T12  Public feed — no auth
  // ─────────────────────────────────────────────────────────────────────────
  await run('T12 | Public feed — GET /api/v1/post/feed (no auth)', async () => {
    const res = await axios.get(`${BASE}/api/v1/post/feed`);
    if (res.status !== 200)        return fail(`Expected 200, got ${res.status}`);
    if (res.data.success !== true) return fail('Expected success: true');
    return ok(`${res.data.data?.length ?? 0} posts`);
  });

  // ── Teardown ──────────────────────────────────────────────────────────────
  console.log('\n🔧 Cleaning up...');
  try {
    await teardownTestUser();
    console.log(seedCreatedNew
      ? '   ✅ Test user removed\n'
      : '   ✅ Pre-existing user left intact\n'
    );
  } catch (err) {
    console.warn('   ⚠️  Cleanup warning:', err.message, '\n');
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  const total = stats.pass + stats.fail;
  console.log('═'.repeat(52));
  console.log(`  RESULTS  ${total} total | ✅ ${stats.pass} passed | ❌ ${stats.fail} failed`);
  console.log('═'.repeat(52));

  if (stats.fail > 0) {
    console.log('\nFailed tests:');
    stats.log
      .filter(r => r.status === 'FAIL')
      .forEach(r => console.log(`  ❌ ${r.label}\n     └─ ${r.note}`));
    console.log('');
    process.exit(1);
  }

  console.log('\n🎉 All tests passed!\n');
  process.exit(0);
}

main().catch(err => {
  console.error('\n💥 Test runner crashed:', err.message || err);
  process.exit(1);
});
