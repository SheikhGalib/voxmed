import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../providers/prescription_provider.dart';
import '../core/constants/app_constants.dart';

class ApprovalQueueScreen extends ConsumerStatefulWidget {
  const ApprovalQueueScreen({super.key});

  @override
  ConsumerState<ApprovalQueueScreen> createState() => _ApprovalQueueScreenState();
}

class _ApprovalQueueScreenState extends ConsumerState<ApprovalQueueScreen> {
  bool _isCardView = true;
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    final renewalsAsync = ref.watch(pendingRenewalsProvider);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Responsive.hPad(context), 16, Responsive.hPad(context), 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Approvals", style: GoogleFonts.manrope(fontSize: Responsive.fontSize(context, 26), fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text("Review and authorize renewal requests from patients in your care.", style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 20),
          _buildControls(renewalsAsync),
          const SizedBox(height: 16),
          _buildList(context, renewalsAsync),
        ],
      ),
    );
  }

  Widget _buildControls(AsyncValue<List<Map<String, dynamic>>> renewalsAsync) {
    final count = renewalsAsync.valueOrNull?.length ?? 0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: count > 0 ? DoctorColors.statOrange.withValues(alpha: 0.1) : DoctorColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text("$count pending", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: count > 0 ? DoctorColors.statOrange : DoctorColors.primary)),
        ),
        const Spacer(),
        InkWell(
          onTap: () => setState(() => _newestFirst = !_newestFirst),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(_newestFirst ? Icons.arrow_downward : Icons.arrow_upward, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(_newestFirst ? "Newest" : "Oldest", style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            _ViewToggleBtn(icon: Icons.view_agenda_outlined, active: _isCardView, onTap: () => setState(() => _isCardView = true)),
            _ViewToggleBtn(icon: Icons.format_list_bulleted, active: !_isCardView, onTap: () => setState(() => _isCardView = false)),
          ]),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, AsyncValue<List<Map<String, dynamic>>> renewalsAsync) {
    return renewalsAsync.when(
      data: (renewals) {
        if (renewals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Column(children: [
              Icon(Icons.check_circle_outline, size: 56, color: DoctorColors.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 14),
              Text("All caught up!", style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
              Text("No pending renewal requests.", style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
            ])),
          );
        }
        final sorted = List<Map<String, dynamic>>.from(renewals);
        sorted.sort((a, b) {
          final da = DateTime.tryParse(a["requested_at"] ?? "") ?? DateTime(2000);
          final db = DateTime.tryParse(b["requested_at"] ?? "") ?? DateTime(2000);
          return _newestFirst ? db.compareTo(da) : da.compareTo(db);
        });
        if (_isCardView) {
          return Column(children: sorted.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ApprovalCard(renewal: r, onAction: (s) => _handleAction(context, r["id"] as String, s), onTap: () => _showDetail(context, r)),
          )).toList());
        } else {
          return Column(children: sorted.map((r) => _ApprovalListRow(renewal: r, onTap: () => _showDetail(context, r))).toList());
        }
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())),
      error: (_, __) => Center(child: Text("Failed to load renewals", style: GoogleFonts.inter(color: AppColors.error))),
    );
  }

  Future<void> _handleAction(BuildContext context, String renewalId, String status) async {
    try {
      final repo = ref.read(prescriptionRepositoryProvider);
      final s = status == "approved" ? RenewalStatus.approved : RenewalStatus.rejected;
      await repo.updateRenewalStatus(renewalId, s);
      ref.invalidate(pendingRenewalsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == "approved" ? "Renewal approved." : "Renewal denied."),
          backgroundColor: status == "approved" ? DoctorColors.statGreen : AppColors.onSurfaceVariant,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error));
      }
    }
  }

  void _showDetail(BuildContext context, Map<String, dynamic> renewal) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => _ApprovalDetailSheet(renewal: renewal, onAction: (s) => _handleAction(context, renewal["id"] as String, s)),
    );
  }
}

// ─── Card View ────────────────────────────────────────────────────────────────

