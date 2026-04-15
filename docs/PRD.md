# **Product Requirements Document (PRD): VoxMed Connect**

## **1. Executive Summary & Vision**
**VoxMed Connect** is an integrated healthcare ecosystem designed to bridge the communication gap between patients and clinicians. Functioning as a closed-loop virtual health assistant, it utilizes a voice-activated adherence engine to track patient compliance in real-time. The platform features a cross-platform mobile app for patients and a comprehensive clinical dashboard for doctors, centralizing medical history to make it actionable.

**Objective:** Shift the virtual assistant from a passive tool to an active participant in patient recovery. The goal is to improve patient outcomes while drastically reducing the administrative burden on clinics through autonomous scheduling, collaborative data sharing, and AI-driven clinical notes.

---

## **2. Target Personas**
* **The Patient:** Individuals seeking seamless appointment booking, proactive health tracking, centralized medical records, and AI-guided triage to find the right care.
* **The Doctor:** Healthcare professionals needing real-time patient compliance data, automated administrative tools (SOAP notes, renewals), and seamless ways to manage unexpected schedule changes.

---

## **3. Core Problems Addressed**
* **The Compliance Gap:** Doctors typically have no way of knowing if a patient follows a prescribed regimen until their next follow-up.
* **Scheduling Friction & Logistics:** Late notifications for doctor absences lead to wasted time and lost health outcomes.
* **Siloed Data:** Critical medical history is scattered across different providers, making collaborative treatment difficult.
* **Administrative Burnout:** Doctors spend excessive time writing clinical notes and manually approving routine prescription renewals.

---

## **4. Feature Specifications: Patient Mobile App**

### **A. Smart Health Passport & Analytics**
* **Universal Record Access:** A secure section to view complete medical history, lab results, and past prescriptions.
* **Document Upload & OCR:** Users scan physical prescriptions or medical reports using their device camera. The image is securely uploaded to **Supabase Storage**. A **Supabase Edge Function** triggers the Gemini Vision API to extract structured data (medication name, dosage, doctor, date) and saves it to the passport.
* **Wearable Integration Dashboard:** Syncs with smartwatches to pull biometric data (e.g., resting heart rate, sleep quality) into an analytics dashboard.
* **Health Trends Visualization:** Displays charts mapping long-term health metrics and medication adherence derived from wearable data and OCR records.

### **B. Voice-Driven Adherence & Renewals**
* **Proactive Voice Tracker:** The app proactively asks the patient via voice at scheduled times if they have taken their medication. Responses are transcribed and evaluated via AI.
* **Automated Prescription Renewals:** When the adherence tracker detects a low medication supply, it automatically prompts the user to request a renewal, sending a direct approval request to the doctor's queue via **Supabase Realtime**.

### **C. AI Triage & Smart Booking**
* **AI Symptom Triage:** A conversational interface powered by Gemini. Patients describe their symptoms, and the AI guides them to the appropriate medical specialty and lists relevant doctors.
* **Advanced Directory Search:** Patients can search by hospital name to view a list of affiliated doctors, or filter by specialty, highest rating, and availability.
* **Autonomous Smart Rescheduling:** If a doctor triggers an "Emergency Absence," **Supabase Edge Functions** automatically run the rescheduling logic, booking the next available slot and notifying the patient via push notification.

---

## **5. Feature Specifications: Doctor Web/Tablet Portal**

### **A. Clinical Dashboard & Workflow**
* **Adherence Dashboard:** Before a consultation, doctors view a live "Compliance Score" derived from the patient's voice-tracked data.
* **Absence Trigger:** A one-click "Emergency Absence" button that initiates the backend auto-reschedule logic.
* **Prescription Approval Queue:** A centralized inbox allowing doctors to quickly review, approve, modify, or reject AI-generated medication renewal requests.

### **B. Live Consultation & Ambient Note-Taking (mediNote)**
* **Ambient Listening Integration:** An ambient listening feature activated during live consultations.
* **Auto-Generated SOAP Notes:** Audio is processed to automatically transcribe and format a standardized SOAP (Subjective, Objective, Assessment, Plan) note in real-time, allowing the doctor to focus entirely on the patient.

### **C. Collaborative Care Hub**
* **Multi-Doctor Sessions:** A consultation module where the primary doctor can share a patient's record with external specialists for collaborative treatment planning. Chat and updates are synced instantly using **Supabase Realtime**.
* **Full EHR Access:** Complete visibility into the patient's Universal Health Passport, including notes from collaborating doctors, OCR-extracted external records, and wearable analytics.

---

## **6. Technical Architecture & Integrations**

* **Frontend:**
  * Flutter (Android/iOS mobile apps).
  * Flutter Web or React (Doctor Web Dashboard).
  * State Management: Riverpod or BLoC.
* **Backend as a Service (BaaS): Supabase**
  * **Database:** Supabase PostgreSQL (Relational data for Users, Appointments, Medical Records).
  * **Authentication:** Supabase Auth (Managing Patient and Doctor roles, Row Level Security to protect patient data).
  * **Storage:** Supabase Storage (Securely storing profile photos, uploaded prescription images, and PDF reports).
  * **Serverless Logic:** Supabase Edge Functions (Deno). These will act as the secure middleman to hold API keys and execute business logic (e.g., calling the Gemini API, executing auto-rescheduling algorithms).
  * **Live Sync:** Supabase Realtime (WebSockets for live chat, instant appointment status updates, and collaborative doctor notes).
* **AI Processing Layer:**
  * **Google Gemini API:** Triggered exclusively via Supabase Edge Functions for conversational triage (NLP), OCR data extraction (Vision), and ambient SOAP note generation.

