/**
 * VoxMed — Bangladesh Hospitals & Doctors Seed Script
 * Run: node supabase/scripts/seed_bd_hospitals_doctors.js
 *
 * Creates:
 *  - 10 public medical college hospitals across Bangladesh
 *  - 2-3 approved doctors per hospital (email: firstname@gmail.com, pw: 123456)
 *  - Doctor schedules (Mon–Fri, 09:00–16:00)
 *  - 30-day adherence logs for jim@gmail.com & galib@gmail.com
 *  - Fixes Square Hospital phone
 */

const https = require('https');

const SUPABASE_URL = 'https://jedgnisrjwemhazherro.supabase.co';
const SERVICE_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImplZGduaXNyandlbWhhemhlcnJvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDYyMzI4NywiZXhwIjoyMDkwMTk5Mjg3fQ.3pgxaEwy_lLsTid2CoZbxVa-QgFp8dJnkpXjI75_ptQ';

// ─── HTTP helpers ─────────────────────────────────────────────────────────────
function apiRequest(path, method = 'GET', body = null, extraHeaders = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(SUPABASE_URL + path);
    const payload = body ? JSON.stringify(body) : null;
    const headers = {
      apikey: SERVICE_KEY,
      Authorization: 'Bearer ' + SERVICE_KEY,
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
      ...extraHeaders,
    };
    if (payload) headers['Content-Length'] = Buffer.byteLength(payload);

    const opts = {
      hostname: url.hostname,
      path: url.pathname + url.search,
      method,
      headers,
    };

    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: data ? JSON.parse(data) : null });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

const rest = {
  get: (path) => apiRequest('/rest/v1' + path),
  post: (path, body) => apiRequest('/rest/v1' + path, 'POST', body),
  patch: (path, body) => apiRequest('/rest/v1' + path, 'PATCH', body, { Prefer: 'return=minimal' }),
  upsert: (path, body) =>
    apiRequest('/rest/v1' + path, 'POST', body, {
      Prefer: 'resolution=merge-duplicates,return=representation',
    }),
};

async function createAuthUser(email, fullName) {
  const res = await apiRequest('/auth/v1/admin/users', 'POST', {
    email,
    password: '123456',
    email_confirm: true,
    user_metadata: { full_name: fullName, role: 'doctor' },
  });
  if (res.status !== 200 && res.status !== 201) {
    // User might already exist; try to look up by email
    if (res.body?.msg?.includes('already been registered') || res.body?.message?.includes('already')) {
      const lookup = await rest.get(`/profiles?email=eq.${encodeURIComponent(email)}&select=id,email`);
      if (lookup.body?.length) return lookup.body[0].id;
    }
    console.warn(`  ⚠ createAuthUser(${email}):`, res.body?.message || res.body?.msg || res.status);
    return null;
  }
  return res.body.id;
}

async function ensureProfile(userId, email, fullName) {
  // The DB trigger may have already created the profile; upsert to set name + role
  const r = await apiRequest(
    '/rest/v1/profiles',
    'POST',
    { id: userId, email, full_name: fullName, role: 'doctor' },
    { Prefer: 'resolution=merge-duplicates,return=minimal' },
  );
  return r.status < 300;
}

// ─── Data definitions ─────────────────────────────────────────────────────────

