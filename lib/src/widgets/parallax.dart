import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

class Parallax extends StatelessWidget {
  Parallax.outside({
    Key key,
    @required this.child,
    @required ScrollController controller,
    this.direction,
  })  : assert(controller != null),
        mainAxisExtent = null,
        delegate = new ParallaxOutsideDelegate(
          controller: controller,
            direction : direction,
        ),
        super(key: key);

  const Parallax.inside({
    Key key,
    @required this.child,
    @required this.mainAxisExtent,
    this.direction,
  })  : assert(mainAxisExtent != null && mainAxisExtent >= 0.0),
        delegate = null,
        super(key: key);

  const Parallax.custom({
    Key key,
    @required this.child,
    @required this.delegate,
  })  : assert(delegate != null),
        mainAxisExtent = null,
        direction = null,
        super(key: key);

  /// The child of this widget.
  final Widget child;

  final ParallaxDelegate delegate;

  final double mainAxisExtent;

  final AxisDirection direction;

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

abstract class ParallaxDelegate {
  const ParallaxDelegate({
    @required this.controller,
  }) : assert(controller != null);

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
  /// provided to the [RenderCustomSingleChildLayoutBox] object, or any time
  /// that a new [CustomSingleChildLayout] object is created with a new instance
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

abstract class ParallaxWithAxisDirectionDelegate extends ParallaxDelegate {
  /// Creates a parallax delegate that indicates the axis of its own scroll direction.
  const ParallaxWithAxisDirectionDelegate({
    @required ScrollController controller,
    this.direction,
  })  : assert(controller != null),
        super(controller: controller);

  /// The direction of the parallax effect when scrolling.
  ///
  /// When null, the direction is the same as the [controller].
  final AxisDirection direction;

  static Offset _getOffsetUnit(AxisDirection direction) {
    switch (direction) {
      case AxisDirection.up:
      case AxisDirection.down:
        return const Offset(0.0, -1.0);
      case AxisDirection.left:
      case AxisDirection.right:
        return const Offset(-1.0, 0.0);
    }
    return null;
  }

  @override
  bool shouldRelayout(ParallaxWithAxisDirectionDelegate oldDelegate) {
    return super.shouldRelayout(oldDelegate) || direction != oldDelegate.direction;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final Axis axis = controller.position?.axis;
    assert(axis != null);
    return axis == Axis.horizontal ? constraints.heightConstraints() : constraints.widthConstraints();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize, RenderBox renderBox) {
    final ScrollPosition position = controller.position;
    assert(position != null);

    final AxisDirection parallaxDirection = direction ?? position.axisDirection;
    assert(parallaxDirection != null);

    final Offset offsetUnit = _getOffsetUnit(parallaxDirection);
    final bool isHorizontalAxis = (position.axis == Axis.horizontal);

    final double childExtent = isHorizontalAxis ? childSize.width : childSize.height;
    final double mainAxisExtent = isHorizontalAxis ? size.width : size.height;

    if (mainAxisExtent < childExtent) {
      final double scrollRatio = getChildScrollRatio(offsetUnit, childExtent, renderBox);
      final offset = childExtent - lerpDouble(mainAxisExtent, childExtent, scrollRatio);

      return offsetUnit * offset;
    } else {
      return Offset.zero;
    }
  }

  double getChildScrollRatio(Offset offsetUnit, double childExtent, RenderBox renderBox);
}

class ParallaxInsideDelegate extends ParallaxWithAxisDirectionDelegate {
  const ParallaxInsideDelegate({
    @required ScrollController controller,
    @required this.mainAxisExtent,
    AxisDirection direction,
  })  : assert(mainAxisExtent != null && mainAxisExtent >= 0.0),
        super(
          controller: controller,
          direction: direction,
        );

  final double mainAxisExtent;

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
    final Offset localPositionOffset = offsetUnit * mainAxisExtent;
    final Offset positionInViewport = renderBox.localToGlobal(localPositionOffset, ancestor: viewport);

