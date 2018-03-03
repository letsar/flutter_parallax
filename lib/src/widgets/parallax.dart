import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

class Parallax extends StatelessWidget {
  const Parallax({
    Key key,
    @required this.child,
    @required this.extent,
    this.controller,
  })
      : super(key: key);

  final Widget child;

  final double extent;

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
