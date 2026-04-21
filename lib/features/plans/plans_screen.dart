import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/plan_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

final _plans = [
  PlanModel(id: 'basic', name: 'Básico', price: 18.90, quality: 'HD', screens: 1, downloads: false,
      features: ['Acesso ao catálogo completo', 'Qualidade HD (720p)', '1 tela simultânea', 'Suporte padrão']),
  PlanModel(id: 'standard', name: 'Padrão', price: 28.90, quality: 'Full HD', screens: 2, downloads: true,
      features: ['Acesso ao catálogo completo', 'Qualidade HD (720p)', 'Qualidade Full HD (1080p)', '2 telas simultâneas', 'Downloads offline', 'Suporte prioritário 24h']),
  PlanModel(id: 'premium', name: 'Premium', price: 39.90, quality: '4K Ultra HD', screens: 4, downloads: true,
      features: ['Acesso ao catálogo completo', 'Qualidade HD (720p)', 'Qualidade Full HD (1080p)', 'Qualidade 4K Ultra HD', '4 telas simultâneas', 'Downloads offline', 'Suporte prioritário 24h', 'Lançamentos antecipados']),
];

const _featuresByPlan = {
  'basic': [
    ('Acesso ao catálogo completo', true),
    ('Qualidade HD (720p)', true),
    ('1 tela simultânea', true),
    ('Suporte padrão', true),
    ('Qualidade Full HD (1080p)', false),
    ('Qualidade 4K Ultra HD', false),
    ('2 ou mais telas simultâneas', false),
    ('Downloads offline', false),
    ('Suporte prioritário 24h', false),
    ('Lançamentos antecipados', false),
  ],
  'standard': [
    ('Acesso ao catálogo completo', true),
    ('Qualidade HD (720p)', true),
    ('Qualidade Full HD (1080p)', true),
    ('2 telas simultâneas', true),
    ('Downloads offline', true),
    ('Suporte prioritário 24h', true),
    ('Qualidade 4K Ultra HD', false),
    ('4 telas simultâneas', false),
    ('Lançamentos antecipados', false),
  ],
  'premium': [
    ('Acesso ao catálogo completo', true),
    ('Qualidade HD (720p)', true),
    ('Qualidade Full HD (1080p)', true),
    ('Qualidade 4K Ultra HD', true),
    ('4 telas simultâneas', true),
    ('Downloads offline', true),
    ('Suporte prioritário 24h', true),
    ('Lançamentos antecipados', true),
  ],
};

const _planOrder = {'basic': 0, 'standard': 1, 'premium': 2};

Color _planColor(String id) {
  switch (id) {
    case 'premium': return const Color(0xFFF59E0B);
    case 'standard': return const Color(0xFF3B82F6);
    default: return const Color(0xFF64748B);
  }
}

const _comparison = [
  ('Qualidade de vídeo', ['HD', 'Full HD', '4K Ultra HD']),
  ('Telas simultâneas', ['1', '2', '4']),
  ('Downloads offline', ['✗', '✓', '✓']),
  ('Lançamentos antecipados', ['✗', '✗', '✓']),
  ('Catálogo completo', ['✓', '✓', '✓']),
];

