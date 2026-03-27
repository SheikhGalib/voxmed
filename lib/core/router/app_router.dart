import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../widgets/voxmed_app_bar.dart';
import '../../widgets/voxmed_bottom_nav.dart';
import '../../widgets/ai_fab.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return _ShellScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/find-care',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FindCareScreen(),
          ),
        ),
        GoRoute(
          path: '/passport',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HealthPassportScreen(),
          ),
        ),
        GoRoute(
          path: '/health',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HealthAnalyticsScreen(),
          ),
        ),
      ],
    ),
    // Full-screen routes (no bottom nav)
    GoRoute(
      path: '/ai-assistant',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AiAssistantScreen(),
    ),
    GoRoute(
      path: '/doctor-booking',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DoctorBookingDetailScreen(),
    ),
    GoRoute(
      path: '/scan-records',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScanRecordsScreen(),
    ),
    GoRoute(
      path: '/prescription-renewals',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrescriptionRenewalsScreen(),
    ),
    GoRoute(
      path: '/live-consultation',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LiveConsultationScreen(),
    ),
    GoRoute(
      path: '/clinical-dashboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ClinicalDashboardScreen(),
    ),
    GoRoute(
      path: '/collaborative-hub',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CollaborativeHubScreen(),
    ),
    GoRoute(
      path: '/approval-queue',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ApprovalQueueScreen(),
    ),
  ],
);

class _ShellScreen extends StatelessWidget {
  final Widget child;

  const _ShellScreen({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _getIndex(location);

    return Scaffold(
      appBar: const VoxmedAppBar(),
      body: child,
      floatingActionButton: AiFab(
        onPressed: () => context.push('/ai-assistant'),
      ),
      bottomNavigationBar: VoxmedBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/find-care');
              break;
            case 2:
              context.go('/passport');
              break;
            case 3:
              context.go('/health');
              break;
          }
        },
      ),
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/find-care')) return 1;
    if (location.startsWith('/passport')) return 2;
    if (location.startsWith('/health')) return 3;
    return 0;
  }
}