class _ApprovalCard extends StatelessWidget {
  final Map<String, dynamic> renewal;
  final void Function(String) onAction;
  final VoidCallback onTap;
  const _ApprovalCard({required this.renewal, required this.onAction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final patientName = renewal["profiles"]?["full_name"] ?? "Unknown";
    final items = renewal["prescriptions"]?["prescription_items"] as List? ?? [];
    final medication = items.isNotEmpty ? "${items.first["medication_name"]} ${items.first["dosage"] ?? ""}".trim() : "Medication";
    final requestedAt = DateTime.tryParse(renewal["requested_at"] ?? "");
    final dateStr = requestedAt != null ? DateFormat("d MMM yyyy, h:mm a").format(requestedAt.toLocal()) : "—";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DoctorColors.border, width: 1),
          boxShadow: [BoxShadow(color: DoctorColors.primary.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 22, backgroundColor: DoctorColors.primaryContainer,
              child: Text(patientName.isNotEmpty ? patientName[0].toUpperCase() : "?",
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: DoctorColors.primary))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(patientName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              Text(medication, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: DoctorColors.statOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text("Pending", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: DoctorColors.statOrange)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => onAction("rejected"),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Color(0xFFE0E0E0))),
              child: Text("Deny", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => onAction("approved"),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), backgroundColor: DoctorColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text("Approve", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ─── List Row ─────────────────────────────────────────────────────────────────

class _ApprovalListRow extends StatelessWidget {
  final Map<String, dynamic> renewal;
  final VoidCallback onTap;
  const _ApprovalListRow({required this.renewal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final patientName = renewal["profiles"]?["full_name"] ?? "Unknown";
    final items = renewal["prescriptions"]?["prescription_items"] as List? ?? [];
    final medication = items.isNotEmpty ? (items.first["medication_name"] as String? ?? "Medication") : "Medication";
    final requestedAt = DateTime.tryParse(renewal["requested_at"] ?? "");
    final dateStr = requestedAt != null ? DateFormat("d MMM").format(requestedAt.toLocal()) : "—";

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
        child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: DoctorColors.primaryContainer,
            child: Text(patientName.isNotEmpty ? patientName[0].toUpperCase() : "?",
              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: DoctorColors.primary))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(patientName, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            Text(medication, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
          ])),
          Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF5A6061)),
        ]),
      ),
    );
  }
}

// ─── Detail Sheet ─────────────────────────────────────────────────────────────

class _ApprovalDetailSheet extends StatelessWidget {
  final Map<String, dynamic> renewal;
  final void Function(String) onAction;
  const _ApprovalDetailSheet({required this.renewal, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final patientName = renewal["profiles"]?["full_name"] ?? "Unknown";
    final prescription = renewal["prescriptions"] as Map<String, dynamic>? ?? {};
    final items = prescription["prescription_items"] as List? ?? [];
    final diagnosis = prescription["diagnosis"] as String? ?? "N/A";
    final reason = renewal["reason"] as String? ?? "Renewal requested by patient";
    final requestedAt = DateTime.tryParse(renewal["requested_at"] ?? "");
    final dateStr = requestedAt != null ? DateFormat("EEEE, d MMMM yyyy").format(requestedAt.toLocal()) : "—";

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            CircleAvatar(radius: 24, backgroundColor: DoctorColors.primaryContainer,
              child: Text(patientName.isNotEmpty ? patientName[0].toUpperCase() : "?",
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: DoctorColors.primary))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(patientName, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              Text("Renewal request \u2022 $dateStr", style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _detailSection("Reason", reason),
            const SizedBox(height: 16),
            _detailSection("Diagnosis", diagnosis),
            const SizedBox(height: 16),
            if (items.isNotEmpty) ...[
              Text("Medications", style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              const SizedBox(height: 10),
              ...items.map((item) => _MedRow(item: item as Map<String, dynamic>)),
              const SizedBox(height: 16),
            ],
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () { Navigator.of(context).pop(); onAction("rejected"); },
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), side: const BorderSide(color: Color(0xFFE0E0E0))),
                child: Text("Deny", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () { Navigator.of(context).pop(); onAction("approved"); },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: DoctorColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text("Approve", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              )),
            ]),
          ]),
        )),
      ]),
    );
  }

  Widget _detailSection(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface, height: 1.4)),
    ]);
  }
}

class _MedRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _MedRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item["medication_name"] as String? ?? "";
    final dosage = item["dosage"] as String? ?? "";
    final freq = item["frequency"] as String? ?? "";
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DoctorColors.lightBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: DoctorColors.border)),
      child: Row(children: [
        const Icon(Icons.medication_outlined, size: 18, color: DoctorColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          if (dosage.isNotEmpty || freq.isNotEmpty)
            Text("$dosage${dosage.isNotEmpty && freq.isNotEmpty ? " \u00b7 " : ""}$freq", style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
        ])),
      ]),
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ViewToggleBtn({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: active ? DoctorColors.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: active ? DoctorColors.primary : AppColors.onSurfaceVariant),
      ),
    );
  }
}