const _whyItems = [
  (AppColors.primary, 'Catálogo Completo', 'Milhares de filmes e séries dos maiores estúdios do mundo, sempre atualizados.', Icons.grid_view_rounded),
  (Color(0xFFF59E0B), 'Qualidade de Imagem', 'Assista em HD, Full HD ou 4K Ultra HD dependendo do seu plano e dispositivo.', Icons.tv_rounded),
  (Color(0xFF3B82F6), 'Múltiplos Dispositivos', 'TV, celular, tablet ou computador — assista onde e como quiser.', Icons.devices_rounded),
  (Color(0xFF22C55E), 'Downloads Offline', 'Baixe seus filmes favoritos e assista sem internet nos planos Padrão e Premium.', Icons.download_rounded),
  (AppColors.error, 'Sem Fidelidade', 'Cancele quando quiser, sem multas ou taxas de cancelamento.', Icons.verified_user_rounded),
  (Color(0xFFF59E0B), 'Lançamentos em Primeira Mão', 'No plano Premium, acesse os lançamentos antes de todo mundo.', Icons.bolt_rounded),
];

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
  _Toast? _toast;

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

  void _showToast(String msg, {bool ok = true}) {
    setState(() => _toast = _Toast(msg, ok));
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _changePlan(PlanModel plan, BuildContext ctx) async {
    if (_user == null || plan.id == _user!.plan) return;

    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => Dialog(
        backgroundColor: const Color(0xFF0F1C35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Confirmar mudança de plano',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  children: [
                    const TextSpan(text: 'Deseja alterar para o plano '),
                    TextSpan(text: plan.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' por '),
                    TextSpan(
                      text: 'R\$ ${plan.price.toStringAsFixed(2).replaceAll('.', ',')}/mês',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155)),
                        foregroundColor: AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _updatingPlanId = plan.id);
    final err = await _auth.updatePlan(_user!.uid, plan.id);
    if (!mounted) return;

    if (err != null) {
      _showToast(err, ok: false);
    } else {
      setState(() => _user = UserModel(uid: _user!.uid, name: _user!.name, email: _user!.email, plan: plan.id, createdAt: _user!.createdAt));
      _showToast('Plano alterado para ${plan.name} com sucesso!');
    }
    setState(() => _updatingPlanId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadUser,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Builder(
                      builder: (innerCtx) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          _buildWhySection(),
                          _buildPlansSection(innerCtx),
                          _buildComparisonTable(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_toast != null) _buildToast(_toast!),
              ],
            ),
    );
  }

  Widget _buildToast(_Toast toast) {
    final color = toast.ok ? const Color(0xFF22C55E) : AppColors.error;
    return Positioned(
      top: 16,
      left: 24,
      right: 24,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            '${toast.ok ? '✓' : '✕'} ${toast.msg}',
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final currentPlan = _plans.where((p) => p.id == _user?.plan).firstOrNull;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
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
          const Text('Planos CineBox', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
            'Entretenimento ilimitado a partir de R\$ 18,90/mês.\nCancele quando quiser.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          if (_user != null && currentPlan != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Seu plano atual', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Text(currentPlan.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Text(
                    'R\$ ${currentPlan.price.toStringAsFixed(2).replaceAll('.', ',')}/mês',
                    style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWhySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Por que assinar o CineBox?', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tudo que você precisa em um só lugar', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: _whyItems.map((item) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1C35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: item.$1.withOpacity(0.13)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$4, color: item.$1, size: 20),
                  const SizedBox(height: 6),
                  Text(item.$2, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Text(item.$3, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, height: 1.4), overflow: TextOverflow.fade),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection(BuildContext ctx) {
    final currentOrder = _planOrder[_user?.plan] ?? -1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Escolha seu Plano', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Todos os planos incluem acesso ao catálogo completo', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          ..._plans.map((plan) {
            final isCurrent = _user?.plan == plan.id;
            final isUpdating = _updatingPlanId == plan.id;
            final planOrd = _planOrder[plan.id] ?? 0;
            final isUpgrade = planOrd > currentOrder;
            final color = _planColor(plan.id);
            final isPremium = plan.id == 'premium';
            final isStandard = plan.id == 'standard';
            final features = _featuresByPlan[plan.id] ?? [];
            final badge = isStandard ? 'Mais Popular' : isPremium ? 'Premium' : plan.name;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                gradient: isCurrent
                    ? LinearGradient(colors: [AppColors.primary.withOpacity(0.12), const Color(0xFF0F1C35)])
                    : isPremium
                        ? LinearGradient(colors: [const Color(0xFFF59E0B).withOpacity(0.08), const Color(0xFF0F1C35)])
                        : const LinearGradient(colors: [Color(0xFF0F1C35), Color(0xFF0F1C35)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent ? color : isStandard ? color.withOpacity(0.4) : const Color(0xFF1E293B),
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: isCurrent ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 20)] : [],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Text(badge, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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
                                      Text(plan.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.bold)),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                          child: const Text('Atual', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                    child: Text(plan.quality, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('R\$ ${plan.price.toStringAsFixed(2).replaceAll('.', ',')}',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                                const Text('/mês', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          children: [
                            _chip('${plan.screens} ${plan.screens == 1 ? 'tela' : 'telas'}', color),
                            _chip(plan.quality, color),
                            _chip(plan.downloads ? 'Downloads' : 'Sem download',
                                plan.downloads ? color : const Color(0xFF475569), dim: !plan.downloads),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFF1E293B)),
                        const SizedBox(height: 8),
                        ...features.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            children: [
                              Icon(f.$2 ? Icons.check_rounded : Icons.close_rounded,
                                  size: 15, color: f.$2 ? color : const Color(0xFF334155)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(f.$1,
                                  style: TextStyle(
                                    color: f.$2 ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    fontSize: 12,
                                    decoration: f.$2 ? TextDecoration.none : TextDecoration.lineThrough,
                                    decorationColor: const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 8),
                        if (isCurrent)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: const Text('✓ Plano atual', textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isUpdating ? null : () => _changePlan(plan, ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isUpgrade ? AppColors.primary : const Color(0xFF1E293B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: isUpgrade ? BorderSide.none : const BorderSide(color: Color(0xFF334155)),
                                elevation: isUpgrade ? 4 : 0,
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

  Widget _chip(String label, Color color, {bool dim = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dim ? const Color(0xFF64748B).withOpacity(0.1) : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildComparisonTable() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1C35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
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
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E293B)))),
                  children: [
                    const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Recurso', style: TextStyle(color: AppColors.textMuted, fontSize: 11))),
                    ...[('Básico', Color(0xFF64748B)), ('Padrão', Color(0xFF3B82F6)), ('Premium', Color(0xFFF59E0B))].map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(p.$1, style: TextStyle(color: p.$2, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
                ..._comparison.map((row) => TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E293B)))),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(row.$1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    ...row.$2.map((v) {
                      final isCheck = v == '✓';
                      final isCross = v == '✗';
                      if (isCheck || isCross) {
                        final color = isCheck ? const Color(0xFF22C55E) : AppColors.error;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                              child: Icon(isCheck ? Icons.check_rounded : Icons.close_rounded, size: 12, color: color),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(v, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
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

class _Toast {
  final String msg;
  final bool ok;
  _Toast(this.msg, this.ok);
}
