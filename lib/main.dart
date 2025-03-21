import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scanner App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const QRScannerPage(),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  // Controlador para el scanner móvil
  late MobileScannerController cameraController;
  
  // Variables de estado
  String? qrResult;
  bool isScanning = true;
  bool isFlashOn = false;
  bool isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner de QR'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Botón para encender/apagar la linterna
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: isFlashOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                isFlashOn = !isFlashOn;
                cameraController.toggleTorch();
              });
            },
          ),
          // Botón para cambiar cámara
          IconButton(
            icon: Icon(
              isFrontCamera ? Icons.camera_front : Icons.camera_rear,
            ),
            onPressed: () {
              setState(() {
                isFrontCamera = !isFrontCamera;
                cameraController.switchCamera();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: isScanning
                ? MobileScanner(
                    controller: cameraController,
                    onDetect: (BarcodeCapture capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        // Cuando se detecta un código QR
                        setState(() {
                          qrResult = barcode.rawValue;
                          isScanning = false; // Detener el escaneo
                        });
                      }
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 100,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'QR Escaneado con éxito',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          // Contenedor para mostrar el resultado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resultado:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  qrResult ?? 'Escanea un código QR',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (qrResult != null && Uri.tryParse(qrResult!)?.isAbsolute == true)
                  ElevatedButton.icon(
                    onPressed: () => _launchURL(qrResult!),
                    icon: const Icon(Icons.launch),
                    label: const Text('Abrir enlace'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                const SizedBox(height: 8),
                if (qrResult != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        qrResult = null;
                        isScanning = true; // Volver a escanear
                      });
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear otro QR'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Función para abrir URLs
  Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

  if (!launched && mounted) { // Verifica si el widget sigue montado
    if (context.mounted) { // Verificación extra para seguridad
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir: $url')),
      );
    }
  }
}

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}