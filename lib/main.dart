import 'dart:math';

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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
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
  late final adjustX = width / 2 - 312;
  late final adjustY = -height / 2 + 150;
  bool showImage = true;
  final mouse = Mouse();
  late final width = MediaQuery.sizeOf(context).width;
  late final height = MediaQuery.sizeOf(context).height;

  Future<void> getImagePixels() async {
    final ByteData data = await rootBundle.load('assets/images/Pagani.png');
    final List<int> bytes = data.buffer.asUint8List();

    final img.Image? image = img.decodeImage(Uint8List.fromList(bytes));
    if (image != null) {
      for (int y = 0; y < image.height; y += 3) {
        for (int x = 0; x < image.width; x += 3) {
          img.Pixel pixel = image.getPixel(x, y);
          int r = pixel.r.toInt();
          int g = pixel.g.toInt();
          int b = pixel.b.toInt();
          int a = pixel.a.toInt();

          if (a > 125) {
            final positionX = (x + adjustX).toDouble();
            final positionY = (y - adjustY).toDouble();
            particleArray.add(Particle(positionX, positionY, r, g, b));
            particleArray.last.x = (Random().nextDouble() - 0.5) * 5 * width;
            particleArray.last.y = (Random().nextDouble() - 0.5) * 5 * height;
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
    return MouseRegion(
      onHover: (event) {
        mouse.x = event.position.dx;
        mouse.y = event.position.dy;
      },
      child: GestureDetector(
        onTap: () => showImage = !showImage,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: CustomPaint(
            painter: ImagePainter(particleArray),
          ),
        ),
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final List<Particle> particleArray;
  ImagePainter(this.particleArray);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;

    for (final particle in particleArray) {
      final dx = particle.x - particle.baseX;
      final dy = particle.y - particle.baseY;
      final distance = sqrt(dx * dx + dy * dy);
      final fixedSize = particle.size + (2 - particle.size) * (1 - min((distance / 1000).abs(), 1));

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
