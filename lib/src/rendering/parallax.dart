import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

/// A delegate that controls the parallax effect of a [Parallax] widget.
///
/// Used by [ParallaxSingleChildLayout] (in the widgets folder) and
/// [RenderParallaxSingleChildLayoutBox] (in this file).
///
/// When asked to layout, [RenderParallaxSingleChildLayoutBox] first calls [getSize] with
/// its incoming constraints to determine its size. It then calls
/// [getConstraintsForChild] to determine the constraints to apply to the child.
/// After the child completes its layout, [RenderParallaxSingleChildLayoutBox]
/// calls [getPositionForChild] to determine the child's position.
///
/// The [shouldRelayout] method is called when a new instance of the class
/// is provided, to check if the new instance actually represents different
/// information.
///
/// See also:
///
///  * [ParallaxSingleChildLayout], the widget that uses this delegate.
///  * [RenderParallaxSingleChildLayoutBox], render object that uses this
///    delegate.
abstract class ParallaxDelegate {
  /// Creates a parallax layout delegate.
  ///
  /// The layout will update whenever [controller] notifies its listeners.
  const ParallaxDelegate({
    @required this.controller,
  }) : assert(controller != null);

  /// The controller used to update the parallax offset.
  final ScrollController controller;

  /// The size of this object given the incoming constraints.
  ///
  /// Defaults to the biggest size that satisfies the given constraints.
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  /// The constraints for the child given the incoming constraints.
  ///
  /// During layout, the child is given the layout constraints returned by this
  /// function. The child is required to pick a size for itself that satisfies
  /// these constraints.
  ///
  /// Defaults to the given constraints.
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints;

  /// The position where the child should be placed.
  ///
  /// The `size` argument is the size of the parent, which might be different
  /// from the value returned by [getSize] if that size doesn't satisfy the
  /// constraints passed to [getSize]. The `childSize` argument is the size of
  /// the child, which will satisfy the constraints returned by
  /// [getConstraintsForChild].
  ///
  /// Defaults to positioning the child in the upper left corner of the parent.
  Offset getPositionForChild(Size size, Size childSize, RenderBox renderBox) => Offset.zero;

  /// Called whenever a new instance of the custom layout delegate class is
  /// provided to the [RenderParallaxSingleChildLayoutBox] object, or any time
  /// that a new [ParallaxSingleChildLayout] object is created with a new instance
  /// of the custom layout delegate class (which amounts to the same thing,
  /// because the latter is implemented in terms of the former).
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If the method returns false, then the [getSize],
  /// [getConstraintsForChild], and [getPositionForChild] calls might be
  /// optimized away.
  ///
  /// It's possible that the layout methods will get called even if
  /// [shouldRelayout] returns false (e.g. if an ancestor changed its layout).
  /// It's also possible that the layout method will get called
  /// without [shouldRelayout] being called at all (e.g. if the parent changes
  /// size).
  bool shouldRelayout(covariant ParallaxDelegate oldDelegate) {
    return controller != oldDelegate.controller;
  }
}

/// A parallax layout delegate that follows a given direction when scrolled.
///
/// See also:
///
///  * [ParallaxInsideDelegate], which is a delegate for widgets inside a scroll view.
///  * [ParallaxOutsideDelegate], which is a delegate for widgets outside a scroll view.
abstract class ParallaxWithAxisDirectionDelegate extends ParallaxDelegate {
  /// Creates a parallax layout delegate that indicates its own scroll direction
  /// independently of the [controller.position] one.
  ///
  /// The [controller] and [flipDirection] arguments must not be null.
  const ParallaxWithAxisDirectionDelegate({
    @required ScrollController controller,
    this.direction,
    this.flipDirection = false,
  })  : assert(controller != null),
        assert(flipDirection != null),
        super(controller: controller);

  /// The direction of the parallax effect when scroll offset increases.
  ///
  /// When null, the direction is the same as the [controller].
  final AxisDirection direction;

  /// Whether to flip the given [direction].
  ///
  /// Defaults to false.
  final bool flipDirection;

