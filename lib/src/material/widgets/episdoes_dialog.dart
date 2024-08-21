import 'package:flutter/material.dart';

class EpisodeDialog extends StatefulWidget {
  const EpisodeDialog({
    Key? key,
    required this.episodes,
    this.selectedEpisode,
    this.cancelButtonText,
  }) : super(key: key);

  final Map<String, String> episodes;
  final String? selectedEpisode;
  final String? cancelButtonText;

  @override
  _EpisodeDialogState createState() => _EpisodeDialogState();
}

class _EpisodeDialogState extends State<EpisodeDialog> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: widget.episodes.length,
            itemBuilder: (context, i) {
              final item = widget.episodes.entries.elementAt(i);

              return ListTile(
                onTap: () => Navigator.pop(context, item.key),
                leading: widget.selectedEpisode != null
                    ? widget.selectedEpisode! == item.key
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
