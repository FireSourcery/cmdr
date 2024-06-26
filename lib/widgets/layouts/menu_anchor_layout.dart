import 'package:flutter/material.dart';

/// Layouts
class MenuAnchorButton extends StatelessWidget {
  const MenuAnchorButton({required this.items, this.icon = const Icon(Icons.more_horiz), super.key});

  final List<Widget> items; //MenuItemButton
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    Widget builder(BuildContext context, MenuController controller, Widget? child) {
      return IconButton(onPressed: () => (controller.isOpen) ? controller.close() : controller.open(), icon: icon);
    }

    return MenuAnchor(
      menuChildren: items,
      builder: builder,
      crossAxisUnconstrained: true,
      consumeOutsideTap: true,
    );
  }
}

class MenuAnchorOverlay extends StatelessWidget {
  const MenuAnchorOverlay({required this.items, required this.child, this.onOpen, this.onClose, this.menuController, super.key});

  final List<Widget> items; //MenuItemButton
  final Widget child;
  final MenuController? menuController;

  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final MenuController controller = menuController ?? MenuController();

    void onSecondaryTapDown(TapDownDetails details) => controller.open(position: details.localPosition);
    void onLongPress() => controller.open();

    return GestureDetector(
      onSecondaryTapDown: onSecondaryTapDown,
      onLongPress: onLongPress,
      child: MenuAnchor(
        menuChildren: items,
        controller: controller,
        crossAxisUnconstrained: true,
        consumeOutsideTap: true,
        // child: InkWell(onTap: () {}, child: child),
        child: child,
      ),
    );
  }
}
