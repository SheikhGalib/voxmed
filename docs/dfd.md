# VoxMed Connect — Data Flow Diagrams

> **Last Updated:** 2026-03-28

---

## Table of Contents

1. [Context Diagram (Level -1)](#1-context-diagram)
2. [Level-0 DFD](#2-level-0-dfd)
3. [Level-1 DFDs](#3-level-1-dfds)

---

## 1. Context Diagram

The highest-level view showing VoxMed Connect as a single system interacting with external entities.

```mermaid
flowchart TB
    P["👤 Patient"]
    D["🩺 Doctor"]
    G["🤖 Google Gemini API"]
    W["⌚ Wearable Devices"]
    N["🔔 Push Notification Service"]

    P -->|"Sign up, book appointments,\nupload records, chat with AI,\ntrack medications"| V["VoxMed Connect\nSystem"]
    V -->|"Appointment confirmations,\nhealth data, AI triage results,\nmedication reminders"| P

    D -->|"Manage schedule, view patients,\napprove renewals, collaborate"| V
    V -->|"Patient compliance data,\nrenewal requests, SOAP notes"| D

    V -->|"Symptom text, prescription images,\nconsultation audio"| G
    G -->|"Triage results, OCR data,\nSOAP notes"| V

    W -->|"Heart rate, blood pressure,\nsleep data, SpO2"| V

    V -->|"Reminders, alerts,\nrescheduling notices"| N
    N -->|"Delivery status"| V
```

### External Entities

| Entity                    | Description                                                   |
|---------------------------|---------------------------------------------------------------|
| **Patient**               | End user who manages health records, books appointments, and interacts with AI |
| **Doctor**                | Clinician who manages schedules, views patient data, approves prescriptions |
| **Google Gemini API**     | AI service for OCR extraction, symptom triage, and SOAP note generation |
| **Wearable Devices**     | Smartwatches/rings that provide biometric data (Phase 2+)     |
| **Push Notification Service** | FCM/APNs for delivering reminders and alerts               |

---

## 2. Level-0 DFD

Decomposes the VoxMed system into its major processing subsystems.

```mermaid
flowchart TB
    P["👤 Patient"]
    D["🩺 Doctor"]
    G["🤖 Gemini API"]

    subgraph VoxMed["VoxMed Connect"]
        direction TB
        P1["1.0\nAuthentication\n& Profile"]
        P2["2.0\nAppointment\nManagement"]
        P3["3.0\nHealth Passport\n& Records"]
        P4["4.0\nPrescription\n& Adherence"]
        P5["5.0\nAI Triage\nAssistant"]
        P6["6.0\nDoctor Clinical\nTools"]
        P7["7.0\nCollaborative\nCare"]
        P8["8.0\nNotification\nEngine"]
    end

    DB[("Supabase\nPostgreSQL")]
    ST[("Supabase\nStorage")]

    P -->|"Credentials, profile data"| P1
    P1 -->|"JWT token, profile"| P
    P1 <-->|"profiles"| DB

    P -->|"Booking request"| P2
    P2 -->|"Confirmation"| P
    D -->|"Schedule, absence"| P2
    P2 <-->|"appointments,\ndoctor_schedules"| DB

    P -->|"Upload scan"| P3
    P3 -->|"Extracted data"| P
    P3 <-->|"medical_records"| DB
    P3 <-->|"Images, PDFs"| ST
    P3 -->|"Prescription image"| G
    G -->|"OCR result"| P3

    P -->|"Adherence response"| P4
    P4 -->|"Reminders"| P
    D -->|"Approve/reject"| P4
    P4 <-->|"prescriptions,\nadherence_logs,\nrenewal_requests"| DB

    P -->|"Symptom description"| P5
    P5 -->|"Triage + doctor suggestions"| P
    P5 -->|"Prompt"| G
    G -->|"AI response"| P5
    P5 <-->|"ai_conversations,\nai_messages"| DB

    D -->|"View patients"| P6
    P6 -->|"Compliance data,\nschedule"| D
    P6 <-->|"doctors,\nappointments,\nadherence_logs"| DB

    D -->|"Create session,\ninvite specialist"| P7
    P7 -->|"Shared patient data,\nchat messages"| D
    P7 <-->|"consultation_sessions,\nconsultation_members,\nconsultation_messages"| DB

    P8 -->|"Push notifications"| P
    P8 -->|"Push notifications"| D
    P8 <-->|"notifications"| DB
```

### Process Descriptions

| Process | Name                          | Description                                                |
|---------|-------------------------------|------------------------------------------------------------|
| 1.0     | Authentication & Profile      | User registration, login, role assignment, profile management |
| 2.0     | Appointment Management        | Search doctors/hospitals, book/cancel/reschedule appointments |
| 3.0     | Health Passport & Records     | Upload, store, and OCR-process medical documents            |
| 4.0     | Prescription & Adherence      | Manage prescriptions, track medication compliance, handle renewals |
| 5.0     | AI Triage Assistant           | Conversational symptom analysis and doctor recommendation   |
| 6.0     | Doctor Clinical Tools         | Doctor dashboard, schedule management, patient compliance views |
| 7.0     | Collaborative Care            | Multi-doctor consultation sessions with realtime messaging  |
| 8.0     | Notification Engine           | Medication reminders, appointment alerts, system notifications |

### Data Stores

| Store            | Description                                                   |
|------------------|---------------------------------------------------------------|
| Supabase PostgreSQL | All relational data (19 tables as defined in database_schema.md) |
| Supabase Storage | Binary files (avatars, report images, prescription scans)     |

---

## 3. Level-1 DFDs

### 3.1 Process 1.0 — Authentication & Profile

```mermaid
flowchart LR
    P["👤 User"]

    P -->|"Email, password, role"| P1_1["1.1\nRegister\nUser"]
    P1_1 -->|"Insert"| AUTH[("auth.users")]
    AUTH -->|"Trigger"| P1_2["1.2\nCreate\nProfile"]
    P1_2 -->|"Insert"| PROF[("profiles")]

    P -->|"Email, password"| P1_3["1.3\nLogin\nUser"]
    P1_3 -->|"Verify"| AUTH
    P1_3 -->|"JWT + role"| P

    P -->|"Update info"| P1_4["1.4\nUpdate\nProfile"]
    P1_4 -->|"Update"| PROF
    P1_4 -->|"Upload avatar"| ST[("avatars\nbucket")]

    P1_3 -->|"Check role"| P1_5["1.5\nRoute by\nRole"]
    P1_5 -->|"Patient shell"| PS["Patient Dashboard"]
    P1_5 -->|"Doctor shell"| DS["Doctor Dashboard"]
```

---

### 3.2 Process 2.0 — Appointment Management

```mermaid
flowchart LR
    P["👤 Patient"]
    D["🩺 Doctor"]

    P -->|"Search query"| P2_1["2.1\nSearch\nDoctors &\nHospitals"]
    P2_1 -->|"Read"| HOSP[("hospitals")]
    P2_1 -->|"Read"| DOC[("doctors")]
    P2_1 -->|"Results"| P

    P -->|"Select doctor + slot"| P2_2["2.2\nBook\nAppointment"]
    P2_2 -->|"Check"| SCHED[("doctor_schedules")]
    P2_2 -->|"Insert"| APPT[("appointments")]
    P2_2 -->|"Confirmation"| P

    D -->|"Mark absent"| P2_3["2.3\nHandle\nAbsence"]
    P2_3 -->|"Insert"| ABS[("doctor_absences")]
    P2_3 -->|"Trigger"| P2_4["2.4\nAuto\nReschedule"]
    P2_4 -->|"Update"| APPT
    P2_4 -->|"Notify"| P

    D -->|"Create/update slots"| P2_5["2.5\nManage\nSchedule"]
    P2_5 -->|"Upsert"| SCHED
```

---

### 3.3 Process 3.0 — Health Passport & Records

```mermaid
flowchart LR
    P["👤 Patient"]
    G["🤖 Gemini API"]

    P -->|"Camera capture"| P3_1["3.1\nUpload\nDocument"]
    P3_1 -->|"Store image"| ST[("reports /\nprescriptions\nbucket")]
    P3_1 -->|"Image URL"| P3_2["3.2\nOCR\nExtraction"]

    P3_2 -->|"Image data"| G
    G -->|"Structured JSON"| P3_2
    P3_2 -->|"Insert"| MR[("medical_records")]

    P -->|"View records"| P3_3["3.3\nList\nRecords"]
    P3_3 -->|"Read"| MR
    P3_3 -->|"Records list"| P

    P -->|"View details"| P3_4["3.4\nRecord\nDetail"]
    P3_4 -->|"Read"| MR
    P3_4 -->|"Read file"| ST
    P3_4 -->|"Full record + file"| P
```

---

### 3.4 Process 4.0 — Prescription & Adherence

```mermaid
flowchart TB
    P["👤 Patient"]
    D["🩺 Doctor"]

    D -->|"Issue prescription"| P4_1["4.1\nCreate\nPrescription"]
    P4_1 -->|"Insert"| RX[("prescriptions")]
    P4_1 -->|"Insert items"| RXI[("prescription_items")]

    P4_1 -->|"Generate schedule"| P4_2["4.2\nSchedule\nReminders"]
    P4_2 -->|"Insert"| ADH[("adherence_logs")]
    P4_2 -->|"Push notification"| P

    P -->|"Taken / Skipped"| P4_3["4.3\nLog\nAdherence"]
    P4_3 -->|"Update"| ADH

    P4_3 -->|"Check remaining"| P4_4["4.4\nAuto Renewal\nCheck"]
    P4_4 -->|"Low supply?"| P4_5["4.5\nRequest\nRenewal"]
    P4_5 -->|"Insert"| REN[("prescription_renewals")]
    P4_5 -->|"Notify"| D

    D -->|"Approve/Reject"| P4_6["4.6\nProcess\nRenewal"]
    P4_6 -->|"Update"| REN
    P4_6 -->|"Notify result"| P
```

---

### 3.5 Process 5.0 — AI Triage Assistant

```mermaid
flowchart LR
    P["👤 Patient"]
    G["🤖 Gemini API"]

    P -->|"Start chat"| P5_1["5.1\nCreate\nConversation"]
    P5_1 -->|"Insert"| CONV[("ai_conversations")]

    P -->|"Describe symptoms"| P5_2["5.2\nSend\nMessage"]
    P5_2 -->|"Insert user msg"| MSG[("ai_messages")]
    P5_2 -->|"Prompt + context"| G

    G -->|"AI response"| P5_3["5.3\nProcess\nResponse"]
    P5_3 -->|"Insert assistant msg"| MSG
    P5_3 -->|"Update triage"| CONV
    P5_3 -->|"Response + suggestions"| P

    P5_3 -->|"Triage complete?"| P5_4["5.4\nSuggest\nDoctors"]
    P5_4 -->|"Query by specialty"| DOC[("doctors")]
    P5_4 -->|"Doctor list"| P
```

---

### 3.6 Process 6.0 — Doctor Clinical Tools

```mermaid
flowchart LR
    D["🩺 Doctor"]

    D -->|"View dashboard"| P6_1["6.1\nLoad\nDashboard"]
    P6_1 -->|"Read"| APPT[("appointments")]
    P6_1 -->|"Read"| ADH[("adherence_logs")]
    P6_1 -->|"Read"| REN[("prescription_renewals")]
    P6_1 -->|"Stats + schedule"| D

    D -->|"Select patient"| P6_2["6.2\nView Patient\nPassport"]
    P6_2 -->|"Read"| MR[("medical_records")]
    P6_2 -->|"Read"| RX[("prescriptions")]
    P6_2 -->|"Read"| PROF[("profiles")]
    P6_2 -->|"Full patient data"| D

    D -->|"Compliance query"| P6_3["6.3\nCalculate\nCompliance"]
    P6_3 -->|"Read"| ADH
    P6_3 -->|"Score + breakdown"| D
```

---

### 3.7 Process 7.0 — Collaborative Care

```mermaid
flowchart LR
    D1["🩺 Primary\nDoctor"]
    D2["🩺 Specialist"]

    D1 -->|"Create session"| P7_1["7.1\nCreate\nSession"]
    P7_1 -->|"Insert"| CS[("consultation_sessions")]
    P7_1 -->|"Insert self"| CM[("consultation_members")]

    D1 -->|"Invite specialist"| P7_2["7.2\nInvite\nMember"]
    P7_2 -->|"Insert"| CM
    P7_2 -->|"Notify"| D2

    D1 -->|"Send message"| P7_3["7.3\nRealtime\nChat"]
    D2 -->|"Send message"| P7_3
    P7_3 -->|"Insert (Realtime)"| CMSG[("consultation_messages")]
    P7_3 -->|"Live updates"| D1
    P7_3 -->|"Live updates"| D2

    D1 -->|"Share records"| P7_4["7.4\nShare Patient\nData"]
    P7_4 -->|"Read"| MR[("medical_records")]
    P7_4 -->|"Records"| D2
```

---

## Summary

| Diagram       | Purpose                                        | Key Insight                                          |
|---------------|-------------------------------------------------|------------------------------------------------------|
| Context       | System boundary and external actors              | 5 external entities interact with VoxMed             |
| Level-0       | Major subsystems and data stores                 | 8 core processes, 2 data stores (DB + Storage)       |
| Level-1 (×7)  | Internal data flow within each subsystem         | Shows exact tables touched and data transformations  |

> **Reference:** See [database_schema.md](./database_schema.md) for full table definitions and [development_plan.md](./development_plan.md) for implementation phasing.
