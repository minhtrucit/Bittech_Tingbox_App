import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../ting_box.dart';

class TransactionList extends StatelessWidget {
  final List<StatisticTransaction>? transactions;
  const TransactionList({super.key, this.transactions});

  @override
  Widget build(BuildContext context) {
    final txList = transactions ?? [];

    if (txList.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: 64.h),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Text('Chưa có giao dịch nào'),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 64.h),
      child: Column(
        children:
            txList.map((tx) {
              final isIncome = (tx.amount ?? 0) >= 0;
              final color = isIncome ? Colors.green : Colors.red;
              final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
              final bgColor = isIncome ? Colors.green[100] : Colors.red[100];

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24.sp),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.description ?? 'Giao dịch',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            tx.date != null
                                ? DateFormat(
                                  'HH:mm dd/MM/yyyy',
                                ).format(tx.date!)
                                : '',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      (tx.amount ?? 0).formatMoney(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
