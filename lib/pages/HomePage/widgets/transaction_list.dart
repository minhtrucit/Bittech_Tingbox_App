import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final transactions = [
      {
        'icon': Icons.coffee,
        'title': 'Cà phê sữa',
        'time': '10:30 AM',
        'amount': '+35.000đ',
        'isIncome': true,
        'color': Colors.blue[100],
        'iconColor': Colors.blue,
      },
      {
        'icon': Icons.receipt_long,
        'title': 'Chi tiền điện',
        'time': '09:15 AM',
        'amount': '-500.000đ',
        'isIncome': false,
        'color': Colors.red[100],
        'iconColor': Colors.red,
      },
      {
        'icon': Icons.credit_card,
        'title': 'Bán 2 Bạc xỉu',
        'time': '08:45 AM',
        'amount': '+70.000đ',
        'isIncome': true,
        'color': Colors.green[100],
        'iconColor': Colors.green,
      },
      {
        'icon': Icons.qr_code,
        'title': 'Trà đào cam sả',
        'time': '08:30 AM',
        'amount': '+45.000đ',
        'isIncome': true,
        'color': Colors.amber[100],
        'iconColor': Colors.amber,
      },
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: 64.h),
      child: Column(
        children:
            transactions.map((tx) {
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
                        color: tx['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        tx['icon'] as IconData,
                        color: tx['iconColor'] as Color,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx['title'] as String,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            tx['time'] as String,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      tx['amount'] as String,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color:
                            (tx['isIncome'] as bool)
                                ? Colors.green
                                : Colors.red,
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
