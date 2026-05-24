import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'models.dart';

class ChannelState {
  ChannelState({required this.name, required this.scheme, this.canHost = false});
  final String name;
  String scheme;
  bool canHost;
  final List<Player> players = [];
  final List<Game> games = [];
  final List<ChatLine> messages = [];
}

class SnooperState extends ChangeNotifier {
  SnooperState(this._api, this._prefs);

  final SnooperApi _api;
  final SharedPreferences _prefs;

  final List<String> channels = [];
  final Map<String, ChannelState> byChannel = {};

  String? activeChannel;
  String? xsrfKey;
  Map<String, String> schemes = const {};
  String nick = '';
  String? hostResultUrl;
  String? hostError;
  bool hostLoading = false;
  String currentHostedGame = '';

  int _lastMessage = 0;
  Duration _pollInterval = const Duration(milliseconds: 1000);

  ChannelState? get activeChannelState => byChannel[activeChannel];

  void setActiveChannel(String name) {
    if (activeChannel == name) return;
    activeChannel = name;
    notifyListeners();
  }

  void setNick(String value) {
    nick = value;
    _prefs.setString('name', value);
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    if (activeChannel == null || xsrfKey == null) return;
    resetPollBackoff();
    try {
      final err = await _api.postMessage(activeChannel!, xsrfKey!, nick, message);
      if (err.isNotEmpty) {
        _addMessage(err, _sys, [activeChannel!]);
        notifyListeners();
      }
    } catch (e) {
      final ch = activeChannel;
      if (ch != null) _addMessage('Send error: $e', _sys, [ch]);
      notifyListeners();
    }
  }

  Future<void> hostGame({
    required String name,
    required String schemeId,
    required String password,
  }) async {
    if (activeChannel == null || xsrfKey == null) return;
    hostLoading = true;
    notifyListeners();
    try {
      final r = await _api.host(
        name: name,
        schemeId: schemeId,
        password: password,
        channel: activeChannel!,
        xsrf: xsrfKey!,
      );
      _ingest(r);
    } catch (e) {
      hostError = e.toString();
      hostLoading = false;
      notifyListeners();
    }
  }

  void resetHostDialog() {
    hostLoading = false;
    hostResultUrl = null;
    hostError = null;
    currentHostedGame = '';
    notifyListeners();
  }

  void resetPollBackoff() {
    _pollInterval = const Duration(milliseconds: 1000);
  }

  Future<void> init() async {
    // Only load from prefs if nick hasn't already been set (e.g. from query string).
    if (nick.isEmpty) nick = _prefs.getString('name') ?? '';
    final initial = await _api.initInfo();
    _ingest(initial);
    _pollLoop();
  }

  bool _polling = false;

  Future<void> _pollLoop() async {
    if (_polling) return;
    _polling = true;
    while (true) {
      try {
        final r = await _api.messages(_lastMessage);
        _ingest(r);
      } catch (e) {
        _addMessageToAll('Network error', const Color(0xFF808080));
        notifyListeners();
      }
      _pollInterval = _pollInterval.inMilliseconds >= 10000
          ? const Duration(milliseconds: 10000)
          : Duration(milliseconds: _pollInterval.inMilliseconds + 3);
      await Future.delayed(_pollInterval);
    }
  }

  static const _sys = Color(0xFFBF0000);
  static const _own = Color(0xFFFFFFFF);
  static const _action = Color(0xFF00CF00);
  static const _gameNew = Color(0xFF00A080);
  static const _gameGone = Color(0xFF006040);
  static const _normal = Color(0xFF808080);

  void _ingest(SnooperResponse r) {
    if (r.last != null) {
      _lastMessage = r.last!;
    }

    if (r.channels != null) {
      channels.clear();
      byChannel.clear();

      final channelNames = r.channels!.map((c) => c.name).toList();
      if (activeChannel == null || !channelNames.contains(activeChannel)) {
        activeChannel = channelNames.isNotEmpty ? channelNames.first : null;
      }

      for (final ch in r.channels!) {
        channels.add(ch.name);
        final state = ChannelState(
          name: ch.name,
          scheme: ch.scheme,
          canHost: ch.canHost,
        );
        for (final g in ch.games) {
          state.games.insert(0, g);
        }
        state.players.addAll(ch.players);
        _sortPlayers(state.players);
        byChannel[ch.name] = state;
      }
    }

    if (r.messages != null) {
      for (final msg in r.messages!) {
        _processMessage(msg);
      }
    }

    if (r.key != null) {
      xsrfKey = r.key;
    }

    if (r.schemes != null) {
      schemes = r.schemes!;
    }

    if (r.host != null) {
      if (r.host!.error != null) {
        hostError = r.host!.error;
        hostLoading = false;
      } else if (r.host!.url != null) {
        hostResultUrl = r.host!.url;
        currentHostedGame = r.host!.id ?? '';
        hostLoading = false;
      }
    }

    notifyListeners();
  }

