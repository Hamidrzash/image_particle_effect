import 'dart:math';

import 'package:image_particle_effect/main.dart';

class Particle {
  double x;
  double y;
  int red;
  int green;
  int blue;
  late double baseX;
  late double baseY;
  late double density;
  late double size;

  Particle(this.x, this.y, this.red, this.green, this.blue) {
    baseX = x;
    baseY = y;
    density = Random().nextDouble();
    size = 2 * density;
  }

  void update(final Mouse mouse, final bool showText) {
    final dx = (mouse.x ?? 0) - x;
    final dy = (mouse.y ?? 0) - y;
    final distance = sqrt(dx * dx + dy * dy);

    final forceDirectionX = dx / distance;
    final forceDirectionY = dy / distance;
    final maxDistance = mouse.radius;
    final force = (maxDistance - distance) / maxDistance;
    final directionX = forceDirectionX * force * (density * 30 + 50);
    final directionY = forceDirectionY * force * (density * 30 + 50);

    if (distance < mouse.radius && mouse.x != null || !showText) {
      x -= directionX * 0.2;
      y -= directionY * 0.2;
    }
    {
      if (x != baseX) {
        if (showText) {
          final dx = x - baseX;
          x -= dx * 0.04;
        }
      }
      if (y != baseY) {
        if (showText) {
          final dy = y - baseY;
          y -= dy * 0.04;
        }
      }
    }
  }
}
