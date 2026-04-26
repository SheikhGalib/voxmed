import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/find_care_screen.dart';
import '../../screens/health_passport_screen.dart';
import '../../screens/health_analytics_screen.dart';
import '../../screens/ai_assistant_screen.dart';
import '../../screens/doctor_booking_detail_screen.dart';
import '../../screens/scan_records_screen.dart';
import '../../screens/prescription_renewals_screen.dart';
import '../../screens/live_consultation_screen.dart';
import '../../screens/clinical_dashboard_screen.dart';
import '../../screens/collaborative_hub_screen.dart';
import '../../screens/approval_queue_screen.dart';
import '../../screens/doctor_schedule_screen.dart';
import '../../screens/my_patients_screen.dart';
import '../../screens/patient_detail_screen.dart';
import '../../screens/doctor_chat_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/record_detail_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/voxmed_app_bar.dart';
import '../../widgets/voxmed_bottom_nav.dart';
import '../../widgets/ai_fab.dart';
import '../../core/config/supabase_config.dart';
import '../../core/constants/app_constants.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _patientShellKey = GlobalKey<NavigatorState>();
final _doctorShellKey = GlobalKey<NavigatorState>();
final _authRefreshListenable = _GoRouterRefreshStream(
  supabase.auth.onAuthStateChange,
);

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.login,
  refreshListenable: _authRefreshListenable,
  redirect: (context, state) {
    final isAuthenticated = supabase.auth.currentSession != null;
    final isAuthRoute =
        state.uri.path == AppRoutes.login ||
        state.uri.path == AppRoutes.register;

    // If not authenticated and not on auth route, redirect to login
    if (!isAuthenticated && !isAuthRoute) {
      return AppRoutes.login;
    }

    // If authenticated and on auth route, redirect to dashboard
    if (isAuthenticated && isAuthRoute) {
      // Check user role from metadata
      final user = supabase.auth.currentUser;
      final role = user?.userMetadata?['role'] as String?;
      if (role == 'doctor') {
        return AppRoutes.clinicalDashboard;
      }
      return AppRoutes.dashboard;
    }

    return null; // No redirect
  },
  routes: [
    // Auth routes (no shell)
    GoRoute(
      path: AppRoutes.login,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterScreen(),
    ),

    // Patient shell (bottom nav)
    ShellRoute(
      navigatorKey: _patientShellKey,
      builder: (context, state, child) {
        return _PatientShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: AppRoutes.findCare,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: FindCareScreen()),
        ),
        GoRoute(
          path: AppRoutes.passport,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HealthPassportScreen()),
        ),
        GoRoute(
          path: AppRoutes.health,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HealthAnalyticsScreen()),
        ),
      ],
    ),

    // Doctor shell (bottom nav — 4 tabs: Dashboard, Patients, Approvals, Collaborate)
    ShellRoute(
      navigatorKey: _doctorShellKey,
      builder: (context, state, child) {
        return _DoctorShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.clinicalDashboard,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ClinicalDashboardScreen()),
        ),
        GoRoute(
          path: AppRoutes.myPatients,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MyPatientsScreen()),
        ),
        GoRoute(
          path: AppRoutes.approvalQueue,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ApprovalQueueScreen()),
        ),
        GoRoute(
          path: AppRoutes.collaborativeHub,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CollaborativeHubScreen()),
        ),
      ],
    ),

    // Full-screen routes (no bottom nav)
    GoRoute(
      path: AppRoutes.profile,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiAssistant,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AiAssistantScreen(),
    ),
    GoRoute(
      path: AppRoutes.doctorBooking,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => DoctorBookingDetailScreen(
        doctorId: state.uri.queryParameters['doctorId'],
      ),
    ),
    GoRoute(
      path: AppRoutes.scanRecords,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScanRecordsScreen(),
    ),
    GoRoute(
      path: AppRoutes.prescriptionRenewals,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrescriptionRenewalsScreen(),
    ),
    GoRoute(
      path: AppRoutes.liveConsultation,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LiveConsultationScreen(),
    ),
    GoRoute(
      path: AppRoutes.patientDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => PatientDetailScreen(
        patientId: state.uri.queryParameters['patientId'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.doctorSchedule,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DoctorScheduleScreen(),
    ),
    GoRoute(
      path: AppRoutes.doctorChat,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => DoctorChatScreen(
        otherDoctorId: state.uri.queryParameters['doctorId'] ?? '',
        otherDoctorName: Uri.decodeComponent(
            state.uri.queryParameters['name'] ?? 'Doctor'),
        otherDoctorSpecialty: Uri.decodeComponent(
            state.uri.queryParameters['specialty'] ?? ''),
      ),
    ),
    GoRoute(
      path: AppRoutes.recordDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RecordDetailScreen(
        recordId: state.uri.queryParameters['recordId'] ?? '',
      ),
    ),
  ],
);

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    // Only notify when the session state actually changes (login/logout).
    // Firing on every auth event (e.g. token refresh) caused GoRouter to
    // internally call go() which wiped the push-navigation back stack,
    // making context.pop() fail on the register screen.
    _subscription = stream.asBroadcastStream().listen((_) {
      final nowHasSession = supabase.auth.currentSession != null;
      if (nowHasSession != _prevHasSession) {
        _prevHasSession = nowHasSession;
        notifyListeners();
      }
    });
  }

  bool _prevHasSession = supabase.auth.currentSession != null;
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Patient shell with AppBar, BottomNav, and AI FAB.
class _PatientShell extends StatelessWidget {
  final Widget child;

