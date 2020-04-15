import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TextSizeButton extends StatefulWidget {
  const TextSizeButton({
    @required this.value,
    @required this.onChanged,
    Key key,
  })  : assert(value != null),
        assert(onChanged != null),
        super(key: key);

  final double value;
  final Function(double) onChanged;

  @override
  _TextSizeButtonState createState() => _TextSizeButtonState();
}

class _TextSizeButtonState extends State<TextSizeButton>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.format_size),
      onPressed: () =>
          Overlay.of(context).insertAll(_overlays(context).toList()),
    );
  }

  Iterable<OverlayEntry> _overlays(BuildContext context) sync* {
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    final position = _buttonPosition(context);
    final buttonsOverlay = OverlayEntry(builder: (context) {
      return Positioned(
        top: position.top,
        right: position.right,
        child: PopupPalette(
          animation: animationController,
          child: TextSizeAdjuster(
            value: widget.value,
            onChanged: widget.onChanged,
          ),
        ),
      );
    });
    OverlayEntry barrierOverlay;
    yield barrierOverlay = OverlayEntry(builder: (context) {
      return GestureDetector(
        onTapDown: (_) async {
          await animationController.reverse();
          barrierOverlay.remove();
          buttonsOverlay.remove();
          animationController.dispose();
        },
        behavior: HitTestBehavior.opaque,
      );
    });
    yield buttonsOverlay;
    animationController.forward();
  }

  RelativeRect _buttonPosition(BuildContext context) {
    // Copied from PopupMenuButtonState.showButtonMenu()
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    return RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
  }
}

class PopupPalette extends AnimatedWidget {
  const PopupPalette({
    @required Animation<double> animation,
    @required this.child,
    Key key,
  })  : assert(child != null),
        super(key: key, listenable: animation);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Material(
      type: MaterialType.card,
      elevation: PopupMenuTheme.of(context)?.elevation ?? 8,
      child: SizeTransition(
        sizeFactor: animation,
        axis: Axis.horizontal,
        axisAlignment: 1,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }
}

class TextSizeAdjuster extends StatefulWidget {
  const TextSizeAdjuster({
    @required this.value,
    @required this.onChanged,
    Key key,
  })  : assert(value != null),
        assert(onChanged != null),
        super(key: key);

  final double value;
  final Function(double) onChanged;

  @override
  _TextSizeAdjusterState createState() => _TextSizeAdjusterState();
}

const _kTextSizeAdjustmentIncrement = 10;
const _kTextSizeAdjustmentFactor = 100;

class _TextSizeAdjusterState extends State<TextSizeAdjuster> {
  double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value * _kTextSizeAdjustmentFactor;
  }

  void _setValue(double newValue) {
    setState(() {
      _value = newValue;
    });
    widget.onChanged(newValue / _kTextSizeAdjustmentFactor);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => _setValue(_value - _kTextSizeAdjustmentIncrement),
        ),
        Text(
          (_value / _kTextSizeAdjustmentFactor).toStringAsFixed(2),
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _setValue(_value + _kTextSizeAdjustmentIncrement),
        )
      ],
    );
  }
}
