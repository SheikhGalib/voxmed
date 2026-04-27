/**
 * VoxMed — Migration 012: Add missing enum values
 * Uses the Supabase Management API to run raw SQL.
 *
 * Usage:
 *   set SUPABASE_PAT=<your-personal-access-token>
 *   node supabase/scripts/run_migration_012.js
 *
 * Get your PAT at: https://supabase.com/dashboard/account/tokens
 */

const https = require('https');

const PROJECT_REF = 'jedgnisrjwemhazherro';
const PAT = process.env.SUPABASE_PAT;

if (!PAT) {
  console.error('');
  console.error('ERROR: SUPABASE_PAT environment variable is not set.');
  console.error('');
  console.error('Get your personal access token at:');
  console.error('  https://supabase.com/dashboard/account/tokens');
  console.error('');
  console.error('Then run:');
  console.error('  $env:SUPABASE_PAT="your-token-here"');
  console.error('  node supabase/scripts/run_migration_012.js');
  console.error('');
  console.error('Or run the SQL manually in the Supabase SQL editor:');
  console.error('  https://supabase.com/dashboard/project/' + PROJECT_REF + '/sql/new');
  console.error('');
  console.error("SQL to run:");
  console.error("  ALTER TYPE renewal_status ADD VALUE IF NOT EXISTS 'follow_up';");
  console.error("  ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'renewal_follow_up';");
  console.error("  ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'appointment_completed';");
  console.error('');
  process.exit(1);
}

const SQL = `
ALTER TYPE renewal_status ADD VALUE IF NOT EXISTS 'follow_up';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'renewal_follow_up';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'appointment_completed';
`;

function runQuery(sql) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ query: sql });
    const options = {
      hostname: 'api.supabase.com',
      path: `/v1/projects/${PROJECT_REF}/database/query`,
      method: 'POST',
      headers: {
        Authorization: `Bearer ${PAT}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data || '{}'));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

(async () => {
  console.log('Running migration 012: adding missing enum values...');
  try {
    const result = await runQuery(SQL);
    console.log('');
    console.log('✓ Migration applied successfully.');
    if (result && result.length) console.log('Result:', JSON.stringify(result, null, 2));
  } catch (err) {
    console.error('');
    console.error('✗ Migration failed:', err.message);
    console.error('');
    console.error('You can run the SQL manually in the Supabase SQL editor:');
    console.error('  https://supabase.com/dashboard/project/' + PROJECT_REF + '/sql/new');
    process.exit(1);
  }
})();