  const _PatientShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _getPatientIndex(location);

    return Scaffold(
      appBar: const VoxmedAppBar(),
      body: child,
      floatingActionButton: AiFab(
        showGreeting: currentIndex == 0,
        greetingText: 'Hi',
        onPressed: () => context.push(AppRoutes.aiAssistant),
      ),
      bottomNavigationBar: VoxmedBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.dashboard);
              break;
            case 1:
              context.go(AppRoutes.findCare);
              break;
            case 2:
              context.go(AppRoutes.passport);
              break;
            case 3:
              context.go(AppRoutes.health);
              break;
          }
        },
      ),
    );
  }

  int _getPatientIndex(String location) {
    if (location.startsWith('/find-care')) return 1;
    if (location.startsWith('/passport')) return 2;
    if (location.startsWith('/health')) return 3;
    return 0;
  }
}

/// Doctor shell with blue-themed bottom nav (4 tabs).
class _DoctorShell extends StatelessWidget {
  final Widget child;

  const _DoctorShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _getDoctorIndex(location);

    return Theme(
      data: Theme.of(context).copyWith(
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: DoctorColors.primaryContainer,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: DoctorColors.primary);
            }
            return const IconThemeData(color: Color(0xFF5A6061));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: DoctorColors.primary, fontWeight: FontWeight.w700, fontSize: 11);
            }
            return const TextStyle(color: Color(0xFF5A6061), fontSize: 11);
          }),
        ),
      ),
      child: Scaffold(
        appBar: const VoxmedAppBar(),
        body: child,
        floatingActionButton: AiFab(
          showGreeting: currentIndex == 0,
          greetingText: 'Hi',
          onPressed: () => context.push(AppRoutes.aiAssistant),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go(AppRoutes.clinicalDashboard);
                break;
              case 1:
                context.go(AppRoutes.myPatients);
                break;
              case 2:
                context.go(AppRoutes.approvalQueue);
                break;
              case 3:
                context.go(AppRoutes.collaborativeHub);
                break;
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Patients',
            ),
            NavigationDestination(
              icon: Icon(Icons.pending_actions_outlined),
              selectedIcon: Icon(Icons.pending_actions),
              label: 'Approvals',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Collaborate',
            ),
          ],
        ),
      ),
    );
  }

  int _getDoctorIndex(String location) {
    if (location.startsWith('/my-patients')) return 1;
    if (location.startsWith('/approval-queue')) return 2;
    if (location.startsWith('/collaborative-hub')) return 3;
    return 0;
  }
}
