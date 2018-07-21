import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import '../rendering/parallax.dart';

/// A widget that applies a parallax effect on its child.
///
/// There are three options for constructing a [Parallax]:
///
///   1. The [Parallax.inside], that computes the parallax offset from its position
///   in its first [Scrollable] parent.
///   Useful for list or grid items.
///
///   2. The [Parallax.outside], that computes the parallax offset from the percentage
///   of the scrollable's container extent.
///   Useful for a list or grid background.
///
///   3. The [Parallax.custom] takes a [ParallaxDelegate], which provides the ability
///   to customize additional aspects of the child model. For example, a [ParallaxDelegate]
///   can control the algorithm used to computes the parallax offset of the child within its parent.
///
/// See also:
///
///  * [ParallaxSingleChildLayout], which uses a delegate to control the parallax layout of
///    a single child.
class Parallax extends StatelessWidget {
  /// Creates a parallax widget for a widget inside a scroll view.
  ///
  /// The [mainAxisExtent] and [flipDirection] arguments must not be null.
  /// The [mainAxisExtent] argument must be positive.
  const Parallax.inside({
    Key key,
    @required this.child,
    @required this.mainAxisExtent,
    this.direction,
    this.flipDirection = false,
  })  : assert(mainAxisExtent != null && mainAxisExtent >= 0.0),
        delegate = null,
        super(key: key);

  /// Creates a parallax widget for a widget outside a scroll view.
  ///
  /// The [controller] and [flipDirection] arguments must not be null.
  Parallax.outside({
    Key key,
    @required this.child,
    @required ScrollController controller,
    this.direction,
    this.flipDirection = false,
  })  : assert(controller != null),
        mainAxisExtent = null,
        delegate = new ParallaxOutsideDelegate(
            controller: controller,
            direction: direction,
            flipDirection: flipDirection),
        super(key: key);

  /// Creates a parallax widget with a custom parallax layout.
  ///
  /// The [delegate] argument must not be null.
  const Parallax.custom({
    Key key,
    @required this.child,
    @required this.delegate,
  })  : assert(delegate != null),
        mainAxisExtent = null,
        direction = null,
        flipDirection = null,
        super(key: key);

  /// The child of this widget.
  final Widget child;

  /// The delegate that controls the algorithm used to position the child within its parent.
  final ParallaxDelegate delegate;

  /// The extent of the child in the same axis as the scrolling.
  final double mainAxisExtent;

  /// The direction of the parallax effect when scroll offset increases.
  ///
  /// When null, the direction is the same as the [controller].
  final AxisDirection direction;

  /// Whether to flip the given [direction].
  ///
  /// Defaults to false.
  final bool flipDirection;

  @override
  Widget build(BuildContext context) {
    ParallaxDelegate parallaxDelegate = delegate;
    if (parallaxDelegate == null) {
      final ScrollPosition position = Scrollable.of(context).position;
      final ScrollController controller = new ScrollController();
      controller.attach(position);
      parallaxDelegate = new ParallaxInsideDelegate(
        mainAxisExtent: mainAxisExtent,
        direction: direction,
        controller: controller,
        flipDirection: flipDirection,
      );
    }

    return new ClipRect(
      child: new ParallaxSingleChildLayout(
        delegate: parallaxDelegate,
        child: child,
      ),
    );
  }
}

/// A widget that defers the parallax layout of its single child to a delegate.
///
/// The delegate can determine the layout constraints for the child and can
/// decide where to position the child. The delegate can also determine the size
/// of the parent, but the size of the parent cannot depend on the size of the
/// child.
///
/// See also:
///
///  * [ParallaxDelegate], which controls the parallax layout of the child.
class ParallaxSingleChildLayout extends SingleChildRenderObjectWidget {
  /// Creates a custom single child layout.
  ///
  /// The [delegate] argument must not be null.
  const ParallaxSingleChildLayout({
    Key key,
    @required this.delegate,
    Widget child,
  })  : assert(delegate != null),
        super(key: key, child: child);

  /// The delegate that controls the layout of the child.
  final ParallaxDelegate delegate;

  @override
  RenderParallaxSingleChildLayoutBox createRenderObject(BuildContext context) {
    return new RenderParallaxSingleChildLayoutBox(delegate: delegate);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderParallaxSingleChildLayoutBox renderObject) {
    renderObject.delegate = delegate;
  }
}
