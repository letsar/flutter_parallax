import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

class Parallax extends StatelessWidget {
  Parallax.outside({
    Key key,
    @required this.child,
    @required this.controller,
    this.followScrollDirection = true,
  })
      : assert(controller != null),
        assert(followScrollDirection != null),
        mainAxisExtent = null,
        delegate = null,
        super(key: key);

  const Parallax.inside({
    Key key,
    @required this.child,
    @required this.mainAxisExtent,
    this.followScrollDirection = true,
  })
      : assert(mainAxisExtent != null && mainAxisExtent >= 0.0),
        assert(followScrollDirection != null),
        delegate = null,
        controller = null,
        super(key: key);

  const Parallax.custom({
    Key key,
    @required this.child,
    @required this.delegate,
  })
      : assert(delegate != null),
        mainAxisExtent = null,
        followScrollDirection = null,
        controller = null,
        super(key: key);

  /// The child of this widget.
  final Widget child;

  final ParallaxLayoutDelegate delegate;

  final double mainAxisExtent;

  final bool followScrollDirection;

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    ParallaxLayoutDelegate parallaxLayoutDelegate = delegate;
    if (parallaxLayoutDelegate == null) {
      if (mainAxisExtent != null && mainAxisExtent >= 0.0) {
        final ScrollPosition position = Scrollable.of(context).position;
        final ScrollController controller = new ScrollController();
        controller.attach(position);
        parallaxLayoutDelegate = new ParallaxScrollItemLayout(
          mainAxisExtent: mainAxisExtent,
          followScrollDirection: followScrollDirection,
          controller: controller,
        );
      } else if (controller != null) {
        parallaxLayoutDelegate = new ParallaxLayout(
          controller: controller,
          followScrollDirection: followScrollDirection,
        );
      }
    }

    return new ClipRect(
      child: new ParallaxSingleChildLayout(
        delegate: parallaxLayoutDelegate,
        child: child,
      ),
    );
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
  })
      : assert(controller != null),
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
  })
      : assert(mainAxisExtent != null && mainAxisExtent >= 0.0),
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
  })
      : super(
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

class RenderParallaxChildLayoutBox extends RenderShiftedBox {
  RenderParallaxChildLayoutBox({
    RenderBox child,
    @required ParallaxLayoutDelegate delegate,
  })
      : assert(delegate != null),
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
  })
      : assert(delegate != null),
        super(key: key, child: child);

  /// The delegate that controls the layout of the child.
  final ParallaxLayoutDelegate delegate;

  @override
  RenderParallaxChildLayoutBox createRenderObject(BuildContext context) {
    return new RenderParallaxChildLayoutBox(delegate: delegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderParallaxChildLayoutBox renderObject) {
    renderObject.delegate = delegate;
  }
}
