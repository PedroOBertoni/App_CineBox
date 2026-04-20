import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';

class TmdbService {
  static const _apiKey = 'SUA_TMDB_API_KEY';
  static const _base = 'https://api.themoviedb.org/3';
  static const _lang = 'pt-BR';

  static const genres = {
    28: 'Ação', 12: 'Aventura', 16: 'Animação', 35: 'Comédia',
    80: 'Crime', 99: 'Documentário', 18: 'Drama', 10751: 'Família',
    14: 'Fantasia', 36: 'História', 27: 'Terror', 10402: 'Música',
    9648: 'Mistério', 10749: 'Romance', 878: 'Ficção Científica',
    10770: 'TV Movie', 53: 'Thriller', 10752: 'Guerra', 37: 'Faroeste',
  };

  Future<List<MovieModel>> _get(String endpoint, {Map<String, String>? params}) async {
    final uri = Uri.parse('$_base$endpoint').replace(queryParameters: {
      'api_key': _apiKey,
      'language': _lang,
      ...?params,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    return (data['results'] as List).map((e) => MovieModel.fromJson(e)).toList();
  }

  Future<List<MovieModel>> getTrending() => _get('/trending/movie/week');
  Future<List<MovieModel>> getPopular() => _get('/movie/popular');
  Future<List<MovieModel>> getTopRated() => _get('/movie/top_rated');
  Future<List<MovieModel>> getNowPlaying() => _get('/movie/now_playing');
  Future<List<MovieModel>> getUpcoming() => _get('/movie/upcoming');

  Future<List<MovieModel>> getByGenre(int genreId, {int page = 1}) => _get(
    '/discover/movie',
    params: {'with_genres': genreId.toString(), 'page': page.toString()},
  );

  Future<List<MovieModel>> search(String query) => _get(
    '/search/movie',
    params: {'query': query},
  );

  Future<Map<String, dynamic>?> getMovieDetails(int id) async {
    final uri = Uri.parse('$_base/movie/$id').replace(queryParameters: {
      'api_key': _apiKey,
      'language': _lang,
      'append_to_response': 'credits,videos',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }
}
