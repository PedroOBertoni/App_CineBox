import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/movie_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/tmdb_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/movie_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tmdb = TmdbService();
  final _auth = AuthService();

  List<MovieModel> _trending = [];
  List<MovieModel> _popular = [];
  List<MovieModel> _topRated = [];
  List<MovieModel> _nowPlaying = [];
  List<MovieModel> _upcoming = [];
  MovieModel? _featured;
  bool _loading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _auth.getUserData(user.uid);
      if (mounted) setState(() => _userName = userData?.name.split(' ').first ?? '');
    }

    final results = await Future.wait([
      _tmdb.getTrending(),
      _tmdb.getPopular(),
      _tmdb.getTopRated(),
      _tmdb.getNowPlaying(),
      _tmdb.getUpcoming(),
    ]);

    if (!mounted) return;
    setState(() {
      _trending = results[0];
      _popular = results[1];
      _topRated = results[2];
      _nowPlaying = results[3];
      _upcoming = results[4];
      _featured = _trending.isNotEmpty ? _trending.first : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildFeatured()),
            SliverToBoxAdapter(
              child: MovieSection(title: 'Em Alta', movies: _trending, isLoading: _loading),
            ),
            SliverToBoxAdapter(
              child: MovieSection(title: 'Mais Populares', movies: _popular, isLoading: _loading),
            ),
            SliverToBoxAdapter(
              child: MovieSection(title: 'Mais Bem Avaliados', movies: _topRated, isLoading: _loading),
            ),
            SliverToBoxAdapter(
              child: MovieSection(title: 'Em Cartaz', movies: _nowPlaying, isLoading: _loading),
            ),
            SliverToBoxAdapter(
              child: MovieSection(title: 'Em Breve', movies: _upcoming, isLoading: _loading),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background.withOpacity(0.95),
      title: Row(
        children: [
          const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 28),
          const SizedBox(width: 8),
          const Text('CineBox', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
          const Spacer(),
          if (_userName.isNotEmpty)
            Text('Olá, $_userName!', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: AppColors.textPrimary, size: 28),
            color: AppColors.surfaceVariant,
            onSelected: (v) async {
              if (v == 'logout') {
                await _auth.logout();
                if (mounted) context.go('/login');
              } else if (v == 'plans') {
                context.go('/plans');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'plans', child: Row(children: [Icon(Icons.workspace_premium, color: AppColors.primary, size: 18), SizedBox(width: 8), Text('Meu Plano', style: TextStyle(color: AppColors.textPrimary))])),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: AppColors.error, size: 18), SizedBox(width: 8), Text('Sair', style: TextStyle(color: AppColors.error))])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatured() {
    if (_loading) {
      return Container(
        height: 420,
        color: AppColors.surfaceVariant,
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_featured == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/movie/${_featured!.id}'),
      child: SizedBox(
        height: 420,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: _featured!.backdropUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: AppColors.surfaceVariant),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.transparent, Color(0x99000000), AppColors.background],
                  stops: [0, 0.4, 0.7, 1],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('EM DESTAQUE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _featured!.title,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 8, color: Colors.black)]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(_featured!.voteAverage.toStringAsFixed(1), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Text(_featured!.year, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push('/movie/${_featured!.id}'),
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text('Assistir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/movie/${_featured!.id}'),
                        icon: const Icon(Icons.info_outline, size: 18, color: Colors.white),
                        label: const Text('Detalhes', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
