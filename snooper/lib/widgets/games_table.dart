import 'package:flutter/widgets.dart';
import 'package:wa/wa.dart';

import '../models.dart';
import 'flag.dart';

class GamesTable extends StatefulWidget {
  const GamesTable({
    super.key,
    required this.games,
    this.onGameActivated,
  });

  final List<Game> games;
  final ValueChanged<Game>? onGameActivated;

  @override
  State<GamesTable> createState() => _GamesTableState();
}

class _GamesTableState extends State<GamesTable> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return WATable(
      columns: [
        const WATableColumn(width: 36, header: null),
        const WATableColumn(width: 44, header: null),
        const WATableColumn(flex: 1, header: 'Game'),
        WATableColumn(width: waPx(75), header: 'Host'),
      ],
      rowHeight: waPx(17),
      rowCount: widget.games.length,
      selectedIndex: _selectedIndex,
      onSelected: (i) => setState(() => _selectedIndex = i),
      rowBuilder: (context, i) {
        final g = widget.games[i];
        return WATableRow(
          color: g.hasPassword ? WAColors.yellow : null,
          cells: [
            Padlock(locked: g.hasPassword),
            Flag(g.location),
            Text(g.name),
            Text(g.hoster),
          ],
        );
      },
      onActivated: widget.onGameActivated == null
          ? null
          : (i) => widget.onGameActivated!(widget.games[i]),
    );
  }
}
