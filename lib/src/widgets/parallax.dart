import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

class Parallax extends StatelessWidget {
  const Parallax({
    Key key,
    @required this.child,
    @required this.mainAxisExtent,
    this.followScrollDirection = true,
    this.controller,
  })
      : assert(mainAxisExtent != null && mainAxisExtent >= 0.0),
        assert(followScrollDirection != null),
        super(key: key);

  /// The child of this widget.
  final Widget child;

  final double mainAxisExtent;

  final bool followScrollDirection;

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final ScrollPosition scrollPosition = controller?.position ?? Scrollable.of(context)?.position;
    return new ClipRect(
      child: new ParallaxChildLayout(
        extent: mainAxisExtent,
        scrollPosition: scrollPosition,
        followScrollDirection: followScrollDirection,
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DoubleProperty('mainAxisExtent', mainAxisExtent));
    description.add(new DiagnosticsProperty('followScrollDirection', followScrollDirection));
  }
}

class RenderParallaxChildLayoutBox extends RenderShiftedBox {
  RenderParallaxChildLayoutBox({
    RenderBox child,
    @required double extent,
    @required ScrollPosition scrollPosition,
    bool followScrollDirection = true,
  })
      : assert(extent != null),
        assert(scrollPosition != null),
        assert(followScrollDirection != null),
        _extent = extent,
        _scrollPosition = scrollPosition,
        _followScrollDirection = followScrollDirection,
        super(child);

  double get extent => _extent;
  double _extent;
  set extent(double value) {
    assert(value >= 0.0);
    if (_extent == value) return;
    _extent = value;
    markNeedsLayout();
  }

  bool get followScrollDirection => _followScrollDirection;
  bool _followScrollDirection;
  set followScrollDirection(bool value) {
    assert(value != null);
    if (_followScrollDirection == value) return;
    _followScrollDirection = value;
    markNeedsLayout();
  }

  ScrollPosition get scrollPosition => _scrollPosition;
  ScrollPosition _scrollPosition;
  set scrollPosition(ScrollPosition newScrollPosition) {
    assert(newScrollPosition != null);
    if (_scrollPosition == newScrollPosition) return;
    final ScrollPosition oldScrollPosition = _scrollPosition;
    _scrollPosition = newScrollPosition;
    markNeedsLayout();

    if (attached) {
      oldScrollPosition?.removeListener(markNeedsLayout);
      newScrollPosition?.addListener(markNeedsLayout);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scrollPosition.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _scrollPosition.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void performLayout() {
    final Offset offsetUnit = scrollPosition.axis == Axis.horizontal ? const Offset(1.0, 0.0) : const Offset(0.0, 1.0);
    switch (scrollPosition.axis) {
      case Axis.horizontal:
        size = constraints.constrain(new Size(extent, constraints.maxHeight));
        break;
      case Axis.vertical:
        size = constraints.constrain(new Size(constraints.maxWidth, extent));
        break;
    }

    if (child != null) {
      final BoxConstraints childConstraints = constraints;
      assert(childConstraints.debugAssertIsValid(isAppliedConstraint: true));
      child.layout(childConstraints, parentUsesSize: !childConstraints.isTight);
      final BoxParentData childParentData = child.parentData;
      Size childSize = childConstraints.isTight ? childConstraints.smallest : child.size;

      double childExtent;
      final Offset localPositionOffset = offsetUnit * extent;
      switch (scrollPosition.axis) {
        case Axis.horizontal:
          childExtent = childSize.width;
          break;
        case Axis.vertical:
          childExtent = childSize.height;
          break;
      }

      if (extent < childExtent) {
        final RenderAbstractViewport viewport = RenderAbstractViewport.of(child);
        assert(viewport != null);
        final Offset positionInViewport = this.localToGlobal(localPositionOffset, ancestor: viewport);

        // One dimension should be 0.0, so this should be ok.
        final double distanceFromLeading = math.max(positionInViewport.dx, positionInViewport.dy);

        double scrollRatio = distanceFromLeading / (scrollPosition.viewportDimension + extent);
        if (followScrollDirection) {
          scrollRatio = 1 - scrollRatio;
        }

        final offset = childExtent - lerpDouble(extent, childExtent, scrollRatio);

        childParentData.offset = -(offsetUnit * offset);
      } else {
        childParentData.offset = Offset.zero;
      }
    }
  }
}

class ParallaxChildLayout extends SingleChildRenderObjectWidget {
  /// Creates a custom single child layout.
  const ParallaxChildLayout({
    Key key,
    @required this.extent,
    @required this.scrollPosition,
    this.followScrollDirection = true,
    Widget child,
  })
      : assert(extent >= 0.0),
        assert(scrollPosition != null),
        assert(followScrollDirection != null),
        super(key: key, child: child);

  final double extent;

  final ScrollPosition scrollPosition;

  final bool followScrollDirection;

  @override
  RenderParallaxChildLayoutBox createRenderObject(BuildContext context) {
    return new RenderParallaxChildLayoutBox(
      extent: extent,
      scrollPosition: scrollPosition,
      followScrollDirection: followScrollDirection,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderParallaxChildLayoutBox renderObject) {
    renderObject
      ..scrollPosition = scrollPosition
      ..extent = extent
      ..followScrollDirection = followScrollDirection;
  }
}
