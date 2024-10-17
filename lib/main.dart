import 'dart:math';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_particle_effect/particle.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final particleArray = <Particle>[];
  late final adjustX = 0;
  // late final adjustX = width / 2 - 312;
  // late final adjustY = -height / 2 + 150;
  late final adjustY = 0;
  bool showImage = true;
  final mouse = Mouse();
  late final width = MediaQuery.sizeOf(context).width;
  late final height = MediaQuery.sizeOf(context).height;
  int offset = 4;
  int pixelSize = 4;
  img.Image? lastImage;

  Future<void> getImagePixels({img.Image? newImage, bool animation = true}) async {
    final ByteData data;
    final Uint8List bytes;
    img.Image? image = newImage;
    if (image == null) {
      data = await rootBundle.load('assets/images/Pagani.png');
      bytes = data.buffer.asUint8List();
      image = img.decodeImage(bytes);
    }
    if (image != null) {
      for (int y = 0; y < image.height; y += offset) {
        for (int x = 0; x < image.width; x += offset) {
          img.Pixel pixel = image.getPixel(x, y);
          int r = pixel.r.toInt();
          int g = pixel.g.toInt();
          int b = pixel.b.toInt();
          int a = pixel.a.toInt();

          if (a > 125) {
            final positionX = (x + adjustX).toDouble();
            final positionY = (y - adjustY).toDouble();
            particleArray.add(Particle(positionX, positionY, r, g, b));
            particleArray.last.x = animation ? (Random().nextDouble() - 0.5) * 5 * width : positionX;
            particleArray.last.y = animation ? (Random().nextDouble() - 0.5) * 5 * height : positionY;
          }
        }
      }
    }
  }

  void init() async {
    await getImagePixels();
  }

  @override
  void initState() {
    init();
    _ticker = createTicker((elapsed) {
      setState(() {
        for (int i = 0; i < particleArray.length; i++) {
          particleArray[i].update(mouse, showImage);
        }
      });
    });
    _ticker.start();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DropTarget(
          onDragDone: (details) async {
            if (details.files.first.name.contains('png') ||
                details.files.first.name.contains('jpg') ||
                details.files.first.name.contains('webp') ||
                details.files.first.name.contains('jpeg')) {
              particleArray.clear();
              final bytes = await details.files.first.readAsBytes();
              final image = img.decodeImage(bytes);
              lastImage = image;
              await getImagePixels(newImage: lastImage);
            }
          },
          child: MouseRegion(
            onHover: (event) {
              mouse.x = event.position.dx;
              mouse.y = event.position.dy;
            },
            child: GestureDetector(
              onTap: () => showImage = !showImage,
              // onTap: () async {
                // for (int i = 0; i < particleArray.length; i++) {
                //   particleArray[i].x = particleArray[i].baseX;
                //   particleArray[i].y = particleArray[i].baseY;
                // }
                // pixelSize++;
              // },
              child: Scaffold(
                backgroundColor: Colors.black,
                body: CustomPaint(
                  painter: ImagePainter(
                    particleArray,
                    pixelSize: pixelSize.toInt(),
                  ),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 16),
            child: Material(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 8),
                    child: Text('pixel size : ${pixelSize.floor()}'),
                  ),
                  SizedBox(
                    width: 240,
                    child: Row(children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: IconButton(
                          onPressed: () {
                            if (pixelSize <= 2) return;
                            pixelSize--;
                          },
                          iconSize: 14,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back_ios_rounded),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 20,
                            trackShape: const RectangularSliderTrackShape(),
                            overlayShape: SliderComponentShape.noThumb,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 0,
                              disabledThumbRadius: 0,
                            ),
                          ),
                          child: Slider(
                            value: pixelSize.toDouble(),
                            onChanged: (value) async {
                              pixelSize = value.toInt();
                            },
                            max: 30,
                            min: 2,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: IconButton(
                          onPressed: () {
                            if (pixelSize.toInt() >= 30) return;
                            pixelSize++;
                          },
                          iconSize: 14,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_forward_ios_rounded),
                        ),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 8),
                    child: Text('pixel offset : $offset'),
                  ),
                  SizedBox(
                    width: 240,
                    child: Row(children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: IconButton(
                          onPressed: () async {
                            if (offset <= 2) return;
                            offset--;
                            particleArray.clear();
                            await getImagePixels(newImage: lastImage, animation: false);
                          },
                          iconSize: 14,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back_ios_rounded),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 20,
                            trackShape: const RectangularSliderTrackShape(),
                            overlayShape: SliderComponentShape.noThumb,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 0,
                              disabledThumbRadius: 0,
                            ),
                          ),
                          child: Slider(
                            value: offset.toDouble(),
                            allowedInteraction: SliderInteraction.tapOnly,
                            onChanged: (value) async {
                              offset = value.toInt();
                              particleArray.clear();
                              await getImagePixels(newImage: lastImage, animation: false);
                            },
                            max: 30,
                            min: 2,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: IconButton(
                          onPressed: () async {
                            if (offset >= 30) return;
                            offset++;
                            particleArray.clear();
                            await getImagePixels(newImage: lastImage, animation: false);
                          },
                          iconSize: 14,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_forward_ios_rounded),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ImagePainter extends CustomPainter {
  final List<Particle> particleArray;
  final int pixelSize;
  ImagePainter(this.particleArray, {this.pixelSize = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;

    for (final particle in particleArray) {
      final dx = particle.x - particle.baseX;
      final dy = particle.y - particle.baseY;
      final distance = sqrt(dx * dx + dy * dy);
      final fixedSize = particle.size + (pixelSize - particle.size) * (1 - min((distance / 1000).abs(), 1));

      paint.color = Color.fromARGB(
          ((particle.density + (1 - particle.density) * (1 - min((distance / 1000), 1))) * 255).toInt(),
          particle.red,
          particle.green,
          particle.blue);

      final Rect rect = Rect.fromCenter(
        center: Offset(particle.x - fixedSize / 2, particle.y - fixedSize / 2),
        width: fixedSize,
        height: fixedSize,
      );

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Mouse {
  double? x;
  double? y;
  final radius = 200;
}
