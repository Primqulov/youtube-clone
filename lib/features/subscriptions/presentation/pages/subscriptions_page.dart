import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.subscriptions_outlined,
                color: AppTheme.primaryColor,
                size: 72,
              ),
              SizedBox(height: 20),
              Text(
                AppStrings.subscriptionsTitle,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppDimensions.fontSizeHeadingLg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppDimensions.paddingSm),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingXxl),
                child: Text(
                  AppStrings.subscriptionsSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
