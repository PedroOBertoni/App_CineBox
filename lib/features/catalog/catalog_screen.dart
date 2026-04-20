import 'package:flutter/material.dart';
import '../../core/models/movie_model.dart';
import '../../core/services/tmdb_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/movie_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _tmdb = TmdbService();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<MovieModel> _movies = [];
  int? _selectedGenreId;
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  bool _searching = false;

  static const _genres = [
    {'id': 28, 'name': 'Ação'},
    {'id': 35, 'name': 'Comédia'},
    {'id': 18, 'name': 'Drama'},
    {'id': 27, 'name': 'Terror'},
    {'id': 878, 'name': 'Ficção Científica'},
    {'id': 10749, 'name': 'Romance'},
    {'id': 16, 'name': 'Animação'},
    {'id': 80, 'name': 'Crime'},
    {'id': 53, 'name': 'Thriller'},
    {'id': 12, 'name': 'Aventura'},
    {'id': 14, 'name': 'Fantasia'},
    {'id': 99, 'name': 'Documentário'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_loading && _hasMore && !_searching) _loadMore();
    }
  }

  Future<void> _loadMovies({bool reset = false}) async {
    if (_loading) return;
    if (reset) setState(() { _movies = []; _page = 1; _hasMore = true; });
    setState(() => _loading = true);

    List<MovieModel> result;
    if (_selectedGenreId != null) {
      result = await _tmdb.getByGenre(_selectedGenreId!, page: _page);
    } else {
      result = await _tmdb.getPopular();
    }

    if (!mounted) return;
    setState(() {
      _movies.addAll(result);
      _hasMore = result.length >= 20;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    _page++;
    await _loadMovies();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searching = false);
      _loadMovies(reset: true);
      return;
    }
    setState(() { _searching = true; _loading = true; });
    final result = await _tmdb.search(query.trim());
    if (!mounted) return;
    setState(() { _movies = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildGenreFilter(),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.movie_filter_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text('Catálogo', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Buscar filmes...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        _search('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _genres.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            final selected = _selectedGenreId == null;
            return _GenreChip(
              label: 'Todos',
              selected: selected,
              onTap: () {
                setState(() => _selectedGenreId = null);
                _loadMovies(reset: true);
              },
            );
          }
          final genre = _genres[i - 1];
          final selected = _selectedGenreId == genre['id'];
          return _GenreChip(
            label: genre['name'] as String,
            selected: selected,
            onTap: () {
              setState(() => _selectedGenreId = genre['id'] as int);
              _loadMovies(reset: true);
            },
          );
        },
      ),
    );
  }

  Widget _buildGrid() {
    if (_loading && _movies.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_movies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 64),
            SizedBox(height: 12),
            Text('Nenhum filme encontrado', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _movies.length + (_hasMore && !_searching ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _movies.length) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
        }
        return MovieCard(movie: _movies[i], width: double.infinity, height: double.infinity);
      },
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenreChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFF2D3748)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
