import 'package:flutter/material.dart';

class ResolutionDialog extends StatefulWidget {
  const ResolutionDialog({
    Key? key,
    required this.reslutions,
    this.selectedResolution,
    this.cancelButtonText,
  }) : super(key: key);

  final Map<String, String> reslutions;
  final String? selectedResolution;
  final String? cancelButtonText;

  @override
  _ResolutionDialogState createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends State<ResolutionDialog> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: widget.reslutions.length,
            itemBuilder: (context, i) {
              final item = widget.reslutions.entries.elementAt(i);

              return ListTile(
                onTap: () => Navigator.pop(context, item.key),
                leading: widget.selectedResolution != null
                    ? widget.selectedResolution! == item.key
                        ? const Icon(Icons.done, color: Colors.white)
                        : null
                    : null,
                title: Text(
                  item.key,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              thickness: 1.0,
              color: Colors.white54,
            ),
          ),
          ListTile(
            onTap: () => Navigator.pop(context),
            leading: const Icon(Icons.close, color: Colors.white),
            title: Text(
              widget.cancelButtonText ?? 'Cancel',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
