import 'package:material_ui/material_ui.dart';
import 'package:overlays/src/navigation/overlay_observer.dart';

import 'nav_overlay_getter.dart';
import 'nav_overlay_mixin.dart';
import 'overlay_panel.dart';
import 'overlay_side_panel.dart';

typedef SnackbarDelegate = OverlayMixinDelegate;
typedef BannerDelegate = OverlayMixinDelegate;
typedef ToastDelegate = OverlayMixinDelegate;
typedef MenuDelegate = OverlayMixinDelegate;

final _snackBarToken = Object();
final _bannelToken = Object();
final _toastToken = Object();

extension OverlayExt on OverlaysObserver {
  SnackbarDelegate snackBar(
    Widget content, {
    Duration duration = const Duration(seconds: 3),
    Duration animationDuration = const Duration(milliseconds: 300),
    Duration delayDuration = Duration.zero,
    Color? color,
    Object? key,
    bool autoShow = true,
  }) => showOverlay(
    content,
    showKey: key ?? _snackBarToken,
    duration: duration,
    animationDuration: animationDuration,
    delayDuration: delayDuration,
    color: color,
    autoShow: autoShow,
    position: NopOverlayPosition.bottom,
  );

  BannerDelegate banner(
    Widget content, {
    Duration duration = const Duration(seconds: 3),
    Duration animationDuration = const Duration(milliseconds: 300),
    Duration delayDuration = Duration.zero,
    Color? color,
    bool autoShow = true,
    Object? key,
    BorderRadius? radius = const BorderRadius.all(Radius.circular(8)),
  }) {
    return showOverlay(
      content,
      top: 0,
      right: 8,
      left: 8,
      margin: const EdgeInsets.only(top: 8),
      showKey: key ?? _bannelToken,
      duration: duration,
      animationDuration: animationDuration,
      delayDuration: delayDuration,
      radius: radius,
      color: color,
      autoShow: autoShow,
      position: NopOverlayPosition.top,
    );
  }

  ToastDelegate toast(
    Widget content, {
    Duration duration = const Duration(seconds: 3),
    Duration animationDuration = const Duration(milliseconds: 300),
    BorderRadius? radius = const BorderRadius.all(Radius.circular(8)),
    Color? color,
    double bottomPadding = 80.0,
    EdgeInsets? padding,
    Object? key,
    bool autoShow = true,
  }) {
    return showOverlay(
      Container(padding: padding, child: content),
      duration: duration,
      showKey: key ?? _toastToken,
      radius: radius,
      color: color,
      top: null,
      autoShow: autoShow,
      bottom: bottomPadding,
      onTap: (owner) {
        owner.hide();
      },
      transition: (child, self) {
        final owner = self.owner;
        return AnimatedBuilder(
          animation: owner.ignore,
          builder: (context, child) {
            return IgnorePointer(ignoring: owner.ignore.value, child: child);
          },
          child: Center(
            child: IntrinsicWidth(
              child: FadeTransition(
                opacity: owner.controller,
                child: RepaintBoundary(child: child),
              ),
            ),
          ),
        );
      },
    );
  }

