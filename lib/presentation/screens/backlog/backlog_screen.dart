import 'package:flutter/material.dart';
import '../../../core/widgets/responsive_layout.dart';
import 'backlog_mobile_view.dart';
import 'backlog_desktop_view.dart';

class BacklogScreen extends StatelessWidget {
  const BacklogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const BacklogMobileView(),
      desktop: const BacklogDesktopView(),
    );
  }
}
