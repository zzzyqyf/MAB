import 'dart:async';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Use the shared TTS service for consistency
import '../../../../shared/services/TextToSpeech.dart';

/// MushroomCameraPage - Real-time mushroom detection using YOLO model
/// 
/// Features:
/// - Full screen camera preview
/// - Safety Mode: Works even when model is not available
/// - TTS feedback with 3-second cooldown
/// - Bounding boxes for detected objects
class MushroomCameraPage extends StatefulWidget {
  const MushroomCameraPage({Key? key}) : super(key: key);

  @override
  State<MushroomCameraPage> createState() => _MushroomCameraPageState();
}

class _MushroomCameraPageState extends State<MushroomCameraPage> {
  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  String? _errorMessage;
  
  // TFLite Model
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  bool _isDetecting = false;
  List<String> _labels = [];
  
  // Model input size (YOLOv8 typically uses 640x640 or 320x320)
  static const int inputSize = 320;
  static const double confidenceThreshold = 0.45;
  
  // Detection results
  List<Map<String, dynamic>> _detectionResults = [];
  
  // Display duration before clearing and re-detecting
  Timer? _displayTimer;
  static const Duration _displayDuration = Duration(seconds: 3);
  
  // Latest frame for detection
  CameraImage? _latestFrame;
  
  // TTS cooldown (3 seconds)
  DateTime? _lastSpokenTime;
  static const Duration _ttsCooldown = Duration(seconds: 3);
  String? _lastSpokenLabel;
  
