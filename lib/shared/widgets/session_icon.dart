import 'package:flutter/material.dart';

enum DaySession { morning, afternoon, evening, night }

DaySession currentSession() {
  final h = DateTime.now().hour;
  if (h < 12) return DaySession.morning;
  if (h < 17) return DaySession.afternoon;
  if (h < 21) return DaySession.evening;
  return DaySession.night;
}

/// A simple sunrise/sun/sunset icon, or a moon with a small star for night —
/// a plain time-of-day marker, rather than a hand-drawn scene.
class SessionIcon extends StatelessWidget {
  final DaySession session;
  const SessionIcon({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    switch (session) {
      case DaySession.morning:
        return const Icon(
          Icons.wb_twilight_rounded,
          size: 46,
          color: Color(0xFFFFD54F),
        );
      case DaySession.afternoon:
        return const Icon(
          Icons.wb_sunny_rounded,
          size: 42,
          color: Color(0xFFFFF59D),
        );
      case DaySession.evening:
        return const Icon(
          Icons.wb_twilight_rounded,
          size: 46,
          color: Color(0xFFFF8A65),
        );
      case DaySession.night:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.nightlight_round,
              size: 38,
              color: Color(0xFFE8EAF6),
            ),
            Positioned(
              top: -4,
              left: -6,
              child: Icon(
                Icons.star_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        );
    }
  }
}
