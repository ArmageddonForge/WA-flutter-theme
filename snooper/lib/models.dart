import 'dart:ui';

const List<String> countryNames = [
  'United Kingdom', 'Argentina', 'Australia', 'Austria', 'Belgium', 'Brazil',
  'Canada', 'Croatia', 'Bosnia', 'Cyprus', 'Czech Republic', 'Denmark',
  'Finland', 'France', 'Georgia', 'Germany', 'Greece', 'Hong Kong', 'Hungary',
  'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel',
  'Italy', 'Japan', 'Leichtenstein', 'Luxembourg', 'Malaysia', 'Malta',
  'Mexico', 'Morocco', 'Netherlands', 'New Zealand', 'Norway', 'Poland',
  'Portugal', 'Puerto Rico', 'Romania', 'Russia', 'Singapore', 'South Africa',
  'Spain', 'Sweden', 'Switzerland', 'Turkey', 'United States', 'Unknown',
  'RedFlag1', 'RedFlag2', 'RedFlag3', 'Chile', 'Serbia', 'Slovenia', 'Lebanon',
  'Moldova', 'Ukraine', 'Latvia', 'Slovakia', 'Costa Rica', 'Estonia', 'China',
  'Colombia', 'Ecuador', 'Uruguay', 'Venezuela', 'Lithuania', 'Bulgaria',
  'Egypt', 'Saudi Arabia', 'South Korea', 'Belarus', 'Peru', 'Algeria',
  'Kazakhstan', 'El Salvador', 'Taiwan', 'Jamaica', 'Guatemala',
  'Marshall Islands', 'Macedonia', 'United Arab Emirates',
];

class Player {
  Player({required this.nick, this.info = '', this.nation = 50, this.rank = 12});
  String nick;
  String info;
  int nation;
  int rank;
  bool get isSnooper => rank == 13;
}

class Game {
  Game({
    required this.id,
    required this.name,
    required this.hoster,
    required this.location,
    required this.password,
    required this.ip,
    required this.port,
  });
  final String id;
  final String name;
  final String hoster;
  final int location;
  final String password;
  final String ip;
  final int port;
  bool get hasPassword => password.isNotEmpty;
}

class ChatLine {
  ChatLine(this.text, this.tone);
  final String text;
  final Color tone;
}

class ChannelInit {
  ChannelInit({
    required this.name,
    required this.scheme,
    required this.canHost,
    required this.games,
    required this.players,
  });
  final String name;
  final String scheme;
  final bool canHost;
  final List<Game> games;
  final List<Player> players;

  factory ChannelInit.fromJson(Map<String, dynamic> json) {
    int clampNation(dynamic v) {
      final n = int.tryParse(v.toString()) ?? 50;
      return (n < 1 || n > countryNames.length) ? 50 : n;
    }

    int clampRank(dynamic v) {
      final r = int.tryParse(v.toString()) ?? 12;
      return (r < 0 || r > 13) ? 12 : r;
    }

    final rawGames = json['games'];
    final games = <Game>[];
    if (rawGames is List) {
      for (final g in rawGames) {
        if (g is Map<String, dynamic>) {
          games.add(Game(
            id: g['id']?.toString() ?? '',
            name: g['name']?.toString() ?? '',
            hoster: g['hoster']?.toString() ?? '',
            location: clampNation(g['location'] ?? 50),
            password: g['password']?.toString() ?? '',
            ip: g['ip']?.toString() ?? '',
            port: int.tryParse((g['port'] ?? 0).toString()) ?? 0,
          ));
        }
      }
    }

    final rawPlayers = json['players'];
    final players = <Player>[];
    if (rawPlayers is List) {
      for (final p in rawPlayers) {
        if (p is Map<String, dynamic>) {
          players.add(Player(
            nick: p['nick']?.toString() ?? '',
            info: p['info']?.toString() ?? '',
            nation: clampNation(p['nation'] ?? 50),
            rank: clampRank(p['rank'] ?? 12),
          ));
        }
      }
    }

    return ChannelInit(
      name: json['name']?.toString() ?? '',
      scheme: json['scheme']?.toString() ?? '',
      canHost: json['canHost'] == true || json['canHost'] == 'true',
      games: games,
      players: players,
    );
  }
}

class HostResult {
  HostResult({this.error, this.url, this.id});
  final String? error;
  final String? url;
  final String? id;

  factory HostResult.fromJson(Map<String, dynamic> json) {
    return HostResult(
      error: json['error']?.toString(),
      url: json['url']?.toString(),
      id: json['id']?.toString(),
    );
  }
}

class SnooperResponse {
  SnooperResponse({
    this.channels,
    this.messages,
    this.key,
    this.schemes,
    this.last,
    this.host,
  });
  final List<ChannelInit>? channels;
  final List<Map<String, dynamic>>? messages;
  final String? key;
  final Map<String, String>? schemes;
  final int? last;
  final HostResult? host;

  factory SnooperResponse.fromJson(Map<String, dynamic> json) {
    List<ChannelInit>? channels;
    final rawChannels = json['channels'];
    if (rawChannels is List) {
      channels = rawChannels
          .whereType<Map<String, dynamic>>()
          .map(ChannelInit.fromJson)
          .toList();
    }

    List<Map<String, dynamic>>? messages;
    final rawMessages = json['messages'];
    if (rawMessages is List) {
      messages = rawMessages.whereType<Map<String, dynamic>>().toList();
    }

    Map<String, String>? schemes;
    final rawSchemes = json['schemes'];
    if (rawSchemes is Map) {
      schemes = rawSchemes.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }

    HostResult? host;
    final rawHost = json['host'];
    if (rawHost is Map<String, dynamic>) {
      host = HostResult.fromJson(rawHost);
    }

    return SnooperResponse(
      channels: channels,
      messages: messages,
      key: json['key']?.toString(),
      schemes: schemes,
      last: int.tryParse((json['last'] ?? '').toString()),
      host: host,
    );
  }
}
