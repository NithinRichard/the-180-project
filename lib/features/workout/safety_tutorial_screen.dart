import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/progression_provider.dart';

class SafetyTutorialScreen extends StatefulWidget {
  const SafetyTutorialScreen({super.key});

  @override
  State<SafetyTutorialScreen> createState() => _SafetyTutorialScreenState();
}

class _SafetyTutorialScreenState extends State<SafetyTutorialScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasAffirmed = false;
  bool _hasWatchedToEnd = false;
  double _playbackSpeed = 1.0;

  int _currentIndex = 0;
  final List<Map<String, dynamic>> _curriculum = [
    {
      "title": "THE KICK-DOWN",
      "difficulty": "BEGINNER (L1-2)",
      "description": "Simply bringing one leg down at a time if the arms get tired.",
      "videoUrl": "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4", // Placeholder
      "annotations": {2: "Focus eyes on floor", 5: "Step down with lead leg"}
    },
    {
       "title": "THE SIDE-STEP",
       "difficulty": "INTERMEDIATE (L3-4)",
       "description": "'Cartwheeling' out of a chest-to-wall handstand when balance is lost sideways.",
       "videoUrl": "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4", // Placeholder
       "annotations": {1: "Shift weight to opposite hand", 4: "Twist hips 90 deg"}
    },
    {
       "title": "THE PIROUETTE",
       "difficulty": "ADVANCED (L5+)",
       "description": "Shifting weight to one hand and spinning 180 deg to land on feet.",
       "videoUrl": "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4", // Placeholder
       "annotations": {2: "Release right hand", 6: "Spin on left palm"}
    }
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(_curriculum[_currentIndex]["videoUrl"]),
    )..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _hasWatchedToEnd = false;
        });
        _controller.setLooping(true);
        _controller.play();
        _controller.addListener(_videoListener);
      });
  }

  void _videoListener() {
    if (_controller.value.position >= _controller.value.duration && !_hasWatchedToEnd) {
      setState(() => _hasWatchedToEnd = true);
    }
  }

  void _changeTutorial(int index) {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    setState(() {
      _currentIndex = index;
      _isInitialized = false;
    });
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _curriculum[_currentIndex];
    final progression = context.read<ProgressionProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("FAIL-SAFE LIBRARY", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Video Player Section
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                if (_isInitialized)
                  VideoPlayer(_controller)
                else
                  const Center(child: CircularProgressIndicator(color: AppTheme.voltGreen)),
                
                // Annotations Overlay
                if (_isInitialized)
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, VideoPlayerValue value, child) {
                      String? annotation;
                      final seconds = value.position.inSeconds;
                      final annotations = current["annotations"] as Map<int, String>;
                      if (annotations.containsKey(seconds)) {
                        annotation = annotations[seconds];
                      }

                      if (annotation == null) return const SizedBox();
                      return Positioned(
                        top: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.voltGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            annotation.toUpperCase(),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),

                // Video Controls
                _buildVideoControls(),
              ],
            ),
          ),

          // Curriculum Selection
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(_curriculum.length, (index) {
                final isSelected = _currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(_curriculum[index]["title"]),
                    selected: isSelected,
                    onSelected: (val) => _changeTutorial(index),
                    selectedColor: AppTheme.voltGreen,
                    backgroundColor: AppTheme.surfaceGrey,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Text(
                  current["difficulty"],
                  style: const TextStyle(color: AppTheme.voltGreen, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  current["title"],
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Text(
                  current["description"],
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 32),
                
                // Safety Affirmation Drawer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceGrey,
                    border: Border.all(color: _hasWatchedToEnd ? AppTheme.voltGreen : Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SAFETY AFFIRMATION",
                        style: TextStyle(color: AppTheme.voltGreen, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "I understand that handstand training involves risk. I have cleared my surrounding area of furniture and am practicing the bail-out techniques on a safe surface.",
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _hasAffirmed,
                            onChanged: _hasWatchedToEnd ? (val) => setState(() => _hasAffirmed = val!) : null,
                            activeColor: AppTheme.voltGreen,
                            checkColor: Colors.black,
                          ),
                          const Expanded(
                            child: Text(
                              "I have practiced this bail-out 5 times on a soft surface.",
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_hasAffirmed && _hasWatchedToEnd) 
                    ? () {
                        progression.completeSafetyTraining();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("SAFETY CERTIFIED: CERTIFIED FALLER UNLOCKED"),
                            backgroundColor: AppTheme.voltGreen,
                          ),
                        );
                      }
                    : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("COMPLETE TRAINING"),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
              ),
              const SizedBox(width: 8),
              if (!_hasWatchedToEnd)
                 const Text("WATCH FULL LOOP", style: TextStyle(color: AppTheme.voltGreen, fontSize: 10, fontWeight: FontWeight.bold)),
              if (_hasWatchedToEnd)
                 const Icon(Icons.check_circle, color: AppTheme.voltGreen, size: 16),
            ],
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _playbackSpeed = _playbackSpeed == 1.0 ? 0.5 : 1.0;
                _controller.setPlaybackSpeed(_playbackSpeed);
              });
            },
            child: Text(
              "SLOW MO: ${_playbackSpeed}x",
              style: TextStyle(color: _playbackSpeed == 0.5 ? AppTheme.voltGreen : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