  // Dev tool simulation
  int _simulationIndex = 0;
  final List<String> _simulationClasses = [
    'green_mold',
    'stage1_healthy',
    'stage2_healthy',
    'stage3_healthy',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAll();
    });
  }

  Future<void> _initializeAll() async {
    try {
      debugPrint('🍄 MushroomCameraPage: Starting initialization...');
      
      // Request camera permission
      final permissionStatus = await Permission.camera.request();
      debugPrint('📷 Camera permission: $permissionStatus');
      
      if (!permissionStatus.isGranted) {
        setState(() {
          _errorMessage = 'Camera permission denied';
        });
        TextToSpeech.speak('Camera permission denied');
        return;
      }
      
      await _initializeCamera();
      await _initializeModel();
      
      if (_isModelLoaded) {
        TextToSpeech.speak('Mushroom detection ready');
        // Start periodic detection every 3 seconds
        _startPeriodicDetection();
      } else {
        TextToSpeech.speak('Model failed to load. Check console for errors.');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint('📷 Initializing camera...');
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras found';
        });
        return;
      }

      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium, // Lower resolution for better performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        debugPrint('✅ Camera initialized');
      }
    } catch (e) {
      debugPrint('❌ Camera error: $e');
      setState(() {
        _errorMessage = 'Camera error: $e';
      });
    }
  }

  Future<void> _initializeModel() async {
    debugPrint('🧠 Loading TFLite model...');
    
    // Load labels from assets
    try {
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((l) => l.trim().isNotEmpty).toList();
      debugPrint('✅ Loaded ${_labels.length} labels: $_labels');
    } catch (e) {
      debugPrint('⚠️ Labels error: $e, using defaults');
      _labels = ['green_mold', 'stage1_healthy', 'stage2_healthy', 'stage3_healthy'];
    }
    
    // Load TFLite model - copy asset to temp file first
    try {
      debugPrint('📂 Loading model from assets/best_int8.tflite...');
      
      // Load model bytes from assets
      final modelData = await rootBundle.load('assets/best_int8.tflite');
      debugPrint('📦 Model size: ${modelData.lengthInBytes} bytes');
      
      // Write to temp file (tflite_flutter needs a file path)
      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/best_int8.tflite');
      await modelFile.writeAsBytes(modelData.buffer.asUint8List());
      debugPrint('📁 Model copied to: ${modelFile.path}');
      
      // Load interpreter from file
      _interpreter = await Interpreter.fromFile(modelFile);
      
      // Get input/output tensor info
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      debugPrint('📊 Input shape: ${inputTensor.shape}, type: ${inputTensor.type}');
      debugPrint('📊 Output shape: ${outputTensor.shape}, type: ${outputTensor.type}');
      
      if (mounted) {
        setState(() {
          _isModelLoaded = true;
          _errorMessage = null;
        });
        debugPrint('✅ TFLite model loaded successfully!');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Model loading failed: $e');
      debugPrint('📚 Stack: $stackTrace');
      if (mounted) {
        setState(() {
          _isModelLoaded = false;
          _errorMessage = 'Model load failed: $e';
        });
      }
    }
  }
  
  /// Run inference on a camera frame
  Future<void> _runInference(CameraImage image) async {
    if (!_isModelLoaded || _interpreter == null || _isDetecting) return;
    
    _isDetecting = true;
    
    try {
      // Get tensor info
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      final inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;
      
      debugPrint('🔍 Input: $inputShape (${inputTensor.type}), Output: $outputShape (${outputTensor.type})');
      
      // Prepare input based on model type (int8 vs float)
      final isInt8Input = inputTensor.type.toString().contains('uint8') || 
                          inputTensor.type.toString().contains('int8');
      
      Object inputData;
      if (isInt8Input) {
        inputData = _preprocessImageUint8(image, inputShape[1]);
      } else {
        inputData = _preprocessImageFloat(image, inputShape[1]);
      }
      
      // Prepare output buffer based on actual output shape
      // YOLOv8 TFLite output is typically [1, num_classes+4, num_boxes] e.g. [1, 6, 8400]
      // or sometimes [1, num_boxes, num_classes+4] e.g. [1, 8400, 6]
      Object outputData;
      final isInt8Output = outputTensor.type.toString().contains('uint8') || 
                           outputTensor.type.toString().contains('int8');
      
      if (outputShape.length == 3) {
        if (isInt8Output) {
          outputData = List.generate(
            outputShape[0],
            (_) => List.generate(
              outputShape[1],
              (_) => Uint8List(outputShape[2]),
            ),
          );
        } else {
          outputData = List.generate(
            outputShape[0],
            (_) => List.generate(
              outputShape[1],
              (_) => List<double>.filled(outputShape[2], 0.0),
            ),
          );
        }
      } else {
        // 2D output
        if (isInt8Output) {
          outputData = List.generate(outputShape[0], (_) => Uint8List(outputShape[1]));
        } else {
          outputData = List.generate(outputShape[0], (_) => List<double>.filled(outputShape[1], 0.0));
        }
      }
      
      // Run inference
      _interpreter!.run(inputData, outputData);
      
      // Process results
      final detections = _postprocessYoloV8(outputData, outputShape, image.width, image.height);
      
      if (mounted) {
        setState(() {
          _detectionResults = detections;
        });
        
        // Speak the highest confidence detection (if any)
        if (detections.isNotEmpty) {
          final bestDetection = detections.first;
          final label = bestDetection['tag'] as String;
          await _speakDetection(label);
        }
      }
    } catch (e, stack) {
      debugPrint('❌ Inference error: $e');
      debugPrint('📚 Stack: $stack');
    } finally {
      _isDetecting = false;
    }
  }
  
  /// Preprocess for uint8 input (int8 quantized model)
  List<List<List<List<int>>>> _preprocessImageUint8(CameraImage image, int size) {
    final input = List.generate(
      1,
      (_) => List.generate(
        size,
        (_) => List.generate(
          size,
          (_) => List<int>.filled(3, 0),
        ),
      ),
    );
    
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;
    final scaleX = image.width / size;
    final scaleY = image.height / size;
    
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final srcX = (x * scaleX).toInt().clamp(0, image.width - 1);
        final srcY = (y * scaleY).toInt().clamp(0, image.height - 1);
        
        final yIndex = srcY * image.planes[0].bytesPerRow + srcX;
        final uvIndex = (srcY ~/ 2) * uvRowStride + (srcX ~/ 2) * uvPixelStride;
        
        if (yIndex < image.planes[0].bytes.length && 
            uvIndex < image.planes[1].bytes.length &&
            uvIndex < image.planes[2].bytes.length) {
          final yValue = image.planes[0].bytes[yIndex];
          final uValue = image.planes[1].bytes[uvIndex];
          final vValue = image.planes[2].bytes[uvIndex];
          
          // YUV to RGB
          input[0][y][x][0] = (yValue + 1.370705 * (vValue - 128)).round().clamp(0, 255);
          input[0][y][x][1] = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128)).round().clamp(0, 255);
          input[0][y][x][2] = (yValue + 1.732446 * (uValue - 128)).round().clamp(0, 255);
        }
      }
    }
    
    return input;
  }
  
  /// Preprocess for float input
  List<List<List<List<double>>>> _preprocessImageFloat(CameraImage image, int size) {
    // Create a 4D tensor [1, height, width, 3] normalized to 0-1
    final input = List.generate(
      1,
      (_) => List.generate(
        size,
        (_) => List.generate(
          size,
          (_) => List.filled(3, 0.0),
        ),
      ),
    );
    
    // Simple conversion from YUV420 to RGB (approximate)
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;
    
    final scaleX = image.width / size;
    final scaleY = image.height / size;
    
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final srcX = (x * scaleX).toInt().clamp(0, image.width - 1);
        final srcY = (y * scaleY).toInt().clamp(0, image.height - 1);
        
        final yIndex = srcY * image.planes[0].bytesPerRow + srcX;
        final uvIndex = (srcY ~/ 2) * uvRowStride + (srcX ~/ 2) * uvPixelStride;
        
        if (yIndex < image.planes[0].bytes.length && 
            uvIndex < image.planes[1].bytes.length &&
            uvIndex < image.planes[2].bytes.length) {
          final yValue = image.planes[0].bytes[yIndex];
          final uValue = image.planes[1].bytes[uvIndex];
          final vValue = image.planes[2].bytes[uvIndex];
          
          // YUV to RGB conversion
          int r = (yValue + 1.370705 * (vValue - 128)).round().clamp(0, 255);
          int g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128)).round().clamp(0, 255);
          int b = (yValue + 1.732446 * (uValue - 128)).round().clamp(0, 255);
          
          // Normalize to 0-1
          input[0][y][x][0] = r / 255.0;
          input[0][y][x][1] = g / 255.0;
          input[0][y][x][2] = b / 255.0;
        }
      }
    }
    
    return input;
  }
  
  /// Post-process YOLOv8 output
  /// YOLOv8 TFLite output format: [1, 4+num_classes, num_boxes] e.g. [1, 6, 8400]
  /// where each column is [x, y, w, h, class0_score, class1_score, ...]
  List<Map<String, dynamic>> _postprocessYoloV8(Object output, List<int> shape, int imageWidth, int imageHeight) {
    final detections = <Map<String, dynamic>>[];
    
    try {
      debugPrint('🔄 Postprocessing output shape: $shape');
      
      // Convert output to 2D list of doubles
      List<List<double>> outputMatrix = [];
      
      if (output is List) {
        final batch = output[0]; // First batch
        if (batch is List) {
          for (var row in batch) {
            if (row is List) {
              outputMatrix.add(row.map((e) {
                if (e is int) return e.toDouble();
                if (e is double) return e;
                return 0.0;
              }).toList());
            } else if (row is Uint8List) {
              // Int8 quantized output - dequantize
              outputMatrix.add(row.map((e) => e / 255.0).toList());
            }
          }
        }
      }
      
      if (outputMatrix.isEmpty) {
        debugPrint('⚠️ Empty output matrix');
        return [];
      }
      
      debugPrint('📊 Output matrix: ${outputMatrix.length} x ${outputMatrix[0].length}');
      
      // Determine format: [num_features, num_boxes] or [num_boxes, num_features]
      final int numRows = outputMatrix.length;
      final int numCols = outputMatrix[0].length;
      
      // YOLOv8 exports as [4+num_classes, num_boxes], so rows < cols typically
      // e.g., [6, 8400] means 6 features (x,y,w,h + 2 classes) and 8400 boxes
      bool transposed = numRows < numCols;
      
      final int numBoxes = transposed ? numCols : numRows;
      final int numFeatures = transposed ? numRows : numCols;
      final int numClasses = numFeatures - 4; // x, y, w, h + class scores
      
      debugPrint('📦 numBoxes: $numBoxes, numFeatures: $numFeatures, numClasses: $numClasses');
      
      for (int i = 0; i < numBoxes; i++) {
        // Get box data
        double x, y, w, h;
        List<double> classScores = [];
        
        if (transposed) {
          // Format: [features, boxes] - read column i
          x = outputMatrix[0][i];
          y = outputMatrix[1][i];
          w = outputMatrix[2][i];
          h = outputMatrix[3][i];
          for (int c = 4; c < numFeatures; c++) {
            classScores.add(outputMatrix[c][i]);
          }
        } else {
          // Format: [boxes, features] - read row i
          x = outputMatrix[i][0];
          y = outputMatrix[i][1];
          w = outputMatrix[i][2];
          h = outputMatrix[i][3];
          for (int c = 4; c < numFeatures; c++) {
            classScores.add(outputMatrix[i][c]);
          }
        }
        
        // Find best class
        if (classScores.isEmpty) continue;
        
        double maxScore = classScores[0];
        int maxClassId = 0;
        for (int c = 1; c < classScores.length; c++) {
          if (classScores[c] > maxScore) {
            maxScore = classScores[c];
            maxClassId = c;
          }
        }
        
        // Check confidence threshold
        if (maxScore >= confidenceThreshold) {
          final label = maxClassId < _labels.length ? _labels[maxClassId] : 'class_$maxClassId';
          
          detections.add({
            'tag': label,
            'box': [x, y, w, h, maxScore],
            'classId': maxClassId,
          });
        }
      }
      
      // Sort by confidence
      detections.sort((a, b) => 
        ((b['box'][4] as double) - (a['box'][4] as double)).sign.toInt()
      );
      
      if (detections.isNotEmpty) {
        debugPrint('🎯 Found ${detections.length} detections, best: ${detections.first['tag']} (${(detections.first['box'][4] * 100).toStringAsFixed(1)}%)');
      }
    } catch (e, stack) {
      debugPrint('❌ Post-process error: $e');
      debugPrint('📚 $stack');
    }
    
    return detections.take(5).toList();
  }
  
  /// Start detection cycle
  void _startPeriodicDetection() {
    if (_cameraController == null || !_isModelLoaded) return;
    
    debugPrint('🎥 Starting detection cycle...');
    
    // Capture frames continuously but only store latest
    _cameraController!.startImageStream((CameraImage image) {
      _latestFrame = image;
    });
    
    // Run first detection after camera has time to provide frames
    _waitAndRunFirstDetection();
  }
  
  /// Wait for first frame then run detection
  void _waitAndRunFirstDetection() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      if (_latestFrame != null) {
        debugPrint('📸 First frame ready, running detection...');
        _runDetectionCycle();
      } else {
        debugPrint('⏳ Waiting for first frame...');
        _waitAndRunFirstDetection(); // Retry
      }
    });
  }
  
  /// Run a single detection cycle, then schedule next after display
  Future<void> _runDetectionCycle() async {
    if (_latestFrame == null || _isDetecting || !mounted) {
      // If can't run now, schedule retry
      _scheduleNextDetection();
      return;
    }
    
    debugPrint('🔍 Running detection...');
    final frame = _latestFrame!;
    await _runInference(frame);
    
    // Schedule next detection after display duration
    _scheduleNextDetection();
  }
  
  /// Schedule next detection after clearing current display
  void _scheduleNextDetection() {
    _displayTimer?.cancel();
    _displayTimer = Timer(_displayDuration, () {
      if (mounted) {
        // Clear the display
        setState(() {
          _detectionResults = [];
        });
        debugPrint('✨ Cleared, running next detection...');
        // Trigger next detection
        _runDetectionCycle();
      }
    });
  }

  Future<void> _simulateDetection() async {
    final simulatedClass = _simulationClasses[_simulationIndex];
    debugPrint('🧪 Simulating: $simulatedClass');
    
    // Reset cooldown
    _lastSpokenTime = null;
    _lastSpokenLabel = null;
    
    // Speak
    await _speakDetection(simulatedClass);
    
    // Show simulated result
    setState(() {
      _detectionResults = [
        {
          'tag': simulatedClass,
          'box': [50.0, 100.0, 200.0, 200.0, 0.85],
        }
      ];
    });
    
    _simulationIndex = (_simulationIndex + 1) % _simulationClasses.length;
    
    // Clear after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _detectionResults = [];
        });
      }
    });
  }

  Future<void> _speakDetection(String label) async {
    final now = DateTime.now();
    
    if (_lastSpokenTime != null && 
        now.difference(_lastSpokenTime!) < _ttsCooldown &&
        _lastSpokenLabel == label) {
      return;
    }
    
    _lastSpokenTime = now;
    _lastSpokenLabel = label;
    
    final message = _getVoiceMessage(label);
    debugPrint('🔊 TTS: $message');
    await TextToSpeech.speak(message);
  }

  String _getVoiceMessage(String label) {
    switch (label.toLowerCase()) {
      case 'green_mold':
        return 'Warning, Green Mold detected';
      case 'stage1_healthy':
        return 'Stage 1 Healthy';
      case 'stage2_healthy':
        return 'Stage 2 Healthy';
      case 'stage3_healthy':
        return 'Stage 3 Healthy';
      default:
        return 'Detection: $label';
    }
  }

  Color _getBoxColor(String label) {
    return label.toLowerCase() == 'green_mold' ? Colors.red : Colors.green;
  }

  double _getBoxStrokeWidth(String label) {
    return label.toLowerCase() == 'green_mold' ? 3.0 : 2.0;
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onScreenTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full screen camera preview
            if (_isCameraInitialized && _cameraController != null)
              _buildCameraPreview()
            else if (_errorMessage != null)
              _buildErrorView()
            else
              _buildLoadingView(),

            // Bounding boxes overlay
            if (_detectionResults.isNotEmpty)
              _buildBoundingBoxes(),

            // Top bar with back button and status
            _buildTopBar(),

            // Bottom info bar
            _buildBottomBar(),

          // Test button
          // Positioned(
          //   bottom: 100,
          //   right: 16,
          //   child: FloatingActionButton(
          //     onPressed: _simulateDetection,
          //     backgroundColor: Colors.deepPurple,
          //     child: const Icon(Icons.science),
          //   ),
          // ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }
  
  /// Handle screen tap to trigger manual detection
  void _onScreenTap() {
    if (!_isModelLoaded || _latestFrame == null) {
      debugPrint('👆 Tap ignored - model not ready or no frame');
      return;
    }
    
    debugPrint('👆 Screen tapped - triggering detection...');
    
    // Cancel any pending timer
    _displayTimer?.cancel();
    
    // Clear current results immediately
    setState(() {
      _detectionResults = [];
    });
    
    // Reset detecting flag to allow new detection
    _isDetecting = false;
    
    // Run detection now
    _runDetectionCycle();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeAll,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Starting camera...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBoundingBoxes() {
    return CustomPaint(
      size: Size.infinite,
      painter: BoundingBoxPainter(
        detections: _detectionResults,
        getBoxColor: _getBoxColor,
        getStrokeWidth: _getBoxStrokeWidth,
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '🍄 Scanner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isModelLoaded ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isModelLoaded ? 'AI Ready' : 'Model Error',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Info button to show error
              if (_errorMessage != null)
                IconButton(
                  icon: const Icon(Icons.info, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Model Error'),
                        content: Text(_errorMessage!),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Detection result or status
            if (_detectionResults.isNotEmpty)
              _buildDetectionChip(_detectionResults.first)
            else
              const Text(
                'Point camera at mushrooms',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionChip(Map<String, dynamic> detection) {
    final label = detection['tag'] ?? 'Unknown';
    final confidence = ((detection['box']?[4] ?? 0.0) * 100).toStringAsFixed(0);
    final isWarning = label.toLowerCase() == 'green_mold';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red : Colors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWarning ? Icons.warning : Icons.check_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$label ($confidence%)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for bounding boxes
class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Color Function(String) getBoxColor;
  final double Function(String) getStrokeWidth;

  BoundingBoxPainter({
    required this.detections,
    required this.getBoxColor,
    required this.getStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var detection in detections) {
      final box = detection['box'];
      if (box == null || box.length < 4) continue;

      final label = detection['tag'] ?? 'Unknown';
      final color = getBoxColor(label);
      final strokeWidth = getStrokeWidth(label);

      // Simulated box position (center of screen)
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      final boxSize = size.width * 0.6;

      final rect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: boxSize,
        height: boxSize,
      );

      // Draw box
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawRect(rect, paint);

      // Draw label background
      final labelText = label;
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final bgRect = Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - 8,
        textPainter.width + 12,
        textPainter.height + 6,
      );
      
      canvas.drawRect(bgRect, Paint()..color = color);
      textPainter.paint(canvas, Offset(rect.left + 6, rect.top - textPainter.height - 5));
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
