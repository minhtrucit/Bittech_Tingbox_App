import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../ting_box.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void handleLogout(BuildContext context) async {
    await UserRepository.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Auth()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.white,
      appBar: AppAppBar(
        title: TitleAppbarText(title: 'Quản lý doanh thu'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: IconButton(
              icon: Icon(Icons.calendar_today_outlined, color: Colors.black),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          spacing: 20.h,
          children: [
            buildMainCard(
              context,
              title: Text(
                'Số dư hiện tại',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
              amount: Text(
                '15,000,000đ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28.sp,
                ),
              ),
              initialBalance: Text(
                'Số dư đầu kỳ: 10,000,000đ',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
            ),
            Row(
              spacing: 8.w,
              children: [
                Expanded(
                  child: buildMainCard(
                    context,
                    side: BorderSide(width: 0.2.w, color: Colors.grey),
                    title: Text(
                      'Tổng thu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    amount: Text(
                      '8,500,000đ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                    initialBalance: RichText(
                      text: TextSpan(
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.green),
                        children: [
                          WidgetSpan(
                            child: Icon(
                              Icons.arrow_upward,
                              size: 20.w,
                              color: Colors.green,
                            ),
                          ),
                          WidgetSpan(child: SizedBox(width: 2.w)),
                          TextSpan(text: 'Tăng 5.2%'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: buildMainCard(
                    context,
                    side: BorderSide(width: 0.2.w, color: Colors.grey),
                    title: Text(
                      'Tổng chi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    amount: Text(
                      '3,500,000đ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                    initialBalance: RichText(
                      text: TextSpan(
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                        children: [
                          WidgetSpan(
                            child: Icon(
                              Icons.arrow_downward,
                              color: Colors.red,
                            ),
                          ),
                          WidgetSpan(child: SizedBox(width: 2.w)),

                          TextSpan(text: 'Giảm 1.2%'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SizedBox buildMainCard(
    BuildContext context, {
    required Text title,
    required Text amount,
    required Widget initialBalance,
    BorderSide? side,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Card(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.r)),
          side: side ?? BorderSide.none,
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            spacing: 8.h,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, amount, initialBalance],
          ),
        ),
      ),
    );
  }
}
