// lib/widgets/cached_pdf_viewer.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:yeki/services/cache_manager.dart';

class CachedPdfViewer extends StatefulWidget {
  final String pdfUrl;
  final String pdfId;
  final String pdfTitle;

  const CachedPdfViewer({
    super.key,
    required this.pdfUrl,
    required this.pdfId,
    required this.pdfTitle,
  });

  @override
  State<CachedPdfViewer> createState() => _CachedPdfViewerState();
}

class _CachedPdfViewerState extends State<CachedPdfViewer> {
  final CacheManager _cacheManager = CacheManager();
  
  bool _isLoading = true;
  bool _pdfReady = false;
  String? _pdfPath;
  String? _error;
  int _pagesCount = 0;
  int _currentPage = 1;
  PDFViewController? _pdfController;
  
  DownloadStatus _downloadStatus = DownloadStatus.notDownloaded;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkDownloadStatus();
    await _loadPdf();
  }

  Future<void> _checkDownloadStatus() async {
    final status = _cacheManager.getStatus(widget.pdfId);
    final isCached = await _cacheManager.isCached(widget.pdfId);
    
    setState(() {
      _downloadStatus = status;
      if (isCached) {
        _pdfPath = _cacheManager.getCachedPath(widget.pdfId);
      }
    });
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    if (_pdfPath != null && await File(_pdfPath!).exists()) {
      setState(() {
        _pdfReady = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'PDF non disponible hors ligne. Téléchargez-le pour le consulter.';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _downloadStatus = DownloadStatus.downloading);
    
    _cacheManager.getProgress(widget.pdfId).listen((progress) {
      if (mounted) {
        setState(() => _downloadProgress = progress);
      }
    });
    
    await _cacheManager.downloadFile(
      url: widget.pdfUrl,
      fileId: widget.pdfId,
      fileName: '${widget.pdfId}.pdf',
      fileType: 'pdf',
      onComplete: () async {
        await _checkDownloadStatus();
        await _loadPdf();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF téléchargé avec succès'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _downloadStatus = DownloadStatus.failed);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $error'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteDownload() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le PDF'),
        content: const Text('Voulez-vous supprimer ce PDF du cache ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _cacheManager.deleteDownloadedFile(widget.pdfId);
      await _checkDownloadStatus();
      await _loadPdf();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF supprimé du cache'),
            backgroundColor: Color(0xFFF97316),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre d'outils PDF
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Titre
              Expanded(
                child: Text(
                  widget.pdfTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Boutons de contrôle du cache
              if (_downloadStatus == DownloadStatus.downloaded)
                _buildActionButton(
                  icon: Icons.delete_outline,
                  label: 'Supprimer',
                  color: Colors.red,
                  onTap: _deleteDownload,
                )
              else if (_downloadStatus == DownloadStatus.downloading)
                _buildProgressButton()
              else if (_downloadStatus == DownloadStatus.failed)
                _buildActionButton(
                  icon: Icons.error_outline,
                  label: 'Réessayer',
                  color: Colors.orange,
                  onTap: _downloadPdf,
                )
              else
                _buildActionButton(
                  icon: Icons.download_outlined,
                  label: 'Télécharger',
                  color: const Color(0xFF135F74),
                  onTap: _downloadPdf,
                ),
            ],
          ),
        ),
        
        // Visualiseur PDF
        Expanded(
          child: _buildPdfViewer(),
        ),
        
        // Barre de progression de page
        if (_pdfReady && _pagesCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: _currentPage > 1 ? () => _pdfController?.setPage(_currentPage - 1) : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Page $_currentPage / $_pagesCount',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: _currentPage < _pagesCount ? () => _pdfController?.setPage(_currentPage + 1) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPdfViewer() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            if (_downloadStatus != DownloadStatus.downloading && _downloadStatus != DownloadStatus.downloaded)
              ElevatedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.download),
                label: const Text('Télécharger le PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135F74),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }
    
    if (_pdfPath == null) {
      return const Center(child: Text('PDF non disponible'));
    }
    
    return PDFView(
      filePath: _pdfPath,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      onRender: (pages) {
        setState(() {
          _pagesCount = pages ?? 0;
          _pdfReady = true;
        });
      },
      onViewCreated: (controller) {
        setState(() => _pdfController = controller);
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = (page ?? 0) + 1;
          _pagesCount = total ?? _pagesCount;
        });
      },
      onError: (error) {
        setState(() => _error = error.toString());
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF135F74).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF135F74).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              value: _downloadProgress,
              strokeWidth: 2,
              color: const Color(0xFF135F74),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(_downloadProgress * 100).toInt()}%',
            style: const TextStyle(fontSize: 11, color: Color(0xFF135F74), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}