const HOSPITALS = [
  // Already in DB — only updating phone for Square Hospital
  // New Bangladesh public medical college hospitals:
  {
    id: 'bd000000-0000-0000-0000-000000000001',
    name: 'Sir Salimullah Medical College & Mitford Hospital',
    address: 'Mitford Road, Dhaka 1100',
    city: 'Dhaka',
    state: 'Dhaka Division',
    country: 'Bangladesh',
    phone: '+880-2-9558876',
    description: 'One of the oldest public medical college hospitals in Bangladesh, established 1858.',
    services: ['General Medicine', 'Surgery', 'Cardiology', 'Gynecology', 'Orthopedics', 'ENT'],
    latitude: 23.7101,
    longitude: 90.4053,
    status: 'approved',
    is_active: true,
    rating: 3.8,
  },
  {
    id: 'bd000000-0000-0000-0000-000000000002',
    name: 'Shaheed Suhrawardy Medical College Hospital',
    address: 'Sher-e-Bangla Nagar, Dhaka 1207',
    city: 'Dhaka',
    state: 'Dhaka Division',
    country: 'Bangladesh',
    phone: '+880-2-9126805',
    description: 'Major public teaching hospital in Dhaka providing tertiary care services.',
    services: ['Internal Medicine', 'Orthopedics', 'ENT', 'Ophthalmology', 'Psychiatry'],
    latitude: 23.7726,
    longitude: 90.3715,
    status: 'approved',
    is_active: true,
    rating: 3.7,
  },
  {
    id: 'bd000000-0000-0000-0000-000000000003',
    name: 'Rajshahi Medical College Hospital',
    address: 'Laxmipur, Rajshahi 6000',
    city: 'Rajshahi',
    state: 'Rajshahi Division',
    country: 'Bangladesh',
    phone: '+880-721-772150',
    description: 'Principal referral hospital for the Rajshahi division with 1000+ bed capacity.',
    services: ['Cardiology', 'Neurology', 'Surgery', 'Pediatrics', 'Radiology'],
    latitude: 24.3745,
    longitude: 88.6042,
    status: 'approved',
    is_active: true,
    rating: 3.6,
  },
  {
    id: 'bd000000-0000-0000-0000-000000000004',
    name: 'Khulna Medical College Hospital',
    address: 'D.K. Bose Road, Khulna 9000',
    city: 'Khulna',
    state: 'Khulna Division',
    country: 'Bangladesh',
    phone: '+880-41-720280',
    description: 'Serving the Khulna division with specialised surgery and obstetrics departments.',
    services: ['General Medicine', 'Surgery', 'Gynecology', 'Pediatrics', 'Dermatology'],
    latitude: 22.8456,
    longitude: 89.5403,
    status: 'approved',
    is_active: true,
    rating: 3.5,
  },
  {
    id: 'bd000000-0000-0000-0000-000000000005',
    name: 'Mymensingh Medical College Hospital',
    address: 'Mymensingh Sadar, Mymensingh 2200',
    city: 'Mymensingh',
    state: 'Mymensingh Division',
    country: 'Bangladesh',
    phone: '+880-91-65666',
    description: 'Major public hospital for Mymensingh division established 1924.',
    services: ['Internal Medicine', 'General Surgery', 'Obstetrics', 'Pediatrics'],
    latitude: 24.7471,
    longitude: 90.4203,
    status: 'approved',
    is_active: true,
    rating: 3.6,
  },
  {
    id: 'bd000000-0000-0000-0000-000000000006',
    name: 'Rangpur Medical College Hospital',
    address: 'Medical College Road, Rangpur 5400',
    city: 'Rangpur',
    state: 'Rangpur Division',
    country: 'Bangladesh',
    phone: '+880-521-64450',
    description: 'Tertiary care referral hospital for the northern Rangpur division.',
    services: ['Cardiology', 'Internal Medicine', 'Orthopedics', 'Neurology', 'ENT'],
    latitude: 25.7439,
    longitude: 89.2752,
    status: 'approved',
    is_active: true,
    rating: 3.5,
  },
  {
    id: 'bd000000-0000-0000-0000-000000000007',
    name: 'Cumilla Medical College Hospital',
    address: 'Kandirpar, Cumilla 3500',
    city: 'Cumilla',
    state: 'Chattogram Division',
    country: 'Bangladesh',
    phone: '999',
    description: 'Public medical college hospital serving Cumilla and surrounding districts.',
    services: ['General Medicine', 'Surgery', 'Gynecology', 'Radiology'],
    latitude: 23.4607,
    longitude: 91.1809,
    status: 'approved',
    is_active: true,
    rating: 3.4,
  },
  {
    id: 'bd000000-0000-0000-0000-000000000008',
    name: 'Barisal Sher-e-Bangla Medical College Hospital',
    address: 'Hospital Road, Barisal 8200',
    city: 'Barisal',
    state: 'Barishal Division',
    country: 'Bangladesh',
    phone: '+880-431-61609',
    description: 'The main referral hospital for Barishal division with trauma and ICU facilities.',
    services: ['Emergency', 'Trauma', 'Internal Medicine', 'Obstetrics', 'Pediatrics'],
    latitude: 22.7010,
    longitude: 90.3535,
    status: 'approved',
    is_active: true,
    rating: 3.5,
  },
];