  static Offset _getOffsetUnit(AxisDirection direction) {
    switch (direction) {
      case AxisDirection.up:
      case AxisDirection.down:
        return const Offset(0.0, 1.0);
      case AxisDirection.left:
      case AxisDirection.right:
        return const Offset(1.0, 0.0);
    }
    return null;
  }

  @override
  bool shouldRelayout(ParallaxWithAxisDirectionDelegate oldDelegate) {
    return super.shouldRelayout(oldDelegate) || direction != oldDelegate.direction;
  }

  @override
  Offset getPositionForChild(Size size, Size childSize, RenderBox renderBox) {
    final ScrollPosition position = controller.position;
    assert(position != null);

    final AxisDirection parallaxDirection = _getParallaxDirection();
    final Axis parallaxAxis = axisDirectionToAxis(parallaxDirection);

    final Offset offsetUnit = _getOffsetUnit(parallaxDirection);

    final double childExtent = (parallaxAxis == Axis.horizontal) ? childSize.width : childSize.height;
    final double mainAxisExtent = (parallaxAxis == Axis.horizontal) ? size.width : size.height;

    if (mainAxisExtent < childExtent) {
      double scrollRatio = getChildScrollRatio(offsetUnit, childExtent, renderBox);
      if (parallaxDirection == AxisDirection.down || parallaxDirection == AxisDirection.right) {
        scrollRatio = 1.0 - scrollRatio;
      }

      final offset = childExtent - lerpDouble(mainAxisExtent, childExtent, scrollRatio);

      return -(offsetUnit * offset);
    } else {
      return Offset.zero;
    }
  }

  double getChildScrollRatio(Offset offsetUnit, double childExtent, RenderBox renderBox);

  AxisDirection _getParallaxDirection() {
    AxisDirection parallaxDirection = direction ?? controller?.position?.axisDirection;
    if (flipDirection) {
      parallaxDirection = flipAxisDirection(parallaxDirection);
    }
    assert(parallaxDirection != null);
    return parallaxDirection;
  }
}

/// A parallax delegate for a widget inside a scroll view.
///
/// The parallax offset is determined by the position of the widget within its first [Scrollable]
/// parent.
class ParallaxInsideDelegate extends ParallaxWithAxisDirectionDelegate {
  /// Creates a parallax layout delegate for widgets inside a scroll view.
  ///
  /// The [controller], [mainAxisExtent] and [flipDirection] arguments must not be null.
  /// The [mainAxisExtent] argument must be positive.
  const ParallaxInsideDelegate({
    @required ScrollController controller,
    @required this.mainAxisExtent,
    AxisDirection direction,
    bool flipDirection = false,
  })  : assert(mainAxisExtent != null && mainAxisExtent >= 0.0),
        super(
          controller: controller,
          direction: direction,
          flipDirection: flipDirection,
        );

  /// The extent of the layout in the same axis as the scrolling.
  final double mainAxisExtent;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final AxisDirection parallaxDirection = _getParallaxDirection();
    final Axis parallaxAxis = axisDirectionToAxis(parallaxDirection);
    final Axis scrollAxis = controller?.position?.axis;

    if (scrollAxis == parallaxAxis) {
      return scrollAxis == Axis.horizontal ? constraints.heightConstraints() : constraints.widthConstraints();
    } else {
      return scrollAxis == Axis.horizontal
          ? constraints.widthConstraints().tighten(width: mainAxisExtent)
          : constraints.heightConstraints().tighten(height: mainAxisExtent);
    }
  }

  @override
  Size getSize(BoxConstraints constraints) {
    final ScrollPosition position = controller.position;
    assert(position != null);
    final bool isHorizontalAxis = (position.axis == Axis.horizontal);

    return constraints.constrain(new Size(isHorizontalAxis ? mainAxisExtent : constraints.maxWidth, isHorizontalAxis ? constraints.maxHeight : mainAxisExtent));
  }

  @override
  double getChildScrollRatio(Offset offsetUnit, double childExtent, RenderBox renderBox) {
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderBox);
    assert(viewport != null);

    final ScrollPosition position = controller.position;
    assert(position != null);
    final bool isHorizontalAxis = (position.axis == Axis.horizontal);

    final Offset localPositionOffset = isHorizontalAxis ? new Offset(mainAxisExtent, 0.0) : new Offset(0.0, mainAxisExtent); //offsetUnit * mainAxisExtent;
    final Offset positionInViewport = renderBox.localToGlobal(localPositionOffset, ancestor: viewport);

    // One dimension should be 0.0, so this should be ok.
    final double distanceFromLeading = math.max(positionInViewport.dx, positionInViewport.dy);

    double scrollRatio = distanceFromLeading / (controller.position.viewportDimension + mainAxisExtent);
    return scrollRatio;
  }
}

