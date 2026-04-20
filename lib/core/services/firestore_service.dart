import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<List<PlanModel>> getPlans() async {
    final snap = await _db.collection('plans').orderBy('price').get();
    return snap.docs.map((d) => PlanModel.fromMap(d.data(), d.id)).toList();
  }

  Future<PlanModel?> getPlan(String id) async {
    final doc = await _db.collection('plans').doc(id).get();
    if (!doc.exists) return null;
    return PlanModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> seedPlans() async {
    final existing = await _db.collection('plans').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final plans = [
      {
        'id': 'basic',
        'name': 'Básico',
        'price': 18.90,
        'quality': 'HD',
        'screens': 1,
        'downloads': false,
        'features': ['Qualidade HD', '1 tela simultânea', 'Acesso ao catálogo completo'],
      },
      {
        'id': 'standard',
        'name': 'Padrão',
        'price': 29.90,
        'quality': 'Full HD',
        'screens': 2,
        'downloads': true,
        'features': ['Qualidade Full HD', '2 telas simultâneas', 'Downloads disponíveis', 'Acesso ao catálogo completo'],
      },
      {
        'id': 'premium',
        'name': 'Premium',
        'price': 45.90,
        'quality': '4K Ultra HD',
        'screens': 4,
        'downloads': true,
        'features': ['Qualidade 4K Ultra HD', '4 telas simultâneas', 'Downloads ilimitados', 'Acesso antecipado a lançamentos', 'Acesso ao catálogo completo'],
      },
    ];

    final batch = _db.batch();
    for (final plan in plans) {
      final id = plan['id'] as String;
      final ref = _db.collection('plans').doc(id);
      final data = Map<String, dynamic>.from(plan)..remove('id');
      batch.set(ref, data, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