  MenuDelegate menu(
    Widget content, {

    required Rect anchorGlobal,
    Duration animationDuration = const Duration(milliseconds: 300),
    Color? color,
    BorderRadius? radius,
    bool removeAll = false,
    EdgeInsets? margin,
    NopOverlayPosition position = NopOverlayPosition.none,
    Object? showKey,
    bool autoShow = true,
    required Widget Function(BuildContext context, Widget child)? builder,
    Widget Function(
      Widget child,
      UserGestureController<OverlayPanelBuilder> controller,
      ValueNotifier<Alignment> alignment,
    )?
    transition,
  }) {
    final valueNotifier = ValueNotifier(Alignment.center);

    final controller = OverlayPanelBuilder(
      showKey: showKey,
      stay: null,
      builder: (context, self) {
        final key = GlobalKey();

        Widget Function(Widget child)? localTransition;
        if (transition != null) {
          localTransition = (Widget child) {
            return transition(child, self, valueNotifier);
          };
        } else {
          localTransition = _transition(self, position);
        }

        final padding = MediaQuery.paddingOf(context);

        Widget child = OverlayWidget(
          content: content,
          sizeKey: key,
          color: color,
          radius: radius,
          margin: margin,
          removeAll: removeAll,
          position: .none,
        );

        if (localTransition case var transition?) {
          child = transition(child);
        }

        child = CustomSingleChildLayout(
          delegate: _MenuLayoutDelegate(
            anchorRect: anchorGlobal,
            bottomMargin: padding.bottom,
            valueNotifier: valueNotifier,
          ),
          child: child,
        );

        if (builder case var builder?) {
          child = builder(context, child);
        }
        return child;
      },
    );

    final overlay = OverlayMixinDelegate(
      controller,
      animationDuration,
      delayDuration: .zero,
    );
    if (autoShow) overlay.show();
    return overlay;
  }

  Future<T?> showDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor = Colors.black54,
    String? barrierLabel,
    bool useSafeArea = true,
    RouteSettings? routeSettings,
    CapturedThemes? themes,
  }) {
    final route = RawDialogRoute<T>(
      pageBuilder:
          (
            BuildContext buildContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            final Widget pageChild = Builder(builder: builder);
            Widget dialog = themes?.wrap(pageChild) ?? pageChild;
            if (useSafeArea) {
              dialog = SafeArea(child: dialog);
            }
            return dialog;
          },
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: _buildMaterialDialogTransitions,
      settings: routeSettings,
    );
    return push(route);
  }
}

Widget _buildMaterialDialogTransitions(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  );
}

extension Context on BuildContext {
  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }
}

Tween<Offset>? _getOffsetFrom(NopOverlayPosition position) {
  Tween<Offset>? offset;
  switch (position) {
    case NopOverlayPosition.top:
      offset = Tween(
        begin: const Offset(0.0, -1.0),
        end: const Offset(0.0, 0.0),
      );
      break;
    case NopOverlayPosition.left:
      offset = Tween(
        begin: const Offset(-1.0, 0.0),
        end: const Offset(0.0, 0.0),
      );
      break;
    case NopOverlayPosition.bottom:
      offset = Tween(
        begin: const Offset(0.0, 1.0),
        end: const Offset(0.0, 0.0),
      );
      break;
    case NopOverlayPosition.right:
      offset = Tween(
        begin: const Offset(1.0, 0.0),
        end: const Offset(0.0, 0.0),
      );
      break;
    default:
  }
  return offset;
}

