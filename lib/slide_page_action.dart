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
      child: Icon(
        Icons.keyboard_double_arrow_down_sharp,
        size: 32,
      ),
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < 0) {
          Navigator.of(context).push(PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => pageName,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ));
        }
      },
    );
  }
}
