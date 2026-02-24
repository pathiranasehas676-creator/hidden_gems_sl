import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

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
      ResolutionPreset.medium,
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
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
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

    setState(() {
      _isScanning = false;
      _result = "Sigiriya Rock Fortress Identified.\n\nBuilt by King Kasyapa (477–495 CE), Sigiriya is a UNESCO World Heritage site known as the 'Lion Rock'. Highlights include the mirror wall, ancient frescoes, and the symmetrical water gardens at the base.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = Provider.of<PremiumService>(context).isPremium;

    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      appBar: AppBar(
        title: Text("Oracle Vision", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (!isPremium)
              _buildPremiumGateToast(),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildViewfinder(),
                    const SizedBox(height: 40),
                    if (_result == null)
                      Text(
                        "Point your camera at any\nSri Lankan Landmark",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 18),
                      )
                    else
                      _buildResultCard(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildScanButton(isPremium),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumGateToast() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.redAccent, size: 16),
          const SizedBox(width: 12),
          Expanded(child: Text("Landmark Scanner is a Premium Feature.", style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.accentOchre.withOpacity(0.3), width: 2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: _isInit && _controller != null
              ? AspectRatio(
                  aspectRatio: 1,
                  child: CameraPreview(_controller!),
                )
              : Center(
                  child: Icon(Icons.photo_camera_outlined, color: Colors.white.withOpacity(0.1), size: 100),
                ),
          ),
        ),
        if (_isScanning) _ScanningOverlay(),
      ],
    );
  }

  Widget _buildScanButton(bool isPremium) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: (isPremium && !_isScanning) ? _startScan : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentOchre,
          foregroundColor: AppTheme.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          disabledBackgroundColor: Colors.white10,
        ),
        child: Text(
          _isScanning ? "IDENTIFYING..." : "SCAN LANDMARK",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentOchre.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: AppTheme.accentOchre, size: 20),
              const SizedBox(width: 8),
              Text("ORACLE IDENTIFIED", style: GoogleFonts.outfit(color: AppTheme.accentOchre, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_result!, style: GoogleFonts.inter(color: Colors.white, height: 1.5)),
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
        return Container(
          width: 280,
          height: 2,
          margin: EdgeInsets.only(top: _controller.value * 280),
          decoration: BoxDecoration(
            color: AppTheme.accentOchre,
            boxShadow: [BoxShadow(color: AppTheme.accentOchre.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
          ),
        );
      },
    );
  }
}
