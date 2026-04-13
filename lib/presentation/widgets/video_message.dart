import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/message.dart';
import '../../data/services/video_cache_service.dart';

class VideoMessage extends StatefulWidget {
  final Message message;

  const VideoMessage({super.key, required this.message});

  @override
  State<VideoMessage> createState() => _VideoMessageState();
}

class _VideoMessageState extends State<VideoMessage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _videoUrl;
  final VideoCacheService _cacheService = VideoCacheService();
  bool _isResolved = false;

  bool get _isNetworkVideo => _videoUrl?.startsWith('http') == true;

  @override
  void initState() {
    super.initState();
    debugPrint('Video URL from DB: ${widget.message.mediaPath}');
    _resolveVideoUrl();
  }

  Future<void> _resolveVideoUrl() async {
    if (!mounted) return;

    final mediaPath = widget.message.mediaPath;
    if (mediaPath == null) {
      _setError();
      return;
    }

    String? url = mediaPath;

    // If it's a file_id (not http), video resolution needs backend support
    // For now, if it's not an http URL, show error
    if (!mediaPath.startsWith('http')) {
      debugPrint('Video file_id resolution requires backend support');
      _setError();
      return;
    }

    _isResolved = true;

    // Try to get cached local path
    final cachedPath = await _cacheService.getCachedVideoPath(url);
    if (!mounted) return;

    if (cachedPath != null) {
      debugPrint('Video loaded from cache: $cachedPath');
      setState(() {
        _videoUrl = cachedPath;
      });
    } else {
      // No cache, use URL directly (will stream)
      debugPrint('Video loaded from network: $url');
      setState(() {
        _videoUrl = url;
      });
    }
  }

  void _setError() {
    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeVideo() async {
    if (_videoUrl == null || !mounted) return;

    try {
      if (_isNetworkVideo) {
        // For network URLs, check if it's actually a local cached file
        final file = File(_videoUrl!);
        if (await file.exists()) {
          _controller = VideoPlayerController.file(file);
        } else {
          _controller = VideoPlayerController.networkUrl(
            Uri.parse(_videoUrl!),
          );
        }
      } else {
        _controller = VideoPlayerController.file(
          File(_videoUrl!),
        );
      }

      await _controller!.initialize();
      _controller!.addListener(_videoListener);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
      _setError();
    }
  }

  void _videoListener() {
    if (_controller != null && mounted) {
      final isPlaying = _controller!.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.mediaPath == null) {
      return const SizedBox.shrink();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized && _isResolved) {
      _initializeVideo();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
          maxHeight: 300,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
              if (!_isPlaying)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.blue,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.black12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            '视频加载失败',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