    // One dimension should be 0.0, so this should be ok.
    final double distanceFromLeading = math.max(positionInViewport.dx, positionInViewport.dy);

    double scrollRatio = 1.0 - distanceFromLeading / (controller.position.viewportDimension + mainAxisExtent);
//    if (followScrollDirection) {
//      scrollRatio = 1.0 - scrollRatio;
//    }

    return scrollRatio;
  }
}

class ParallaxOutsideDelegate extends ParallaxWithAxisDirectionDelegate {
  const ParallaxOutsideDelegate({
    @required ScrollController controller,
    AxisDirection direction,
  }) : super(
          controller: controller,
          direction: direction,
        );

  @override
  double getChildScrollRatio(Offset offsetUnit, double childExtent, RenderBox renderBox) {
    double scrollRatio = 1.0; //followScrollDirection ? 1.0 : 0.0;
    final ScrollPosition position = controller.position;
    final double offset = controller.offset;
    final double minScrollExtent = position?.minScrollExtent ?? double.negativeInfinity;
    final double maxScrollExtent = position?.maxScrollExtent ?? double.infinity;

    if (minScrollExtent.isFinite && maxScrollExtent.isFinite) {
      scrollRatio = 1.0 - (offset - minScrollExtent) / (maxScrollExtent - minScrollExtent);
//      if (followScrollDirection) {
//        scrollRatio = 1.0 - scrollRatio;
//      }
    }
    return scrollRatio;
  }
}

abstract class ParallaxLayoutDelegate {
  /// Creates a layout delegate.
  ///
  /// The layout will update whenever [controller] notifies its listeners.
  const ParallaxLayoutDelegate({
    @required this.controller,
    this.mainAxisExtent,
    this.followScrollDirection = true,
  })  : assert(controller != null),
        assert(followScrollDirection != null);

  final double mainAxisExtent;

  final ScrollController controller;

  final bool followScrollDirection;

  double getChildScrollRatio(Offset offsetUnit, double childExtent, RenderBox renderBox);

  /// Called whenever a new instance of the custom layout delegate class is
  /// provided to the [RenderParallaxChildLayoutBox] object, or any time
  /// that a new [ParallaxSingleChildLayout] object is created with a new instance
  /// of the custom layout delegate class (which amounts to the same thing,
  /// because the latter is implemented in terms of the former).
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// It's possible that the layout methods will get called even if
  /// [shouldRelayout] returns false (e.g. if an ancestor changed its layout).
  /// It's also possible that the layout method will get called
  /// without [shouldRelayout] being called at all (e.g. if the parent changes
  /// size).
  bool shouldRelayout(covariant ParallaxLayoutDelegate oldDelegate) {
    return mainAxisExtent != oldDelegate.mainAxisExtent || controller != oldDelegate.controller || followScrollDirection != oldDelegate.followScrollDirection;
  }
}

/// Scrolls child content according to the parent scroll offset.
class ParallaxScrollItemLayout extends ParallaxLayoutDelegate {
  const ParallaxScrollItemLayout({
    @required double mainAxisExtent,
    @required ScrollController controller,
    bool followScrollDirection = true,
  })  : assert(mainAxisExtent != null && mainAxisExtent >= 0.0),
        super(
          mainAxisExtent: mainAxisExtent,
          controller: controller,
          followScrollDirection: followScrollDirection,
        );

  @override
  double getChildScrollRatio(Offset offsetUnit, double childExtent, RenderBox renderBox) {
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderBox);
    assert(viewport != null);
    final Offset localPositionOffset = offsetUnit * mainAxisExtent;
    final Offset positionInViewport = renderBox.localToGlobal(localPositionOffset, ancestor: viewport);

    // One dimension should be 0.0, so this should be ok.
    final double distanceFromLeading = math.max(positionInViewport.dx, positionInViewport.dy);

    double scrollRatio = distanceFromLeading / (controller.position.viewportDimension + mainAxisExtent);
    if (followScrollDirection) {
      scrollRatio = 1.0 - scrollRatio;
    }

