import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/tmdb_service.dart';
import '../../core/theme/app_theme.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _tmdb = TmdbService();
  Map<String, dynamic>? _movie;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _tmdb.getMovieDetails(widget.movieId);
    if (mounted) setState(() { _movie = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _movie == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 64),
          const SizedBox(height: 12),
          const Text('Erro ao carregar filme', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final m = _movie!;
    final backdropPath = m['backdrop_path'] ?? '';
    final posterPath = m['poster_path'] ?? '';
    final title = m['title'] ?? '';
    final overview = m['overview'] ?? '';
    final rating = (m['vote_average'] ?? 0).toDouble();
    final releaseDate = m['release_date'] ?? '';
    final runtime = m['runtime'] ?? 0;
    final genres = (m['genres'] as List?)?.map((g) => g['name'] as String).toList() ?? [];
    final cast = (m['credits']?['cast'] as List?)?.take(10).toList() ?? [];
    final videos = (m['videos']?['results'] as List?)
        ?.where((v) => v['type'] == 'Trailer' && v['site'] == 'YouTube')
        .toList() ?? [];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (backdropPath.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: 'https://image.tmdb.org/t/p/w1280$backdropPath',
                    fit: BoxFit.cover,
                  ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.background],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (posterPath.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: 'https://image.tmdb.org/t/p/w300$posterPath',
                          width: 100,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.gold, size: 16),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              if (releaseDate.length >= 4)
                                Text(releaseDate.substring(0, 4), style: const TextStyle(color: AppColors.textMuted)),
                              if (runtime > 0) ...[
                                const SizedBox(width: 12),
                                Text('${runtime}min', style: const TextStyle(color: AppColors.textMuted)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: genres.map((g) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Text(g, style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                            )).toList(),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showTrailerDialog(videos),
                              icon: const Icon(Icons.play_arrow, size: 20),
                              label: Text(videos.isNotEmpty ? 'Ver Trailer' : 'Assistir'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (overview.isNotEmpty) ...[
                  const Text('Sinopse', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(overview, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 20),
                ],
                if (cast.isNotEmpty) ...[
                  const Text('Elenco', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cast.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _CastCard(actor: cast[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTrailerDialog(List videos) {
    if (videos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trailer não disponível'), backgroundColor: AppColors.surfaceVariant),
      );
      return;
    }
    final key = videos.first['key'] as String;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrailerSheet(videoKey: key),
    );
  }
}

class _TrailerSheet extends StatefulWidget {
  final String videoKey;
  const _TrailerSheet({required this.videoKey});

  @override
  State<_TrailerSheet> createState() => _TrailerSheetState();
}

class _TrailerSheetState extends State<_TrailerSheet> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoKey,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Trailer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                // Botão abrir no YouTube
                TextButton.icon(
                  onPressed: () async {
                    final url = Uri.parse('https://youtube.com/watch?v=${widget.videoKey}');
                    if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new, size: 14, color: AppColors.textMuted),
                  label: const Text('Abrir no YouTube', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ],
            ),
          ),
          // Player
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.primary,
            progressColors: const ProgressBarColors(
              playedColor: AppColors.primary,
              handleColor: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CastCard extends StatelessWidget {
  final Map actor;
  const _CastCard({required this.actor});

  @override
  Widget build(BuildContext context) {
    final profilePath = actor['profile_path'] ?? '';
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: profilePath.isNotEmpty
                ? CachedNetworkImageProvider('https://image.tmdb.org/t/p/w185$profilePath')
                : null,
            child: profilePath.isEmpty ? const Icon(Icons.person, color: AppColors.textMuted) : null,
          ),
          const SizedBox(height: 6),
          Text(
            actor['name'] ?? '',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
