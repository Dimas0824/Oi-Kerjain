import 'package:flutter/material.dart';

import '../../../../core/constants/ui_palette.dart';
import '../../../../core/constants/ui_typography.dart';
import '../../../../core/utils/indonesian_date_formatter.dart';
import '../../components/neu_surface.dart';

class HistoryDateCard extends StatelessWidget {
  const HistoryDateCard({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      key: const Key('history-date-card'),
      radius: 16,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SizedBox(
        width: 122,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              IndonesianDateFormatter.weekdayName(date.weekday).toUpperCase(),
              style: UITypography.micro.copyWith(
                letterSpacing: 1,
                color: UIPalette.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date.day.toString(),
              style: UITypography.pageTitle.copyWith(fontSize: 24, height: 1.1),
            ),
            Text(
              IndonesianDateFormatter.monthName(date.month),
              style: UITypography.captionStrong,
            ),
            Text(
              date.year.toString(),
              style: UITypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