    return scrollRatio;
  }
}

/// Scrolls child content according to the overall scroll percentage.
class ParallaxLayout extends ParallaxLayoutDelegate {
  const ParallaxLayout({
    @required ScrollController controller,
    bool followScrollDirection = true,
  }) : super(
          controller: controller,
          followScrollDirection: followScrollDirection,
        );

  @override
  double getChildScrollRatio(Offset offsetUnit, double childExtent, RenderBox renderBox) {
    double scrollRatio = followScrollDirection ? 1.0 : 0.0;
    final ScrollPosition position = controller.position;
    final double offset = controller.offset;
    final double minScrollExtent = position?.minScrollExtent ?? double.negativeInfinity;
    final double maxScrollExtent = position?.maxScrollExtent ?? double.infinity;

    if (minScrollExtent.isFinite && maxScrollExtent.isFinite) {
      scrollRatio = (offset - minScrollExtent) / (maxScrollExtent - minScrollExtent);
      if (followScrollDirection) {
        scrollRatio = 1.0 - scrollRatio;
      }
    }
    return scrollRatio;
  }
}

class RenderParallax extends RenderShiftedBox {
  RenderParallax({RenderBox child, @required ParallaxDelegate delegate})
      : assert(delegate != null),
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

class RenderParallaxChildLayoutBox extends RenderShiftedBox {
  RenderParallaxChildLayoutBox({
    RenderBox child,
    @required ParallaxLayoutDelegate delegate,
  })  : assert(delegate != null),
        _delegate = delegate,
        super(child);

  /// A delegate that controls this object's layout.
  ParallaxLayoutDelegate get delegate => _delegate;
  ParallaxLayoutDelegate _delegate;
  set delegate(ParallaxLayoutDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate) return;
    final ParallaxLayoutDelegate oldDelegate = _delegate;
    if (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRelayout(oldDelegate)) markNeedsLayout();
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

  @override
  void performLayout() {
    final ScrollPosition scrollPosition = _delegate?.controller?.position;
    assert(scrollPosition != null);

    final AxisDirection direction = scrollPosition.axisDirection;
    final double extent = _delegate?.mainAxisExtent;

    final bool followScrollDirection = _delegate?.followScrollDirection;
    assert(followScrollDirection != null);

    final Axis scrollAxis = scrollPosition.axis;
    final bool isHorizontalAxis = (scrollAxis == Axis.horizontal);
    final Offset offsetUnit = isHorizontalAxis ? const Offset(1.0, 0.0) : const Offset(0.0, 1.0);

    if (extent != null && extent >= 0) {
      size = constraints.constrain(new Size(isHorizontalAxis ? extent : constraints.maxWidth, isHorizontalAxis ? constraints.maxHeight : extent));
    } else {
      size = constraints.constrain(new Size(constraints.maxWidth, constraints.maxHeight));
    }

    if (child != null) {
      final BoxConstraints childConstraints = isHorizontalAxis ? constraints.heightConstraints() : constraints.widthConstraints();
      assert(childConstraints.debugAssertIsValid(isAppliedConstraint: true));
      child.layout(childConstraints, parentUsesSize: !childConstraints.isTight);
      final BoxParentData childParentData = child.parentData;
      Size childSize = childConstraints.isTight ? childConstraints.smallest : child.size;

      double childExtent = isHorizontalAxis ? childSize.width : childSize.height;

      final double mainAxisExtent = scrollPosition.axis == Axis.horizontal ? size.width : size.height;
      if (mainAxisExtent < childExtent && _delegate != null) {
        final double scrollRatio = _delegate.getChildScrollRatio(offsetUnit, childExtent, this);
        final offset = childExtent - lerpDouble(mainAxisExtent, childExtent, scrollRatio);

        childParentData.offset = -(offsetUnit * offset);
      }
    }
  }
}

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
  RenderParallax createRenderObject(BuildContext context) {
    return new RenderParallax(delegate: delegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderParallax renderObject) {
    renderObject.delegate = delegate;
  }
}
