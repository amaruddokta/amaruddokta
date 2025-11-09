import 'dart:async';

import 'package:flutter/material.dart';

import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoListSection extends StatefulWidget {
  const VideoListSection({super.key});

  @override
  State<VideoListSection> createState() => _VideoListSectionState();
}

class _VideoListSectionState extends State<VideoListSection> {
  final ScrollController _scrollController = ScrollController();
  bool _isDisposed = false;
  int _currentIndex = 0;
  Timer? _autoSlideTimer;
  bool _isAnyVideoPlaying = false;
  final Map<int, dynamic> _videoControllers = {};

  // Helper to check if a URL is a YouTube URL
  bool _isYoutubeUrl(String url) {
    return YoutubePlayer.convertUrlToId(url) != null;
  }

  // Callback function when video play state changes
  void _onVideoPlayStateChanged(bool isPlaying, int index) {
    if (_isDisposed) return;

    setState(() {
      _isAnyVideoPlaying = isPlaying;
    });

    if (isPlaying) {
      // If any video is playing, stop auto slide
      _autoSlideTimer?.cancel();
    } else {
      // If no video is playing, start auto slide
      _startAutoSlide();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateCurrentIndex);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    if (_isAnyVideoPlaying) return; // Don't start if any video is playing

    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isDisposed || !_scrollController.hasClients || _isAnyVideoPlaying) {
        return;
      }

      final cardWidth = MediaQuery.of(context).size.width * 1.0;
      final totalItems =
          (_scrollController.position.maxScrollExtent / cardWidth).ceil() + 1;

      if (_currentIndex < totalItems - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }

