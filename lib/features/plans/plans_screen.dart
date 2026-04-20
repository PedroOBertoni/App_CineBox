import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/plan_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();

  List<PlanModel> _plans = [];
  UserModel? _user;
  bool _loading = true;
  String? _updatingPlanId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final results = await Future.wait([
      _firestore.getPlans(),
      _auth.getUserData(uid),
    ]);

    if (!mounted) return;
    setState(() {
      _plans = results[0] as List<PlanModel>;
      _user = results[1] as UserModel?;
      _loading = false;
    });
  }

  Future<void> _changePlan(String planId) async {
    if (_user == null || planId == _user!.planId) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('Confirmar mudança de plano', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Deseja alterar para o plano ${_plans.firstWhere((p) => p.id == planId).name}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _updatingPlanId = planId);
    final err = await _auth.updatePlan(_user!.uid, planId);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else {
      setState(() => _user = UserModel(uid: _user!.uid, name: _user!.name, email: _user!.email, planId: planId, createdAt: _user!.createdAt));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plano atualizado com sucesso!'), backgroundColor: AppColors.primary));
    }
    setState(() => _updatingPlanId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      if (_user != null) _buildCurrentPlanBanner(),
                      const SizedBox(height: 24),
                      const Text('Todos os Planos', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ..._plans.map((plan) => _buildPlanCard(plan)),
                      const SizedBox(height: 24),
                      _buildComparisonTable(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('Planos', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 4),
        Text('Escolha o plano ideal para você', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
      ],
    );
  }

  Widget _buildCurrentPlanBanner() {
    final currentPlan = _plans.where((p) => p.id == _user!.planId).firstOrNull;
    if (currentPlan == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.2), AppColors.primaryDark.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seu plano atual', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                Text(currentPlan.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('R\$ ${currentPlan.price.toStringAsFixed(2).replaceAll('.', ',')}/mês', style: const TextStyle(color: AppColors.accent, fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Text(currentPlan.quality, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PlanModel plan) {
    final isCurrent = _user?.planId == plan.id;
    final isUpdating = _updatingPlanId == plan.id;
    final planOrder = {'basic': 0, 'standard': 1, 'premium': 2};
    final currentOrder = planOrder[_user?.planId] ?? 0;
    final planOrd = planOrder[plan.id] ?? 0;
    final isUpgrade = planOrd > currentOrder;
    final isDowngrade = planOrd < currentOrder;

    Color planColor;
    switch (plan.id) {
      case 'premium': planColor = AppColors.gold;
      case 'standard': planColor = AppColors.primaryLight;
      default: planColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppColors.primary : const Color(0xFF1C2333),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(plan.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Atual', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: planColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(plan.quality, style: TextStyle(color: planColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${plan.price.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('/mês', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 15, color: planColor),
                      const SizedBox(width: 8),
                      Text(f, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                if (!isCurrent)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isUpdating ? null : () => _changePlan(plan.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUpgrade ? AppColors.primary : AppColors.surfaceVariant,
                        foregroundColor: Colors.white,
                      ),
                      child: isUpdating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isUpgrade ? '⬆ Fazer Upgrade' : isDowngrade ? '⬇ Fazer Downgrade' : 'Selecionar'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1C2333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Comparativo de Planos', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1)},
            children: [
              TableRow(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1C2333)))),
                children: [
                  const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Recurso', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
                  ..._plans.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(p.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  )),
                ],
              ),
              _tableRow('Qualidade', _plans.map((p) => p.quality).toList()),
              _tableRow('Telas', _plans.map((p) => '${p.screens}').toList()),
              _tableRow('Downloads', _plans.map((p) => p.downloads ? '✓' : '✗').toList()),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(String label, List<String> values) {
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1C2333)))),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        ...values.asMap().entries.map((e) {
          final isCheck = e.value == '✓';
          final isCross = e.value == '✗';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              e.value,
              style: TextStyle(
                color: isCheck ? Colors.green : isCross ? AppColors.error : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }),
      ],
    );
  }
}
