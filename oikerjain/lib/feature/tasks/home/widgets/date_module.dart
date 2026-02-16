import 'package:flutter/material.dart';

import '../../../../core/constants/ui_palette.dart';
import '../../components/neu_surface.dart';

class DateModule extends StatelessWidget {
  const DateModule({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SizedBox(
        width: 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _weekdayShort(now.weekday),
              style: const TextStyle(
                color: UIPalette.textMuted,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            Text(
              '${now.day} ${_monthShort(now.month)}',
              style: const TextStyle(
                color: UIPalette.textSecondary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'SEN';
      case DateTime.tuesday:
        return 'SEL';
      case DateTime.wednesday:
        return 'RAB';
      case DateTime.thursday:
        return 'KAM';
      case DateTime.friday:
        return 'JUM';
      case DateTime.saturday:
        return 'SAB';
      case DateTime.sunday:
        return 'MIN';
      default:
        return '';
    }
  }

  String _monthShort(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'Mei';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Agu';
      case 9:
        return 'Sep';
      case 10:
        return 'Okt';
      case 11:
        return 'Nov';
      case 12:
        return 'Des';
      default:
        return '';
    }
  }
}