OverlayMixinDelegate showOverlay(
  Widget content, {
  Duration? duration = const Duration(seconds: 3),
  Duration animationDuration = const Duration(milliseconds: 300),
  Duration delayDuration = Duration.zero,
  Color? color,
  BorderRadius? radius,
  bool removeAll = false,
  double? left = 0,
  double? right = 0,
  double? top = 0,
  double? bottom = 0,
  EdgeInsets? margin,
  NopOverlayPosition position = NopOverlayPosition.none,
  Object? showKey,
  bool autoShow = true,
  void Function(OverlayMixin owner)? onTap,
  Widget Function(BuildContext context, Widget child)? builder,
  Widget Function(
    Widget child,
    UserGestureController<OverlayPanelBuilder> controller,
  )?
  transition,
}) {
  final offset = _getOffsetFrom(position);

  final controller = OverlayPanelBuilder(
    showKey: showKey,
    stay: duration,
    builder: (context, self) {
      final key = GlobalKey();

      Widget Function(Widget child)? localTransition;
      if (transition != null) {
        localTransition = (Widget child) {
          return transition(child, self);
        };
      } else if (offset != null) {
        localTransition = (Widget child) {
          return AnimatedBuilder(
            animation: self.userGesture,
            builder: (context, _) {
              if (self.userGesture.value) {
                final position = self.owner.controller.drive(offset);

                return SlideTransition(position: position, child: child);
              }

              return CurvedAnimationWidget(
                builder: (context, animation) {
                  final position = animation.drive(offset);
                  return SlideTransition(position: position, child: child);
                },
                controller: self.owner.controller,
              );
            },
          );
        };
      }

      VoidCallback? onTapCallback;
      if (onTap != null) {
        onTapCallback = () {
          onTap(self.owner);
        };
      }
      return OverlaySideGesture(
        sizeKey: key,
        entry: self,
        top: position == NopOverlayPosition.bottom ? null : top,
        left: position == NopOverlayPosition.right ? null : left,
        right: position == NopOverlayPosition.left ? null : right,
        bottom: position == NopOverlayPosition.top ? null : bottom,
        transition: localTransition,
        onTap: onTapCallback,
        builder: (context) {
          Widget child = OverlayWidget(
            content: content,
            sizeKey: key,
            color: color,
            radius: radius,
            margin: margin,
            removeAll: removeAll,
            position: position,
          );
          if (builder != null) {
            child = builder(context, child);
          }
          return child;
        },
      );
    },
  );

  final overlay = OverlayMixinDelegate(
    controller,
    animationDuration,
    delayDuration: delayDuration,
  );
  if (autoShow) overlay.show();
  return overlay;
}

Widget Function(Widget child)? _transition(
  UserGestureController<OverlayPanelBuilder> self,
  NopOverlayPosition position,
) {
  final transitionOffset = _getOffsetFrom(position);
  if (transitionOffset == null) return null;

  return (Widget child) {
    return AnimatedBuilder(
      animation: self.userGesture,
      builder: (context, _) {
        if (self.userGesture.value) {
          final position = self.owner.controller.drive(transitionOffset);

          return SlideTransition(position: position, child: child);
        }

        return CurvedAnimationWidget(
          builder: (context, animation) {
            final position = animation.drive(transitionOffset);
            return SlideTransition(position: position, child: child);
          },
          controller: self.owner.controller,
        );
      },
    );
  };
}

class _MenuLayoutDelegate extends SingleChildLayoutDelegate {
  _MenuLayoutDelegate({
    required this.anchorRect,
    required this.bottomMargin,
    required this.valueNotifier,
  });

  final Rect anchorRect;
  final double bottomMargin;

  final ValueNotifier<Alignment> valueNotifier;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final leftExtent = anchorRect.left;
    final rightExtent = constraints.maxWidth - anchorRect.right;
    final extent = leftExtent > rightExtent ? leftExtent : rightExtent;

    return BoxConstraints.loose(
      .new(extent, constraints.maxHeight - bottomMargin),
    );
  }

  void updateValue(Offset offset, Size size) {
    final rect = offset & size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final x = rect.left < anchorRect.left ? 1.0 : -1.0;
      final center = anchorRect.center.dy;
      final extent = rect.height;
      if (extent == 0) {
        return;
      }
      final yp = center.clamp(rect.top, rect.bottom);
      final p = (yp - rect.top) / extent;
      valueNotifier.value = Alignment(x, p.clamp(0.0, 1.0) * 2 - 1);
    });
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final contentSize = childSize;
    final dyEnd = size.height - bottomMargin;
    final dxEnd = size.width;

    var dx = anchorRect.right;
    var dy = anchorRect.bottom;

    if (dx + contentSize.width > dxEnd) {
      dx = anchorRect.left - contentSize.width;
    }

    if (dy + contentSize.height > dyEnd) {
      dy = dyEnd - childSize.height;
    }

    final Offset offset = .new(dx, dy);
    updateValue(offset, contentSize);
    return offset;
  }

  @override
  bool shouldRelayout(covariant SingleChildLayoutDelegate oldDelegate) {
    return false;
  }
}
