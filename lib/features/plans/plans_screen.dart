import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/plan_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final _auth = AuthService();

  UserModel? _user;
  bool _loading = true;
  String? _updatingPlanId;

  final _plans = PlanModel.defaults;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    final user = await _auth.getUserData(uid);
    if (mounted) setState(() { _user = user; _loading = false; });
  }

  Future<void> _changePlan(String planId) async {
    if (_user == null || planId == _user!.planId) return;

    final plan = _plans.firstWhere((p) => p.id == planId);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('Confirmar mudança de plano', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Deseja alterar para o plano ${plan.name}?',
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
                onRefresh: _loadUser,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildWhySection(),
                      _buildPlansSection(),
                      _buildComparisonTable(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B3E), Color(0xFF0A0E1A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 26),
              SizedBox(width: 8),
              Text('Planos CineBox', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Entretenimento ilimitado a partir de R\$ 18,90/mês.\nCancele quando quiser.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          if (_user != null) ...[
            const SizedBox(height: 20),
            _buildCurrentPlanBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentPlanBanner() {
    final currentPlan = _plans.where((p) => p.id == _user!.planId).firstOrNull;
    if (currentPlan == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seu plano atual', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(currentPlan.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text(
            'R\$ ${currentPlan.price.toStringAsFixed(2).replaceAll('.', ',')}/mês',
            style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildWhySection() {
    const reasons = [
      (Icons.movie_filter_rounded, AppColors.primary, 'Catálogo Completo', 'Milhares de filmes e séries dos maiores estúdios do mundo, sempre atualizados.'),
      (Icons.hd_rounded, AppColors.gold, 'Qualidade de Imagem', 'Assista em HD, Full HD ou 4K Ultra HD dependendo do seu plano e dispositivo.'),
      (Icons.devices_rounded, AppColors.primaryLight, 'Múltiplos Dispositivos', 'TV, celular, tablet ou computador — assista onde e como quiser.'),
      (Icons.download_rounded, Color(0xFF4CAF50), 'Downloads Offline', 'Baixe seus filmes favoritos e assista sem internet nos planos Standard e Premium.'),
      (Icons.cancel_rounded, AppColors.error, 'Sem Fidelidade', 'Cancele quando quiser, sem multas ou taxas de cancelamento.'),
      (Icons.new_releases_rounded, AppColors.accent, 'Lançamentos em Primeira Mão', 'No plano Premium, acesse os lançamentos antes de todo mundo.'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Por que assinar o CineBox?', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tudo que você precisa em um só lugar', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: reasons.map((r) => _ReasonCard(icon: r.$1, color: r.$2, title: r.$3, description: r.$4)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    final planOrder = {'basic': 0, 'standard': 1, 'premium': 2};
    final currentOrder = planOrder[_user?.planId] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Escolha seu Plano', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Todos os planos incluem acesso ao catálogo completo', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          ..._plans.map((plan) {
            final isCurrent = _user?.planId == plan.id;
            final isUpdating = _updatingPlanId == plan.id;
            final planOrd = planOrder[plan.id] ?? 0;
            final isUpgrade = planOrd > currentOrder;

            Color planColor;
            String badge;
            switch (plan.id) {
              case 'premium': planColor = AppColors.gold; badge = 'Mais Completo';
              case 'standard': planColor = AppColors.primaryLight; badge = 'Mais Popular';
              default: planColor = AppColors.textSecondary; badge = 'Ideal para Começar';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent ? AppColors.primary : plan.id == 'standard' ? AppColors.primaryLight.withOpacity(0.4) : const Color(0xFF1C2333),
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  // Badge topo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: planColor.withOpacity(0.12),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    ),
                    child: Text(badge, textAlign: TextAlign.center, style: TextStyle(color: planColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(plan.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      if (isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                          child: const Text('Atual', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: planColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
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
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const Text('/mês', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Color(0xFF1C2333)),
                        const SizedBox(height: 10),
                        // Destaques rápidos
                        Row(
                          children: [
                            _PlanHighlight(icon: Icons.tv, label: '${plan.screens} ${plan.screens == 1 ? 'tela' : 'telas'}', color: planColor),
                            const SizedBox(width: 16),
                            _PlanHighlight(icon: Icons.high_quality, label: plan.quality, color: planColor),
                            const SizedBox(width: 16),
                            _PlanHighlight(
                              icon: plan.downloads ? Icons.download_done : Icons.block,
                              label: plan.downloads ? 'Downloads' : 'Sem download',
                              color: plan.downloads ? planColor : AppColors.textMuted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Features
                        ...plan.features.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 15, color: planColor),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
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
                                  : Text(isUpgrade ? 'Fazer Upgrade' : 'Fazer Downgrade'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    const features = [
      ('Qualidade de vídeo', ['HD', 'Full HD', '4K Ultra HD']),
      ('Telas simultâneas', ['1', '2', '4']),
      ('Downloads offline', ['✗', '✓', '✓']),
      ('Lançamentos antecipados', ['✗', '✗', '✓']),
      ('Catálogo completo', ['✓', '✓', '✓']),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1C2333)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comparativo de Planos', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {0: FlexColumnWidth(2.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1)},
              children: [
                TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1C2333)))),
                  children: [
                    const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Recurso', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
                    ...[
                      ('Básico', AppColors.textSecondary),
                      ('Padrão', AppColors.primaryLight),
                      ('Premium', AppColors.gold),
                    ].map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(p.$1, style: TextStyle(color: p.$2, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    )),
                  ],
                ),
                ...features.map((row) => TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1C2333)))),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(row.$1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ),
                    ...row.$2.map((v) {
                      final isCheck = v == '✓';
                      final isCross = v == '✗';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          v,
                          style: TextStyle(
                            color: isCheck ? const Color(0xFF4CAF50) : isCross ? AppColors.error : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _ReasonCard({required this.icon, required this.color, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Expanded(
            child: Text(description, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4), overflow: TextOverflow.fade),
          ),
        ],
      ),
    );
  }
}

class _PlanHighlight extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PlanHighlight({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
