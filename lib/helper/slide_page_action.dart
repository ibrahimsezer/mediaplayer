import 'package:flutter/material.dart';

class SlidePageAction extends StatelessWidget {
  final Widget pageName;

  const SlidePageAction({
    super.key,
    required this.pageName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToPage(context),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          _navigateToPage(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Icon(
          Icons.keyboard_double_arrow_up_sharp,
          size: 32,
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SafeArea(
          child: Scaffold(
            body: pageName,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
