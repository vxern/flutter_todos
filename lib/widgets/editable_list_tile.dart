import 'package:flutter/material.dart';

typedef VoidCallbackWithValue = void Function(String contents);

class EditableListTile extends StatelessWidget {
  final IconData icon;

  final String _initialContents;

  final VoidCallback onRemove;

  final VoidCallbackWithValue onContentsChanged;
  final VoidCallbackWithValue onContentsSubmitted;

  final VoidCallback? onTap;

  const EditableListTile({
    super.key,
    required this.icon,
    required String initialContents,
    required this.onRemove,
    required this.onContentsChanged,
    required this.onContentsSubmitted,
    this.onTap,
  }) : _initialContents = initialContents;

  @override
  Widget build(BuildContext context) => ListTile(
        trailing: GestureDetector(
          onTap: onRemove,
          child: Icon(icon, color: Theme.of(context).listTileTheme.iconColor),
        ),
        title: TextField(
          controller: TextEditingController(text: _initialContents),
          decoration: const InputDecoration(border: InputBorder.none),
          onChanged: onContentsChanged,
          onSubmitted: onContentsSubmitted,
          style: Theme.of(context).textTheme.labelLarge,
          enabled: false,
        ),
        tileColor: Theme.of(context).listTileTheme.tileColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
      );
}
