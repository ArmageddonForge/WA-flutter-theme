import 'package:flutter/widgets.dart';
import 'package:wa/wa.dart';

import '../models.dart';
import 'flag.dart';

class PlayersTable extends StatefulWidget {
  const PlayersTable({
    super.key,
    required this.players,
    this.onNickActivated,
  });

  final List<Player> players;
  final ValueChanged<String>? onNickActivated;

  @override
  State<PlayersTable> createState() => _PlayersTableState();
}

class _PlayersTableState extends State<PlayersTable> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return WATable(
      columns: const [
        WATableColumn(width: 44, header: null),
        WATableColumn(width: 100, header: null),
        WATableColumn(flex: 1, header: 'Name'),
      ],
      rowHeight: waPx(17),
      rowCount: widget.players.length,
      selectedIndex: _selectedIndex,
      onSelected: (i) => setState(() => _selectedIndex = i),
      rowBuilder: (context, i) {
        final p = widget.players[i];
        return WATableRow(cells: [
          Flag(p.nation),
          Rank(p.rank),
          Text(p.nick),
        ]);
      },
      onActivated: widget.onNickActivated == null
          ? null
          : (i) => widget.onNickActivated!(widget.players[i].nick),
    );
  }
}
