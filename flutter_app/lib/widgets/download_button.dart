import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import '../api/music_api.dart';
import '../theme/app_theme.dart';
// ignore: avoid_web_libraries_in_flutter
import 'download_helper.dart';

enum DownloadState { idle, loading, ready, error }

class DownloadButton extends ConsumerStatefulWidget {
  final String? videoId;
  final String title;
  final String artist;
  final double size;

  const DownloadButton({
    super.key,
    required this.videoId,
    required this.title,
    required this.artist,
    this.size = 36,
  });

  @override
  ConsumerState<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<DownloadButton>
    with SingleTickerProviderStateMixin {
  DownloadState _state = DownloadState.idle;
  String? _errorMsg;
  String? _filePath;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    if (widget.videoId == null) return;

    setState(() {
      _state = DownloadState.loading;
      _errorMsg = null;
    });

    try {
      // Solicitar descarga al backend
      final api = MusicApi();
      final downloadUrl = await api.requestDownload(widget.videoId!, widget.title, widget.artist);

      if (kIsWeb) {
        // Descarga directa en el navegador sin abrir nueva pestaña
        triggerBrowserDownload(downloadUrl, '${widget.title} - ${widget.artist}.mp3');

        setState(() {
          _state = DownloadState.ready;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Descarga iniciada'),
              backgroundColor: AppTheme.accent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // En Android, descargar el archivo localmente
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Error descargando archivo: ${response.statusCode}');
      }

      // Guardar en almacenamiento local
      Directory dir;
      if (Platform.isAndroid) {
        dir = (await getExternalStorageDirectory()) ?? await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final filename = '${widget.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim()} - ${widget.artist.replaceAll(RegExp(r'[^\w\s-]'), '').trim()}.mp3';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        _state = DownloadState.ready;
        _filePath = file.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Descargado: $filename'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'ABRIR',
              textColor: Colors.white,
              onPressed: _openFile,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _state = DownloadState.error;
        _errorMsg = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString().substring(0, (e.toString().length).clamp(0, 80))}'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openFile() {
    if (_filePath != null) {
      OpenFile.open(_filePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoId == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: switch (_state) {
        DownloadState.idle => _download,
        DownloadState.error => _download,
        DownloadState.ready => _openFile,
        DownloadState.loading => null,
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: switch (_state) {
              DownloadState.idle => [AppTheme.accent, AppTheme.accentLight],
              DownloadState.loading => [AppTheme.bgCard, AppTheme.bgSurface],
              DownloadState.ready => [const Color(0xFF10B981), const Color(0xFF059669)],
              DownloadState.error => [Colors.red.shade700, Colors.red.shade900],
            },
          ),
          boxShadow: [
            BoxShadow(
              color: switch (_state) {
                DownloadState.idle => AppTheme.accent.withOpacity(0.4),
                DownloadState.loading => Colors.transparent,
                DownloadState.ready => Colors.green.withOpacity(0.4),
                DownloadState.error => Colors.red.withOpacity(0.4),
              },
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: switch (_state) {
            DownloadState.loading => SizedBox(
                width: widget.size * 0.5,
                height: widget.size * 0.5,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            DownloadState.ready => Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            DownloadState.error => Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            DownloadState.idle => Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
          },
        ),
      ),
    );
  }
}
