import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../main.dart'; 

class SplashScreen extends StatefulWidget {
  final Future<InitializationResult>? initFuture;
  final bool isResume;

  const SplashScreen({
    super.key,
    this.initFuture,
    this.isResume = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset("assets/videos/splash.mp4")
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _controller.play();
      });

    _controller.setLooping(false);

    _controller.addListener(() {
      // Check if video is finished
      if (!_isNavigating && 
          _controller.value.isInitialized && 
          _controller.value.position >= _controller.value.duration) {
        _handleNavigation();
      }
    });
  }

  Future<void> _handleNavigation() async {
    _isNavigating = true; 
    
    InitializationResult? result;
    if (widget.initFuture != null) {
        result = await widget.initFuture;
    }

    if (!mounted) return;

    if (widget.isResume) {
      Navigator.of(context).pop();
    } else {
      if (result != null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AdvanceTravelApp(initResult: result!),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}