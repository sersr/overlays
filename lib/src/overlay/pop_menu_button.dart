import 'package:flutter_nop/flutter_nop.dart';
import 'package:material_ui/material_ui.dart';
import 'package:overlays/overlays.dart';

class PopMenuButton extends StatefulWidget {
  const new({
    super.key,
    required this.builder,
    required this.buildMenu,
    this.background = Colors.transparent,
  });
  final Widget Function(BuildContext context, PopMenuButtonState state) builder;
  final Widget Function(BuildContext context, PopMenuButtonState state)
  buildMenu;

  final Color background;
  @override
  State<PopMenuButton> createState() => PopMenuButtonState();
}

class PopMenuButtonState extends State<PopMenuButton> {
  MenuDelegate? _menu;
  final _key = GlobalKey();

  void _initMenu() {
    if (_menu case var menu? when menu.active) return;

    final box = _key.currentContext?.findRenderObject();
    if (box case RenderBox box) {
      final size = box.size;
      final offset = box.localToGlobal(.zero);
      _menu = Overlays.menu(
        widget.buildMenu(context, this),
        anchorGlobal: offset & size,
        color: widget.background,
        transition: (child, self, alignment) {
          final align = alignment.al;
          return Cs(() {
            final scaleAlign = align.value;
            return CurvedAnimationWidget(
              builder: (context, animation) {
                final scale = Tween(
                  begin: 0.8,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation);
                final body = ScaleTransition(
                  alignment: scaleAlign,
                  scale: scale,
                  child: FadeTransition(opacity: animation, child: child),
                );

                return body;
              },
              controller: self.owner.controller,
            );
          });
        },
        builder: (context, child) {
          return GestureDetector(
            onTap: hide,
            behavior: .opaque,
            child: GestureDetector(
              onTap: () {},
              behavior: .deferToChild,
              child: child,
            ),
          );
        },
      );
    }
  }

  void hide() {
    _menu?.hide();
  }

  void show() {
    _initMenu();
    _menu?.show();
  }

  @override
  void dispose() {
    _menu?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.builder(context, this));
  }
}
