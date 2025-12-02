import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../ting_box.dart';

class RevenuePieChart extends StatefulWidget {
  final IncomeSources? incomeSources;
  const RevenuePieChart({super.key, this.incomeSources});

  @override
  State<RevenuePieChart> createState() => _RevenuePieChartState();
}

class _RevenuePieChartState extends State<RevenuePieChart> {
  int touchedIndex = -1;

  final List<Color> _colors = [
    AppColors.primaryBlue,
    Colors.green,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    final sources = widget.incomeSources?.sources ?? [];
    final total = widget.incomeSources?.total ?? 0;

    if (sources.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Center(child: Text('Chưa có dữ liệu nguồn thu')),
      );
    }

    return IgnorePointer(
      ignoring: true,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 200.h,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex =
                                pieTouchResponse
                                    .touchedSection!
                                    .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 0,
                      centerSpaceRadius: 60.r,
                      sections: showingSections(sources),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tổng thu',
                          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                        ),
                        Text(
                          total.formatMoney(),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            ...List.generate(sources.length, (index) {
              final source = sources[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _buildLegendItem(
                  color: _colors[index % _colors.length],
                  text: source.name,
                  amount: source.amount.formatMoney(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections(List<IncomeSource> sources) {
    double currentAngle = 0;
    final totalValue = sources.fold(0.0, (sum, item) => sum + item.percentage);

    return List.generate(sources.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 35.0 : 30.0;
      final source = sources[i];

      final sweepAngle =
          totalValue > 0 ? (source.percentage / totalValue) * 360 : 0.0;
      final sectionCenterAngle = currentAngle + (sweepAngle / 2);
      final rotationAngle = sectionCenterAngle * (math.pi / 360);

      currentAngle += sweepAngle;

      return PieChartSectionData(
        color: _colors[i % _colors.length],
        value: source.percentage,
        title: '', // Hide default title
        radius: radius,
        badgeWidget:
            rotationAngle.isFinite
                ? Transform.rotate(
                  angle: rotationAngle,
                  child: Text(
                    '${source.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xffffffff),
                    ),
                  ),
                )
                : Text(
                  '${source.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xffffffff),
                  ),
                ),
        badgePositionPercentageOffset: 0.5,
      );
    });
  }

  Widget _buildLegendItem({
    required Color color,
    required String text,
    required String amount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 10.w),
            Text(
              text,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