const DOCTOR_DEFS = [
  // Sir Salimullah Medical College (bd000000...001)
  {
    firstName: 'asif',
    fullName: 'Asif Rahman',
    hospitalId: 'bd000000-0000-0000-0000-000000000001',
    specialty: 'Cardiology',
    fee: 1200,
    exp: 14,
    qualifications: ['MBBS', 'MD (Cardiology)', 'FCPS'],
  },
  {
    firstName: 'nasrin',
    fullName: 'Nasrin Akter',
    hospitalId: 'bd000000-0000-0000-0000-000000000001',
    specialty: 'Gynaecology & Obstetrics',
    fee: 1000,
    exp: 10,
    qualifications: ['MBBS', 'FCPS (Gynae)'],
  },
  {
    firstName: 'tariq',
    fullName: 'Tariq Hossain',
    hospitalId: 'bd000000-0000-0000-0000-000000000001',
    specialty: 'Neurology',
    fee: 1100,
    exp: 12,
    qualifications: ['MBBS', 'MD (Neurology)', 'FCPS'],
  },

  // Shaheed Suhrawardy (bd000000...002)
  {
    firstName: 'mamun',
    fullName: 'Mamun Rashid',
    hospitalId: 'bd000000-0000-0000-0000-000000000002',
    specialty: 'Orthopedics',
    fee: 1000,
    exp: 11,
    qualifications: ['MBBS', 'MS (Ortho)'],
  },
  {
    firstName: 'farhana',
    fullName: 'Farhana Haque',
    hospitalId: 'bd000000-0000-0000-0000-000000000002',
    specialty: 'ENT',
    fee: 800,
    exp: 8,
    qualifications: ['MBBS', 'DLO', 'FCPS (ENT)'],
  },
  {
    firstName: 'sumaiya',
    fullName: 'Sumaiya Islam',
    hospitalId: 'bd000000-0000-0000-0000-000000000002',
    specialty: 'Pediatrics',
    fee: 900,
    exp: 9,
    qualifications: ['MBBS', 'DCH', 'MD (Pediatrics)'],
  },

  // Rajshahi Medical College (bd000000...003)
  {
    firstName: 'sabbir',
    fullName: 'Sabbir Ahmed',
    hospitalId: 'bd000000-0000-0000-0000-000000000003',
    specialty: 'Internal Medicine',
    fee: 700,
    exp: 9,
    qualifications: ['MBBS', 'FCPS (Medicine)'],
  },
  {
    firstName: 'monira',
    fullName: 'Monira Khatun',
    hospitalId: 'bd000000-0000-0000-0000-000000000003',
    specialty: 'Radiology',
    fee: 650,
    exp: 7,
    qualifications: ['MBBS', 'DMRD'],
  },

  // Khulna Medical College (bd000000...004)
  {
    firstName: 'faruk',
    fullName: 'Faruk Islam',
    hospitalId: 'bd000000-0000-0000-0000-000000000004',
    specialty: 'General Medicine',
    fee: 700,
    exp: 8,
    qualifications: ['MBBS', 'FCPS (Medicine)'],
  },
  {
    firstName: 'sharmin',
    fullName: 'Sharmin Jahan',
    hospitalId: 'bd000000-0000-0000-0000-000000000004',
    specialty: 'Gynaecology & Obstetrics',
    fee: 700,
    exp: 7,
    qualifications: ['MBBS', 'FCPS (Gynae)'],
  },

  // Mymensingh Medical College (bd000000...005)
  {
    firstName: 'zahirul',
    fullName: 'Zahirul Islam',
    hospitalId: 'bd000000-0000-0000-0000-000000000005',
    specialty: 'General Surgery',
    fee: 700,
    exp: 10,
    qualifications: ['MBBS', 'MS (Surgery)', 'FCPS'],
  },
  {
    firstName: 'nilufar',
    fullName: 'Nilufar Ahmed',
    hospitalId: 'bd000000-0000-0000-0000-000000000005',
    specialty: 'Pediatrics',
    fee: 650,
    exp: 6,
    qualifications: ['MBBS', 'DCH'],
  },

  // Rangpur Medical College (bd000000...006)
  {
    firstName: 'rezaul',
    fullName: 'Rezaul Karim',
    hospitalId: 'bd000000-0000-0000-0000-000000000006',
    specialty: 'Orthopedics',
    fee: 650,
    exp: 8,
    qualifications: ['MBBS', 'MS (Ortho)'],
  },
  {
    firstName: 'rina',
    fullName: 'Rina Begum',
    hospitalId: 'bd000000-0000-0000-0000-000000000006',
    specialty: 'Internal Medicine',
    fee: 600,
    exp: 6,
    qualifications: ['MBBS', 'FCPS (Medicine)'],
  },

  // Cumilla Medical College (bd000000...007)
  {
    firstName: 'karim',
    fullName: 'Karim Hossain',
    hospitalId: 'bd000000-0000-0000-0000-000000000007',
    specialty: 'Neurology',
    fee: 650,
    exp: 7,
    qualifications: ['MBBS', 'MD (Neurology)'],
  },
  {
    firstName: 'taslima',
    fullName: 'Taslima Begum',
    hospitalId: 'bd000000-0000-0000-0000-000000000007',
    specialty: 'Dermatology',
    fee: 650,
    exp: 6,
    qualifications: ['MBBS', 'DDV'],
  },

  // Barisal Sher-e-Bangla Medical College (bd000000...008)
  {
    firstName: 'morshed',
    fullName: 'Morshed Ali',
    hospitalId: 'bd000000-0000-0000-0000-000000000008',
    specialty: 'Cardiology',
    fee: 700,
    exp: 9,
    qualifications: ['MBBS', 'MD (Cardiology)', 'FCPS'],
  },
  {
    firstName: 'roksana',
    fullName: 'Roksana Parvin',
    hospitalId: 'bd000000-0000-0000-0000-000000000008',
    specialty: 'Obstetrics',
    fee: 650,
    exp: 7,
    qualifications: ['MBBS', 'FCPS (Gynae)'],
  },

  // Dhaka Medical College Hospital (already exists: a1000000...001) — adding more doctors
  {
    firstName: 'tanvir',
    fullName: 'Tanvir Mahmud',
    hospitalId: 'a1000000-0000-0000-0000-000000000001',
    specialty: 'Dermatology',
    fee: 1000,
    exp: 9,
    qualifications: ['MBBS', 'DDV', 'FCPS (Derma)'],
  },
  {
    firstName: 'lubna',
    fullName: 'Lubna Sultana',
    hospitalId: 'a1000000-0000-0000-0000-000000000001',
    specialty: 'Ophthalmology',
    fee: 900,
    exp: 8,
    qualifications: ['MBBS', 'DO', 'FCPS (Ophtha)'],
  },

  // Chittagong General Hospital (already exists: a1000000...002) — adding more doctors
  {
    firstName: 'amin',
    fullName: 'Amin Chowdhury',
    hospitalId: 'a1000000-0000-0000-0000-000000000002',
    specialty: 'General Surgery',
    fee: 800,
    exp: 10,
    qualifications: ['MBBS', 'MS (Surgery)', 'FCPS'],
  },
  {
    firstName: 'rehana',
    fullName: 'Rehana Sultana',
    hospitalId: 'a1000000-0000-0000-0000-000000000002',
    specialty: 'Gynaecology & Obstetrics',
    fee: 700,
    exp: 8,
    qualifications: ['MBBS', 'FCPS (Gynae)'],
  },
];