      _scrollController.animateTo(
        _currentIndex * cardWidth,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  void _updateCurrentIndex() {
    if (_isDisposed || !_scrollController.hasClients) return;

    final cardWidth = MediaQuery.of(context).size.width * 1.0;
    final currentScroll = _scrollController.offset;
    _currentIndex = (currentScroll / cardWidth).round();

    if (mounted) {
      setState(() {});
    }
  }

  void _onManualScroll() {
    // Pause any playing video when manually scrolling
    if (_isAnyVideoPlaying && _videoControllers.containsKey(_currentIndex)) {
      final controller = _videoControllers[_currentIndex];
      if (controller is YoutubePlayerController) {
        controller.pause();
      } else if (controller is VideoPlayerController) {
        controller.pause();
      }
    }

    // Only reset auto slide timer if no video is playing
    if (!_isAnyVideoPlaying) {
      _resetAutoSlideTimer();
    }
  }

  void _resetAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoSlideTimer?.cancel();
    _scrollController.removeListener(_updateCurrentIndex);
    _scrollController.dispose();

    // Dispose all video controllers
    for (var controller in _videoControllers.values) {
      if (controller is YoutubePlayerController) {
        controller.dispose();
      } else if (controller is VideoPlayerController) {
        controller.dispose();
      }
    }
    _videoControllers.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('adminVideoss')
          .stream(primaryKey: ['id'])
          .order('timestamp', ascending: false)
          .execute()
          .map((data) => data as List<Map<String, dynamic>>),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }
        final videos = snapshot.data!;
        if (videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No videos available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // ভিডিও কার্ডের প্রস্থ স্ক্রিনের প্রস্থ অনুযায়ী নির্ধারণ
        final cardWidth = screenWidth * 1.0;

        return SizedBox(
          height: screenWidth * (9 / 16),
          width: screenWidth,
          child: Stack(
            children: [
              ColoredBox(color: const Color.fromARGB(255, 211, 111, 4)),
              // ভিডিও লিস্ট
              NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollEndNotification) {
                    _onManualScroll();
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const PageScrollPhysics(),
                  itemCount: videos.length,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  itemBuilder: (context, index) {
                    final videoData = videos[index];
                    final videoUrl = videoData['adminurlvideos'] ?? '';

                    if (videoUrl.isEmpty) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: cardWidth,
                          child: const ListTile(
                            leading:
                                Icon(Icons.error_outline, color: Colors.red),
                            title: Text('Invalid video link'),
                          ),
                        ),
                      );
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 0),
                      width: cardWidth,
                      child: VideoCard(
                        key: ValueKey('$videoUrl-$index'),
                        videoData: videoData,
                        index: index,
                        onPlayStateChanged: _onVideoPlayStateChanged,
                        onControllerCreated: (controller) {
                          _videoControllers[index] = controller;
                        },
                      ),
                    );
                  },
                ),
              ),

              // Auto slide indicator (bottom dots)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(videos.length, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Colors.blue
                            : Colors.white.withOpacity(0.5),
                        border: Border.all(color: Colors.grey),
                      ),
                    );
                  }),
                ),
              ),

              // Auto slide status indicator
              if (_isAnyVideoPlaying)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pause,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Auto Slide Paused',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class VideoCard extends StatefulWidget {
  final Map<String, dynamic> videoData;
  final int index;
  final Function(bool, int) onPlayStateChanged;
  final Function(dynamic) onControllerCreated;

  const VideoCard({
    super.key,
    required this.videoData,
    required this.index,
    required this.onPlayStateChanged,
    required this.onControllerCreated,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubePlayerController;

  bool _isPlayerReady = false;
  bool _isDisposed = false;
  bool _isPlaying = false;
  bool _isYoutube = false;

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.videoData['adminurlvideos'] ?? '';

    if (videoUrl.isNotEmpty && YoutubePlayer.convertUrlToId(videoUrl) == null) {
      // Direct video URL
      _isYoutube = false;
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(videoUrl))
            ..initialize().then((_) {
              if (!_isDisposed) {
                setState(() {
                  _isPlayerReady = true;
                });
                _chewieController = ChewieController(
                  videoPlayerController: _videoPlayerController!,
                  autoPlay: false,
                  looping: false,
                  showControls: false, // Hide controls
                  allowFullScreen: true,
                  aspectRatio: 16 / 9,
                  placeholder: Container(
                    color: Colors.black,
                  ),
                  errorBuilder: (context, errorMessage) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 42,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error loading video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
                _chewieController?.videoPlayerController.addListener(() {
                  final isPlaying =
                      _chewieController!.videoPlayerController.value.isPlaying;
                  if (_isPlaying != isPlaying) {
                    setState(() {
                      _isPlaying = isPlaying;
                    });
                    widget.onPlayStateChanged(isPlaying, widget.index);
                  }
                });
                widget.onControllerCreated(_videoPlayerController);
              }
            }).catchError((error) {
              if (!_isDisposed) {
                print("Error initializing direct video player: $error");
                if (mounted) {
                  setState(() {
                    _isPlayerReady = false;
                  });
                }
              }
            });
    } else if (videoUrl.isNotEmpty &&
        YoutubePlayer.convertUrlToId(videoUrl) != null) {
      // YouTube URL
      _isYoutube = true;
      _youtubePlayerController = YoutubePlayerController(
        initialVideoId: YoutubePlayer.convertUrlToId(videoUrl)!,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: true,
          enableCaption: true,
          hideControls: true, // Hide controls
          controlsVisibleAtStart: false,
        ),
      )..addListener(() {
          final isPlaying = _youtubePlayerController!.value.isPlaying;
          if (_isPlaying != isPlaying) {
            setState(() {
              _isPlaying = isPlaying;
            });
            widget.onPlayStateChanged(isPlaying, widget.index);
          }
        });
      widget.onControllerCreated(_youtubePlayerController);
    } else {
      // Invalid video URL
      _isYoutube = false;
      _isPlayerReady = false;
      print("No valid video link found for index ${widget.index}");
    }
  }

  void _togglePlay() {
    if (_isYoutube) {
      if (_isPlaying) {
        _youtubePlayerController?.pause();
      } else {
        _youtubePlayerController?.play();
      }
    } else {
      if (_isPlaying) {
        _chewieController?.pause();
      } else {
        _chewieController?.play();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_isYoutube) {
      _youtubePlayerController?.dispose();
    } else {
      _chewieController?.dispose();
      _videoPlayerController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isYoutube && _youtubePlayerController != null)
            YoutubePlayer(
              controller: _youtubePlayerController!,
              showVideoProgressIndicator: false,
              progressIndicatorColor: Colors.transparent,
              progressColors: const ProgressBarColors(
                playedColor: Colors.transparent,
                handleColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                bufferedColor: Colors.transparent,
              ),
              onReady: () {
                if (_isDisposed) return;
                _isPlayerReady = true;
              },
            )
          else if (!_isYoutube && _chewieController != null && _isPlayerReady)
            Chewie(
              controller: _chewieController!,
            )
          else if (!_isYoutube && !_isPlayerReady)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 42,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Error loading video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Play/Pause overlay button
          if (_isPlayerReady || _isYoutube)
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