/// A parallax delegate for a widget outside a scroll view, or for a widget where the parallax offset does
/// not depend on its position within its first [Scrollable] parent.
class ParallaxOutsideDelegate extends ParallaxWithAxisDirectionDelegate {
  /// Creates a delegate for a widget outside a scroll view.
  ///
  /// The [controller] and [flipDirection] arguments must not be null.
  const ParallaxOutsideDelegate({
    @required ScrollController controller,
    AxisDirection direction,
    bool flipDirection = false,
  }) : super(
          controller: controller,
          direction: direction,
          flipDirection: flipDirection,
        );

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final AxisDirection parallaxDirection = _getParallaxDirection();
    final Axis parallaxAxis = axisDirectionToAxis(parallaxDirection);

    return parallaxAxis == Axis.horizontal ? constraints.heightConstraints() : constraints.widthConstraints();
  }

  @override
  double getChildScrollRatio(Offset offsetUnit, double childExtent, RenderBox renderBox) {
    double scrollRatio = 0.0;
    final ScrollPosition position = controller.position;
    final double offset = controller.offset;
    final double minScrollExtent = position?.minScrollExtent ?? double.negativeInfinity;
    final double maxScrollExtent = position?.maxScrollExtent ?? double.infinity;

    if (minScrollExtent.isFinite && maxScrollExtent.isFinite) {
      scrollRatio = (offset - minScrollExtent) / (maxScrollExtent - minScrollExtent);
    }
    return scrollRatio;
  }
}

/// Defers the parallax layout of its single child to a delegate.
///
/// The delegate can determine the layout constraints for the child and can
/// decide where to position the child. The delegate can also determine the size
/// of the parent, but the size of the parent cannot depend on the size of the
/// child.
class RenderParallaxSingleChildLayoutBox extends RenderShiftedBox {
  /// Creates a render box that defers its parallax layout to a delegate.
  ///
  /// The [delegate] argument must not be null.
  RenderParallaxSingleChildLayoutBox({
    RenderBox child,
    @required ParallaxDelegate delegate,
  })  : assert(delegate != null),
        _delegate = delegate,
        super(child);

  /// A delegate that controls this object's layout.
  ParallaxDelegate get delegate => _delegate;
  ParallaxDelegate _delegate;
  set delegate(ParallaxDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate) {
      return;
    }
    final ParallaxDelegate oldDelegate = _delegate;
    if (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRelayout(oldDelegate)) {
      markNeedsLayout();
    }
    _delegate = newDelegate;
    if (attached) {
      oldDelegate?.controller?.removeListener(markNeedsLayout);
      newDelegate?.controller?.addListener(markNeedsLayout);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _delegate?.controller?.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _delegate?.controller?.removeListener(markNeedsLayout);
    super.detach();
  }

  Size _getSize(BoxConstraints constraints) {
    return constraints.constrain(_delegate.getSize(constraints));
  }

  @override
  void performLayout() {
    size = _getSize(constraints);
    if (child != null) {
      final BoxConstraints childConstraints = delegate.getConstraintsForChild(constraints);
      assert(childConstraints.debugAssertIsValid(isAppliedConstraint: true));
      child.layout(childConstraints, parentUsesSize: !childConstraints.isTight);
      final BoxParentData childParentData = child.parentData;
      childParentData.offset = delegate.getPositionForChild(size, childConstraints.isTight ? childConstraints.smallest : child.size, this);
    }
  }
}
