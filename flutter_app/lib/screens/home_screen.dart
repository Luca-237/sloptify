import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../api/music_api.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../widgets/song_card.dart';
import '../widgets/album_card.dart';
import 'album_screen.dart';
import '../providers/player_provider.dart';
import '../api/image_proxy.dart';

enum SearchFilter { songs, albums, all }

final _searchStateProvider = StateProvider<SearchFilter>((ref) => SearchFilter.all);
final _searchResultsProvider = StateProvider<AsyncValue<List<dynamic>>>((ref) => const AsyncValue.data([]));
final _queryProvider = StateProvider<String>((ref) => '');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _backendOk = false;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final ok = await MusicApi().checkHealth();
    if (mounted) setState(() => _backendOk = ok);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    ref.read(_queryProvider.notifier).state = query;
    ref.read(_searchResultsProvider.notifier).state = const AsyncValue.loading();

    try {
      final filter = ref.read(_searchStateProvider);
      List<dynamic> results;
      switch (filter) {
        case SearchFilter.songs:
          results = await MusicApi().searchSongs(query);
        case SearchFilter.albums:
          results = await MusicApi().searchAlbums(query);
        case SearchFilter.all:
          results = await MusicApi().searchAll(query);
      }
      ref.read(_searchResultsProvider.notifier).state = AsyncValue.data(results);
    } catch (e) {
      ref.read(_searchResultsProvider.notifier).state = AsyncValue.error(e, StackTrace.current);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(_searchResultsProvider);
    final filter = ref.watch(_searchStateProvider);
    final query = ref.watch(_queryProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con degradado
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                // Backend status
                if (!_backendOk)
                  _buildBackendWarning(),
                // Barra de búsqueda
                _buildSearchBar(context),
                const SizedBox(height: 12),
                // Filtros
                _buildFilters(filter),
                const SizedBox(height: 8),
                // Resultados
                Expanded(
                  child: results.when(
                    data: (data) => data.isEmpty
                        ? _buildEmptyState(query.isNotEmpty)
                        : _buildResults(data, filter),
                    loading: () => _buildLoadingState(),
                    error: (err, _) => _buildErrorState(err.toString()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() => Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.8),
            radius: 1.2,
            colors: [Color(0xFF1A0840), AppTheme.bgDeep],
          ),
        ),
      );

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Row(
          children: [
            Text(
              'Sloptify',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _backendOk ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                color: _backendOk ? const Color(0xFF10B981) : Colors.red.shade400,
                size: 22,
              ),
              onPressed: _checkBackend,
              tooltip: _backendOk ? 'Backend conectado' : 'Backend desconectado',
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);

  Widget _buildBackendWarning() => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade700, width: 0.8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade300, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Backend no disponible. Inicia el servidor con ./backend/run.sh',
                style: TextStyle(color: Colors.red.shade300, fontSize: 12),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().shake();

  Widget _buildSearchBar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: TextField(
          controller: _searchController,
          onSubmitted: _search,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Buscar canciones, álbumes, artistas...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
            suffixIcon: ValueListenableBuilder(
              valueListenable: _searchController,
              builder: (_, value, __) => value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(_queryProvider.notifier).state = '';
                        ref.read(_searchResultsProvider.notifier).state = const AsyncValue.data([]);
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);

  Widget _buildFilters(SearchFilter current) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: SearchFilter.values.map((f) {
            final selected = f == current;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_filterLabel(f)),
                selected: selected,
                onSelected: (_) {
                  ref.read(_searchStateProvider.notifier).state = f;
                  final q = ref.read(_queryProvider);
                  if (q.isNotEmpty) _search(q);
                },
                selectedColor: AppTheme.accent,
                backgroundColor: AppTheme.bgCard,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: selected ? AppTheme.accent : AppTheme.divider,
                  width: 1,
                ),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            );
          }).toList(),
        ),
      ).animate().fadeIn(delay: 150.ms);

  String _filterLabel(SearchFilter f) => switch (f) {
        SearchFilter.all => 'Todo',
        SearchFilter.songs => 'Canciones',
        SearchFilter.albums => 'Álbumes',
      };

  Widget _buildResults(List<dynamic> data, SearchFilter filter) {
    if (filter == SearchFilter.albums) {
      final albums = data.cast<Album>();
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: albums.length,
        itemBuilder: (_, i) => AlbumCard(
          album: albums[i],
          onTap: albums[i].browseId != null
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlbumScreen(browseId: albums[i].browseId!, title: albums[i].title),
                    ),
                  )
              : null,
        ).animate().fadeIn(delay: (i * 40).ms).scale(begin: const Offset(0.95, 0.95)),
      );
    }

    if (filter == SearchFilter.songs) {
      final songs = data.cast<Song>();
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: songs.length,
        itemBuilder: (_, i) => SongCard(
              song: songs[i],
              onTap: () => ref.read(playerProvider.notifier).playFromQueue(songs, i),
            )
            .animate()
            .fadeIn(delay: (i * 30).ms)
            .slideX(begin: 0.05, end: 0),
      );
    }

    // Modo "all" — mezcla de tipos
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final item = data[i] as Map<String, dynamic>;
        final type = item['type'] as String?;
        if (type == 'album') {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: SizedBox(
              height: 240,
              child: AlbumCard(
              album: Album.fromJson(item),
              onTap: item['browseId'] != null
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlbumScreen(
                            browseId: item['browseId'],
                            title: item['title'] ?? '',
                          ),
                        ),
                      )
                  : null,
              ),
            ),
          ).animate().fadeIn(delay: (i * 30).ms);
        }
        if (type == 'song') {
          return SongCard(
            song: Song.fromJson(item),
            onTap: () {
              // Filtrar solo las canciones de la lista mixta para la cola
              final songItems = data
                  .where((item) => item is Map<String, dynamic> && item['type'] == 'song')
                  .map((item) => Song.fromJson(item as Map<String, dynamic>))
                  .toList();
              final song = Song.fromJson(item);
              final songIndex = songItems.indexWhere((s) => s.videoId == song.videoId);
              ref.read(playerProvider.notifier).playFromQueue(
                songItems,
                songIndex >= 0 ? songIndex : 0,
              );
            },
          )
              .animate()
              .fadeIn(delay: (i * 30).ms)
              .slideX(begin: 0.05, end: 0);
        }
        return _buildArtistTile(context, item, i);
      },
    );
  }

  Widget _buildArtistTile(BuildContext context, Map<String, dynamic> item, int i) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.divider, width: 0.8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.bgSurface,
            backgroundImage: item['thumbnail'] != null
                ? NetworkImage(proxyImageUrl(item['thumbnail'])!)
                : null,
            child: item['thumbnail'] == null
                ? const Icon(Icons.person_rounded, color: AppTheme.textSecondary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? item['title'] ?? 'Artista',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text('Artista', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
        ],
      ),
    ).animate().fadeIn(delay: (i * 30).ms);
  }

  Widget _buildEmptyState(bool hasQuery) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.accent, AppTheme.pink],
              ).createShader(bounds),
              child: const Icon(Icons.search_rounded, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              hasQuery ? 'Sin resultados' : 'Busca tu música favorita',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Intenta con otros términos'
                  : 'Escribe el nombre de una canción,\nálbum o artista',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );

  Widget _buildLoadingState() => ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 8,
        itemBuilder: (_, i) => _shimmerTile().animate().fadeIn(delay: (i * 50).ms),
      );

  Widget _shimmerTile() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.bgCard,
        ),
        child: Row(
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.bgSurface,
            )),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 140, color: AppTheme.bgSurface, margin: const EdgeInsets.only(bottom: 6)),
                  Container(height: 11, width: 90, color: AppTheme.bgSurface),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildErrorState(String err) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                err,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final q = ref.read(_queryProvider);
                  if (q.isNotEmpty) _search(q);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              ),
            ],
          ),
        ),
      );
}
