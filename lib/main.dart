import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QRScannerWithLinkHighlight(),
    );
  }
}

class QRScannerWithLinkHighlight extends StatefulWidget {
  @override
  State<QRScannerWithLinkHighlight> createState() =>
      _QRScannerWithLinkHighlightState();
}

class _QRScannerWithLinkHighlightState
    extends State<QRScannerWithLinkHighlight> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String scannedResult = '';
  bool flashOn = false;
  // bool frontCamera = false;
  bool isCameraPaused = false;

  final urlPattern = RegExp(r'^(https?:\/\/)?([\w\-]+\.)+[\w]{2,}(\/\S*)?$');

  bool isLink(String text) => urlPattern.hasMatch(text);

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    final bool isResultLink = isLink(scannedResult);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.lightBlueAccent,
              borderRadius: 16,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: MediaQuery.of(context).size.width * 0.7,
            ),
          ),
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Center(
              child: Text(
                'Scan a QR code',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
          ),
          Positioned(
            bottom: 130,
            left: 20,
            right: 20,
            child: Center(
              child:
                  scannedResult.isEmpty
                      ? Text(
                        'Waiting for scan...',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      )
                      : GestureDetector(
                        onTap: () async {
                          String cleaned = scannedResult.trim();
                          if (!cleaned.startsWith('http')) {
                            cleaned = 'https://$cleaned';
                          }

                          final Uri url = Uri.parse(cleaned);
                          print('Launching: $url'); // for debugging

                          try {
                            final canLaunchIt = await canLaunchUrl(url);
                            if (canLaunchIt) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              print("Can't launch URL");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "❌ Can't launch the scanned link",
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            print('Launch error: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("🚫 Error launching link"),
                              ),
                            );
                          }
                        },

                        child: Text(
                          scannedResult,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 40,
            child: IconButton(
              icon: Icon(
                flashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              iconSize: 30,
              onPressed: () async {
                await controller?.toggleFlash();
                setState(() => flashOn = !flashOn);
              },
            ),
          ),
          if (isCameraPaused)
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    controller?.resumeCamera();
                    setState(() {
                      scannedResult = '';
                      isCameraPaused = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.1,
                      ), // translucent background
                      border: Border.all(color: Colors.white70, width: 1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Scan Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
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

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) async {
      if (mounted && scanData.code != null) {
        await controller.pauseCamera();
        setState(() {
          scannedResult = scanData.code!;
          isCameraPaused = true;
        });
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