// Days Mon-Fri = [1,2,3,4,5] in ISO weekday
const WEEKDAYS = [1, 2, 3, 4, 5];

// ─── Patient IDs for health insight seeding ──────────────────────────────────
const PATIENTS = [
  { id: '98c61d56-2247-4062-ae8d-62f4df4a20ae', email: 'jim@gmail.com' },
  { id: 'b2b678db-c9b6-401f-af56-e1e18951e629', email: 'galib@gmail.com' },
];

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  // ── 1. Fix Square Hospital phone ─────────────────────────────────────────
  console.log('\n[1] Fixing Square Hospital phone number...');
  await rest.patch(
    '/hospitals?id=eq.081c6e6f-c3a5-4ab8-bfb3-3bf3eab8d831',
    { phone: '+880-2-8159457', city: 'Panthapath', state: 'Dhaka Division' },
  );
  console.log('  ✔ Square Hospital phone updated to +880-2-8159457');

  // ── 2. Upsert new hospitals ───────────────────────────────────────────────
  console.log('\n[2] Upserting Bangladesh hospitals...');
  for (const h of HOSPITALS) {
    const r = await rest.upsert('/hospitals', h);
    if (r.status >= 300) {
      console.warn(`  ⚠ ${h.name}:`, r.body?.message || r.status);
    } else {
      console.log(`  ✔ ${h.name}`);
    }
  }

  // ── 3. Create doctor auth users + profiles + doctors rows ─────────────────
  console.log('\n[3] Creating doctor accounts...');
  const credentials = [];

  for (const doc of DOCTOR_DEFS) {
    const email = `${doc.firstName}@gmail.com`;
    process.stdout.write(`  Creating ${email} (${doc.fullName})... `);

    const userId = await createAuthUser(email, doc.fullName);
    if (!userId) {
      console.log('FAILED — skipping');
      continue;
    }
    await ensureProfile(userId, email, doc.fullName);

    // Insert or update doctors row
    const doctorBody = {
      profile_id: userId,
      hospital_id: doc.hospitalId,
      specialty: doc.specialty,
      consultation_fee: doc.fee,
      experience_years: doc.exp,
      qualifications: doc.qualifications,
      is_available: true,
      status: 'approved',
      approved_by_hospital: true,
    };
    const dr = await apiRequest(
      '/rest/v1/doctors?on_conflict=profile_id',
      'POST',
      doctorBody,
      { Prefer: 'resolution=merge-duplicates,return=representation' },
    );
    if (dr.status >= 300) {
      console.log(`FAILED doctors insert: ${dr.body?.message || dr.status}`);
      continue;
    }
    const doctorId = Array.isArray(dr.body) ? dr.body[0]?.id : dr.body?.id;
    console.log(`✔ (doctor id: ${doctorId})`);

    // Add Mon–Fri schedule
    if (doctorId) {
      for (const day of WEEKDAYS) {
        await apiRequest(
          '/rest/v1/doctor_schedules',
          'POST',
          {
            doctor_id: doctorId,
            day_of_week: day,
            start_time: '09:00',
            end_time: '16:00',
            slot_duration_minutes: 30,
            is_active: true,
          },
          { Prefer: 'resolution=merge-duplicates,return=minimal' },
        );
      }
    }

    credentials.push({ email, password: '123456', name: doc.fullName, specialty: doc.specialty, hospital: doc.hospitalId, fee: doc.fee });
  }

  // ── 4. Seed 30-day adherence logs for jim & galib ─────────────────────────
  console.log('\n[4] Seeding adherence logs for jim & galib...');

  // First get their medication schedules
  for (const patient of PATIENTS) {
    const sched = await rest.get(
      `/medication_schedules?patient_id=eq.${patient.id}&is_active=eq.true&select=id,medication_name,times_of_day,prescription_item_id`,
    );
    if (!sched.body?.length) {
      // Create a seed schedule for this patient if none exists
      const newSched = await rest.post('/medication_schedules', {
        patient_id: patient.id,
        medication_name: 'Metformin',
        dosage: '500mg',
        frequency: 'twice daily',
        times_of_day: ['08:00', '20:00'],
        days_of_week: null,
        is_active: true,
        notes: 'seed:30_day_adherence',
      });
      if (newSched.body?.length) sched.body = newSched.body;
      else { console.warn(`  ⚠ No schedules found for ${patient.email}`); continue; }
    }

    const schedules = sched.body;
    const now = new Date();
    const logs = [];

    // Random seed per patient for reproducibility
    let rng = patient.id.charCodeAt(0);
    const rand = () => { rng = (rng * 1664525 + 1013904223) & 0xffffffff; return (rng >>> 0) / 0xffffffff; };

    for (let dayOffset = 29; dayOffset >= 0; dayOffset--) {
      const date = new Date(now);
      date.setDate(date.getDate() - dayOffset);

      for (const schedule of schedules) {
        for (const timeStr of schedule.times_of_day) {
          const [h, m] = timeStr.split(':').map(Number);
          const scheduledTime = new Date(date);
          scheduledTime.setHours(h, m, 0, 0);

          // Skip future doses
          if (scheduledTime > now) continue;

          // 75% taken, 15% missed, 10% skipped
          const roll = rand();
          let status;
          if (roll < 0.75) status = 'taken';
          else if (roll < 0.90) status = 'missed';
          else status = 'skipped';

          // Skip doses from schedules without a prescription_item_id (DB constraint)
          if (!schedule.prescription_item_id) continue;

          logs.push({
            patient_id: patient.id,
            schedule_id: schedule.id,
            prescription_item_id: schedule.prescription_item_id,
            medication_name: schedule.medication_name,
            scheduled_time: scheduledTime.toISOString(),
            status,
            voice_transcript: 'seed:30_day_adherence',
          });
        }
      }
    }

    if (logs.length === 0) { console.log(`  ⚠ No logs to insert for ${patient.email}`); continue; }

    // Delete old seed logs
    await apiRequest(
      `/rest/v1/adherence_logs?patient_id=eq.${patient.id}&voice_transcript=eq.seed:30_day_adherence`,
      'DELETE',
      null,
      {},
    );

    // Insert in batches of 100
    for (let i = 0; i < logs.length; i += 100) {
      const batch = logs.slice(i, i + 100);
      const ins = await rest.post('/adherence_logs', batch);
      if (ins.status >= 300) console.warn(`  ⚠ batch insert error: ${ins.body?.message}`);
    }
    console.log(`  ✔ ${patient.email}: inserted ${logs.length} adherence log entries`);
  }

  // ── 5. Print credentials summary ─────────────────────────────────────────
  console.log('\n[5] Doctor credentials created:');
  console.table(credentials.map(c => ({ Email: c.email, Password: c.password, Name: c.name, Specialty: c.specialty, Fee: `৳${c.fee}` })));

  console.log('\n✅ Seed complete!');
}

main().catch(console.error);