  void _processMessage(Map<String, dynamic> msg) {
    final msgtype = int.tryParse(msg['msgtype']?.toString() ?? '') ?? -1;

    List<String> targetChannels;
    final chField = msg['channel']?.toString() ?? '';
    final chsField = msg['channels']?.toString() ?? '';
    if (chField.isNotEmpty) {
      targetChannels = [chField];
    } else if (chsField.isNotEmpty) {
      targetChannels =
          chsField.split(' ').where((s) => s.isNotEmpty).toList();
    } else {
      targetChannels = List.of(channels);
    }
    targetChannels =
        targetChannels.where((c) => byChannel.containsKey(c)).toList();

    final user = msg['user']?.toString() ?? '';
    final message = msg['message']?.toString() ?? '';
    final reason = msg['reason']?.toString() ?? '';
    final reasonPart = reason.isNotEmpty ? ' ($reason)' : '';

    switch (msgtype) {
      case 0: // system
        _addMessage('*** $message', _sys, targetChannels);

      case 1: // join
        _addMessage('** $user ** joined the channel.', _sys, targetChannels);
        for (final ch in targetChannels) {
          final state = byChannel[ch];
          if (state != null) {
            state.players.removeWhere((p) => p.nick == user);
            state.players.add(Player(nick: user, nation: 50, rank: 12));
            _sortPlayers(state.players);
          }
        }

      case 2: // part
        _addMessage(
            '** $user ** has left the channel$reasonPart.', _sys, targetChannels);
        for (final ch in targetChannels) {
          byChannel[ch]?.players.removeWhere((p) => p.nick == user);
        }

      case 3: // quit
        _addMessage(
            '** $user ** has left WormNET$reasonPart.', _sys, targetChannels);
        for (final ch in channels) {
          byChannel[ch]?.players.removeWhere((p) => p.nick == user);
        }

      case 4: // message (fall through to 5 when user == self)
        if (user != nick) {
          _addMessage('$user> $message', _normal, targetChannels);
          break;
        }
        _addMessage('$user: $message', _own, targetChannels);

      case 5: // ownMessage
        _addMessage('$user: $message', _own, targetChannels);

      case 6: // action
        _addMessage('* $user $message *', _action, targetChannels);

      case 7: // gameCreated
        final old = msg['old'];
        final isOld = old == 'true' || old == true;
        final hoster = msg['hoster']?.toString() ?? '';
        final name = msg['name']?.toString() ?? '';
        final password = msg['password']?.toString() ?? '';
        final id = msg['id']?.toString() ?? '';
        if (!isOld) {
          final passworded = password.isNotEmpty ? 'passworded ' : '';
          _addMessage(
              '>> $hoster hosted a ${passworded}game ($name).', _gameNew, targetChannels);
        }
        for (final ch in targetChannels) {
          final state = byChannel[ch];
          if (state != null) {
            state.games.removeWhere((g) => g.id == id);
            final g = Game(
              id: id,
              name: name,
              hoster: hoster,
              location:
                  int.tryParse(msg['location']?.toString() ?? '') ?? 50,
              password: password,
              ip: msg['ip']?.toString() ?? '',
              port: int.tryParse(msg['port']?.toString() ?? '') ?? 0,
            );
            state.games.insert(0, g);
          }
        }

      case 8: // gameDeleted
        final hoster = msg['hoster']?.toString() ?? '';
        final name = msg['name']?.toString() ?? '';
        _addMessage(
            "<< $hoster's game ($name) has closed.", _gameGone, targetChannels);
        final id = msg['id']?.toString() ?? '';
        for (final ch in targetChannels) {
          byChannel[ch]?.games.removeWhere((g) => g.id == id);
        }

      case 9: // userInfo
        final msgName = msg['name']?.toString() ?? '';
        final nation =
            int.tryParse(msg['nation']?.toString() ?? '') ?? 50;
        final rank = int.tryParse(msg['rank']?.toString() ?? '') ?? 12;
        final info = msg['info']?.toString() ?? '';
        for (final ch in channels) {
          final state = byChannel[ch];
          if (state != null) {
            final idx = state.players.indexWhere((p) => p.nick == msgName);
            if (idx != -1) {
              state.players[idx].nation = nation;
              state.players[idx].rank = rank;
              state.players[idx].info = info;
              _sortPlayers(state.players);
            }
          }
        }

      case 10: // reset
        // ignore: discarded_futures
        init();

      case 11: // channelJoined
        final chName = msg['channel']?.toString() ?? '';
        _addMessage('*** Joined #$chName', _sys, targetChannels);

      case 12: // snoopGameHosted
        final id = msg['id']?.toString() ?? '';
        if (id.isNotEmpty && id == currentHostedGame) {
          hostLoading = false;
        }

      default:
        _addMessage('Unknown message type: $msgtype', _sys, targetChannels);
    }
  }

  void _sortPlayers(List<Player> players) {
    players.sort((a, b) {
      if (a.isSnooper != b.isSnooper) return a.isSnooper ? 1 : -1;
      return a.nick.toLowerCase().compareTo(b.nick.toLowerCase());
    });
  }

  void _addMessage(String text, Color tone, List<String> targetChannels) {
    for (final ch in targetChannels) {
      byChannel[ch]?.messages.add(ChatLine(text, tone));
    }
  }

  void _addMessageToAll(String text, Color tone) {
    for (final ch in channels) {
      byChannel[ch]?.messages.add(ChatLine(text, tone));
    }
  }
}
