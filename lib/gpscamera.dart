import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  bool ready = false;
  String watermarkText = "Loading...";

  bool isFrontCamera = false;
  bool isVideoMode = false;
  bool isRecording = false;
  XFile? recordedVideoFile;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    initCamera();
    fetchLocation();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.storage,
    ].request();
  }

  Future<void> initCamera() async {
    controller = CameraController(widget.cameras.first, ResolutionPreset.high);
    await controller!.initialize();
    setState(() => ready = true);
  }

  Future<void> fetchLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      openAppSettings();
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: Duration(seconds: 15),
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    Placemark place = placemarks.first;

    String address = cleanAddress(place);

    setState(() {
      watermarkText =
          "${DateFormat('dd MMM yyyy • hh:mm a').format(DateTime.now())}\n"
          "📍 $address\n"
          "Lat: ${pos.latitude.toStringAsFixed(5)}, Lon: ${pos.longitude.toStringAsFixed(5)}";
    });
  }

  String cleanAddress(Placemark place) {
    // Build structured single-line address
    String address =
        "${place.locality}, ${place.administrativeArea}, ${place.country}";

    // Remove multiple spaces and unwanted newlines
    return address.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> capturePhoto() async {
    final xFile = await controller!.takePicture();
    Uint8List originalBytes = await xFile.readAsBytes();

    // Decode base image
    final uiImage = await decodeImageFromList(originalBytes);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw photo normally
    canvas.drawImage(uiImage, Offset.zero, Paint());

    // ---- APPLY WATERMARK AT BOTTOM LEFT ----

    const double fontSize = 28; // Smaller watermark size
    const double padding = 30; // Distance from edges

    final textPainter = TextPainter(
      text: TextSpan(
        text: watermarkText,
        style: const TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          height: 1.2,
          shadows: [Shadow(color: Colors.black, blurRadius: 5)],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout(maxWidth: uiImage.width.toDouble() * 0.7);

    // Position watermark bottom-left
    final double dx = padding;
    final double dy = uiImage.height - textPainter.height - padding;

    // Background rectangle behind watermark
    final rect = Rect.fromLTWH(
      dx - 12,
      dy - 6,
      textPainter.width + 20,
      textPainter.height + 12,
    );
    final bgPaint = Paint()..color = const Color.fromARGB(120, 0, 0, 0);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      bgPaint,
    );

    textPainter.paint(canvas, Offset(dx, dy));

    // ---- END WATERMARK ----

    final picture = recorder.endRecording();
    final finalImg = await picture.toImage(uiImage.width, uiImage.height);
    final byteData = await finalImg.toByteData(format: ui.ImageByteFormat.png);
    final finalBytes = byteData!.buffer.asUint8List();

    // Save file to app folder inside /gps_photos
    final dir = await getApplicationDocumentsDirectory();
    final saveFolder = Directory("${dir.path}/gps_photos");

    if (!await saveFolder.exists()) {
      await saveFolder.create(recursive: true);
    }

    final filePath =
        "${saveFolder.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.png";
    File file = File(filePath);
    await file.writeAsBytes(finalBytes);

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text("📁 Saved with watermark:\n$filePath")),
    // );
    showMiniToast("📸 Photo Saved");
  }

  Future<void> switchCamera() async {
    if (widget.cameras.length < 2) return;

    setState(() => ready = false);

    try {
      await controller?.dispose();

      isFrontCamera = !isFrontCamera;

      controller = CameraController(
        widget.cameras[isFrontCamera ? 1 : 0],
        ResolutionPreset.high,
        enableAudio: isVideoMode,
      );

      await controller!.initialize();
    } catch (e) {
      debugPrint("Camera Switch Error: $e");
    }

    if (mounted) setState(() => ready = true);
  }

  Future<void> toggleVideoMode() async {
    setState(() {
      ready = false;
      isVideoMode = !isVideoMode;
    });

    try {
      await controller?.dispose();

      controller = CameraController(
        widget.cameras[isFrontCamera ? 1 : 0],
        ResolutionPreset.high,
        enableAudio: isVideoMode,
      );

      await controller!.initialize();
    } catch (e) {
      debugPrint("Mode Toggle Error: $e");
    }

    if (mounted) setState(() => ready = true);
  }

  Future<void> recordVideo() async {
    if (!isRecording) {
      await controller!.startVideoRecording();
      setState(() => isRecording = true);
    } else {
      recordedVideoFile = await controller!.stopVideoRecording();
      setState(() => isRecording = false);

      final dir = await getApplicationDocumentsDirectory();
      final saveFolder = Directory("${dir.path}/gps_photos");

      if (!await saveFolder.exists()) {
        await saveFolder.create(recursive: true);
      }

      final newPath =
          "${saveFolder.path}/VID_${DateTime.now().millisecondsSinceEpoch}.mp4";
      await File(recordedVideoFile!.path).copy(newPath);

      showMiniToast("🎬 Video Saved");
    }
  }

  void showMiniToast(String message) async {
    OverlayState? overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: MediaQuery.of(context).size.width / 2 - 80,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    await Future.delayed(const Duration(seconds: 2));
    entry.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ready
          ? Stack(
              children: [
                // ✅ Fullscreen responsive camera preview
                // ✅ Fullscreen responsive camera preview with safe check
                Positioned.fill(
                  child:
                      ready &&
                          controller != null &&
                          controller!.value.isInitialized
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: controller!.value.previewSize!.height,
                            height: controller!.value.previewSize!.width,
                            child: CameraPreview(controller!),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),

                // ✅ Watermark bottom-left
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      watermarkText,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),
                ),

                // 📸 Stylish Capture Button
                // 📸 Stylish Capture Button (Fixed)
                Positioned(
                  bottom: 65,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      if (watermarkText == "Getting Location?.....") return;
                      isVideoMode ? recordVideo() : capturePhoto();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: isRecording ? 95 : 88,
                      width: isRecording ? 95 : 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (isRecording)
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.6),
                              blurRadius: 25,
                              spreadRadius: 8,
                            ),
                        ],
                        gradient: LinearGradient(
                          colors: isVideoMode
                              ? [Colors.redAccent, Colors.deepOrange]
                              : [
                                  Colors.blueAccent,
                                  Colors.purpleAccent,
                                  Colors.orangeAccent,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isVideoMode
                              ? (isRecording ? Icons.stop : Icons.videocam)
                              : Icons.camera_alt,
                          size: isRecording ? 40 : 35,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // 🔄 Switch Camera Button
                Positioned(
                  //top: 12,
                  right: 20,
                  bottom: 100,

                  child: GestureDetector(
                    onTap: switchCamera,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cameraswitch_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // 🎥 Mode Toggle Button
                Positioned(
                  bottom: 9,
                  left: 148,

                  child: GestureDetector(
                    onTap: toggleVideoMode,
                    child: Container(
                      height: 27,
                      width: 70,
                      padding: EdgeInsets.symmetric(),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isVideoMode ? "Photo" : "Video",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),

                // 🖼 Open Gallery Button
                Positioned(
                  bottom: 16,
                  left: 20,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GalleryScreen(),
                        ),
                      );
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File> images = [];

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> loadImages() async {
    final dir = await getApplicationDocumentsDirectory();

    final files = Directory("${dir.path}/gps_photos")
        .listSync()
        .where(
          (item) =>
              item.path.endsWith(".png") ||
              item.path.endsWith(".jpg") ||
              item.path.endsWith(".mp4"),
        )
        .map((item) => File(item.path))
        .toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    setState(() => images = files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Saved Photos"),
        backgroundColor: Colors.white,
      ),

      body: images.isEmpty
          ? const Center(
              child: Text(
                "📂 No images saved yet",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => images[index].path.endsWith(".mp4")
                            ? VideoPlayerScreen(file: images[index])
                            : FullImageScreen(
                                image: images[index],
                                onDelete: () {
                                  File(images[index].path).deleteSync();
                                  setState(() => images.removeAt(index));
                                },
                              ),
                      ),
                    );

                    // If video was deleted, refresh UI
                    if (result == true) {
                      setState(() => images.removeAt(index));
                    }
                  },

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        // 🖼 Show thumbnail if image, video icon if video
                        images[index].path.endsWith(".mp4")
                            ? Container(
                                color: Colors.black26,
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    size: 45,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Image.file(
                                images[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),

                        if (images[index].path.endsWith(".mp4"))
                          const Positioned(
                            right: 6,
                            bottom: 6,
                            child: Icon(
                              Icons.videocam,
                              color: Colors.white70,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final File file;
  const VideoPlayerScreen({super.key, required this.file});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController videoController;

  @override
  void initState() {
    super.initState();
    videoController = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        videoController.play();
      });
  }

  @override
  void dispose() {
    videoController.dispose();
    super.dispose();
  }

  Future<void> _deleteVideo(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Video?"),
        content: const Text("Are you sure you want to delete this video?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.file.delete();
        Navigator.pop(context, true); // send success delete back
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error deleting video")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, size: 30, color: Colors.redAccent),
            onPressed: () => _deleteVideo(context),
          ),
        ],
      ),
      body: Center(
        child: videoController.value.isInitialized
            ? AspectRatio(
                aspectRatio: videoController.value.aspectRatio,
                child: VideoPlayer(videoController),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class FullImageScreen extends StatelessWidget {
  final File image;
  final VoidCallback onDelete;

  const FullImageScreen({
    super.key,
    required this.image,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Photo?"),
                  content: const Text(
                    "Are you sure you want to delete this photo permanently?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                onDelete();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),

      // 🖼️ Full Interactive Image View
      body: Center(
        child: InteractiveViewer(
          clipBehavior: Clip.none,
          minScale: 1,
          maxScale: 5,
          child: SizedBox.expand(
            child: FittedBox(fit: BoxFit.contain, child: Image.file(image)),
          ),
        ),
      ),
    );
  }
}
