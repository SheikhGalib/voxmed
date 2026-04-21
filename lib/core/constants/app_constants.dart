/// Route paths used by GoRouter.
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';

  // Patient shell tabs
  static const String dashboard = '/';
  static const String findCare = '/find-care';
  static const String passport = '/passport';
  static const String health = '/health';

  // Patient full-screen
  static const String aiAssistant = '/ai-assistant';
  static const String doctorBooking = '/doctor-booking';
  static const String scanRecords = '/scan-records';
  static const String prescriptionRenewals = '/prescription-renewals';
  static const String profile = '/profile';

  // Doctor shell tabs
  static const String clinicalDashboard = '/clinical-dashboard';
  static const String approvalQueue = '/approval-queue';
  static const String collaborativeHub = '/collaborative-hub';
  static const String liveConsultation = '/live-consultation';
}

/// Doctor approval status values (mirrors doctor_status enum in DB).
class DoctorStatus {
  DoctorStatus._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

/// Hospital approval status values (mirrors hospital_status enum in DB).
class HospitalStatus {
  HospitalStatus._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

/// Supabase table names — single source of truth.
class Tables {
  Tables._();

  static const String profiles = 'profiles';
  static const String hospitals = 'hospitals';
  static const String doctors = 'doctors';

  /// View: only approved doctors visible to patients.
  static const String publicDoctors = 'public_doctors';
  static const String doctorSchedules = 'doctor_schedules';
  static const String doctorAbsences = 'doctor_absences';
  static const String appointments = 'appointments';
  static const String medicalRecords = 'medical_records';
  static const String prescriptions = 'prescriptions';
  static const String prescriptionItems = 'prescription_items';
  static const String prescriptionRenewals = 'prescription_renewals';
  static const String adherenceLogs = 'adherence_logs';
  static const String aiConversations = 'ai_conversations';
  static const String aiMessages = 'ai_messages';
  static const String consultationSessions = 'consultation_sessions';
  static const String consultationMembers = 'consultation_members';
  static const String consultationMessages = 'consultation_messages';
  static const String notifications = 'notifications';
  static const String reviews = 'reviews';
  static const String wearableData = 'wearable_data';
}

/// Storage bucket names.
class Buckets {
  Buckets._();

  static const String avatars = 'avatars';
  static const String reports = 'reports';
  static const String prescriptions = 'prescriptions';
}

/// User roles matching the database `user_role` enum.
enum UserRole {
  patient,
  doctor;

  String get value => name;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.patient,
    );
  }
}

/// Appointment status matching the database `appointment_status` enum.
enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
  rescheduled;

  String get value {
    switch (this) {
      case AppointmentStatus.inProgress:
        return 'in_progress';
      case AppointmentStatus.noShow:
        return 'no_show';
      default:
        return name;
    }
  }

  static AppointmentStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return AppointmentStatus.inProgress;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => AppointmentStatus.scheduled,
        );
    }
  }
}

/// Appointment type matching the database `appointment_type` enum.
enum AppointmentType {
  inPerson,
  video,
  followUp;

  String get value {
    switch (this) {
      case AppointmentType.inPerson:
        return 'in_person';
      case AppointmentType.followUp:
        return 'follow_up';
      default:
        return name;
    }
  }

  static AppointmentType fromString(String value) {
    switch (value) {
      case 'in_person':
        return AppointmentType.inPerson;
      case 'follow_up':
        return AppointmentType.followUp;
      default:
        return AppointmentType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => AppointmentType.inPerson,
        );
    }
  }
}

/// Medical record type matching the database `record_type` enum.
enum RecordType {
  prescription,
  labResult,
  radiology,
  consultationNote,
  dischargeSummary,
  other;

  String get value {
    switch (this) {
      case RecordType.labResult:
        return 'lab_result';
      case RecordType.consultationNote:
        return 'consultation_note';
      case RecordType.dischargeSummary:
        return 'discharge_summary';
      default:
        return name;
    }
  }

  static RecordType fromString(String value) {
    switch (value) {
      case 'lab_result':
        return RecordType.labResult;
      case 'consultation_note':
        return RecordType.consultationNote;
      case 'discharge_summary':
        return RecordType.dischargeSummary;
      default:
        return RecordType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => RecordType.other,
        );
    }
  }
}

/// Prescription status matching the database `prescription_status` enum.
enum PrescriptionStatus {
  active,
  completed,
  cancelled;

  String get value => name;

  static PrescriptionStatus fromString(String value) {
    return PrescriptionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PrescriptionStatus.active,
    );
  }
}

/// Renewal request status matching the database `renewal_status` enum.
enum RenewalStatus {
  pending,
  approved,
  rejected,
  modified;

  String get value => name;

  static RenewalStatus fromString(String value) {
    return RenewalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RenewalStatus.pending,
    );
  }
}

/// Adherence status matching the database `adherence_status` enum.
enum AdherenceStatus {
  pending,
  taken,
  skipped,
  missed;

  String get value => name;

  static AdherenceStatus fromString(String value) {
    return AdherenceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AdherenceStatus.pending,
    );
  }
}

/// Notification type matching the database `notification_type` enum.
enum NotificationType {
  appointmentReminder,
  appointmentRescheduled,
  appointmentCancelled,
  medicationReminder,
  renewalRequest,
  renewalApproved,
  renewalRejected,
  newLabResult,
  consultationInvite,
  aiTriageResult,
  doctorAbsence,
  general;

  String get value {
    // Convert camelCase to snake_case
    return name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }

  static NotificationType fromString(String value) {
    // Convert snake_case to camelCase for matching
    final camel = value.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (m) => m.group(1)!.toUpperCase(),
    );
    return NotificationType.values.firstWhere(
      (e) => e.name == camel,
      orElse: () => NotificationType.general,
    );
  }
}
