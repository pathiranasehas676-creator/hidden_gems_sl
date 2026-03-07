import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/premium_service.dart';
import '../widgets/custom_buttons.dart';
import '../widgets/batik_background.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInit = false;
  bool _isScanning = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInit = true);
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  void _startScan() async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
      _result = null;
    });

    // Simulate "Oracle" high-fidelity processing
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _result = "Sigiriya Rock Fortress Identified.\n\nBuilt by King Kasyapa (477–495 CE), Sigiriya is a UNESCO World Heritage site known as the 'Lion Rock'. Highlights include the mirror wall, ancient frescoes, and the symmetrical water gardens at the base.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = Provider.of<PremiumService>(context).isPremium;

    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: BatikBackground(
        child: Stack(
          children: [
            // Full Screen Camera or Placeholder
            Positioned.fill(
              child: _isInit && _controller != null
                ? CameraPreview(_controller!)
                : Container(
                    color: AppTheme.primaryBlue,
                    child: Center(
                      child: Icon(Icons.photo_camera_outlined, color: Colors.white.withValues(alpha: 0.1), size: 120),
                    ),
                  ),
            ),
            
            // Scrim for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          "ORACLE VISION",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 48), // Spacer
                      ],
                    ),
                    const Spacer(),
                    if (!isPremium) _buildPremiumGate(),
                    if (isPremium && _result != null) _buildResultCard(),
                    const SizedBox(height: 48),
                    if (isPremium)
                      ModernGradientButton(
                        label: _isScanning ? "PROCESSING..." : "SCAN LANDMARK",
                        icon: Icons.filter_center_focus_rounded,
                        isLoading: _isScanning,
                        onPressed: _startScan,
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Scanner Animation
            if (_isScanning) 
              Center(
                child: Container(
                  width: double.infinity,
                  height: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.accentOchre.withValues(alpha: 0.5), width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _ScanningOverlay(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumGate() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassDecoration(opacity: 0.2),
      child: Column(
        children: [
          const Icon(Icons.lock_person_outlined, color: AppTheme.accentOchre, size: 48),
          const SizedBox(height: 24),
          Text(
            "Vision Reserved",
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            "Unlock landmark identification, historical deep-dives, and AR-guided tours with TripMe Luxury.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 32),
          ModernGradientButton(
            label: "Explore Premium",
            onPressed: () => Provider.of<PremiumService>(context, listen: false).buyPremium(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(opacity: 0.2).copyWith(
        border: Border.all(color: AppTheme.accentOchre.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: AppTheme.accentOchre, size: 20),
              const SizedBox(width: 12),
              Text(
                "ORACLE IDENTIFIED",
                style: GoogleFonts.outfit(
                  color: AppTheme.accentOchre,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _result!,
            style: GoogleFonts.inter(color: Colors.white, height: 1.6, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ScanningOverlay extends StatefulWidget {
  @override
  State<_ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<_ScanningOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: _controller.value * 300,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: AppTheme.accentOchre,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentOchre.withValues(alpha: 0.6),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
