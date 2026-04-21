import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/plan_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/cinebox_logo.dart';

class SelectPlanScreen extends StatefulWidget {
  // Nulos quando vem do Google Sign In
  final String? name;
  final String? email;
  final String? password;

  const SelectPlanScreen({
    super.key,
    this.name,
    this.email,
    this.password,
  });

  bool get isGoogleUser => name == null && email == null && password == null;

  @override
  State<SelectPlanScreen> createState() => _SelectPlanScreenState();
}

class _SelectPlanScreenState extends State<SelectPlanScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  List<PlanModel> _plans = [];
  String _selectedPlanId = 'basic';
  bool _loading = false;
  bool _loadingPlans = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    if (mounted) setState(() { _plans = PlanModel.defaults; _loadingPlans = false; });
    try { await _firestore.seedPlans(); } catch (_) {}
  }

  Future<void> _confirm() async {
    setState(() { _loading = true; _error = null; });

    String? err;
    if (widget.isGoogleUser) {
      // Usuário Google: só atualiza o planId no Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) err = await _auth.updatePlan(uid, _selectedPlanId);
    } else {
      // Cadastro normal: cria conta e salva tudo
      err = await _auth.register(
        name: widget.name!,
        email: widget.email!,
        password: widget.password!,
        plan: _selectedPlanId,
      );
    }

    if (!mounted) return;
    if (err != null) {
      setState(() { _error = err; _loading = false; });
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B3E), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _loadingPlans
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'Escolha seu Plano',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Passo 2 de 2 — Selecione o plano ideal para você',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: 1.0,
                              backgroundColor: AppColors.surfaceVariant,
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 24),
                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                                ),
                                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                              ),
                              const SizedBox(height: 16),
                            ],
                            ..._plans.map((plan) => _PlanCard(
                              plan: plan,
                              isSelected: _selectedPlanId == plan.id,
                              onTap: () => setState(() => _selectedPlanId = plan.id),
                            )),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _confirm,
                                child: _loading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Confirmar e Começar'),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/register'),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const Spacer(),
          const Row(
            children: [
              CineBoxLogo(size: 30),
              SizedBox(width: 6),
              Text('CineBox', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.isSelected, required this.onTap});

  Color get _planColor {
    switch (plan.id) {
      case 'premium': return AppColors.gold;
      case 'standard': return AppColors.primaryLight;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFF1C2333),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.textMuted, width: 2),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _planColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _planColor.withOpacity(0.4)),
                        ),
                        child: Text(plan.quality, style: TextStyle(color: _planColor, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...plan.features.map((f) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 13, color: _planColor),
                        const SizedBox(width: 5),
                        Text(f, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${plan.price.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text('/mês', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
