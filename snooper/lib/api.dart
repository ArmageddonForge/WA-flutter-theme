import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'raw_http.dart' as raw;

class SnooperApi {
  SnooperApi(this._client, this._origin);
  final http.Client _client;
  final Uri _origin;

  Future<SnooperResponse> initInfo() async {
    final r = await _client.get(_origin.resolve('/data/initinfo?'));
    _expect200(r);
    return SnooperResponse.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<SnooperResponse> messages(int lastMessage) async {
    final r = await _client.get(_origin.resolve('/data/messages?$lastMessage'));
    _expect200(r);
    return SnooperResponse.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<String> postMessage(
      String channel, String xsrf, String name, String message) async {
    final base = _origin.resolve('/data/message').toString();
    return raw.rawPost('$base?$channel|$xsrf', '$name|$message');
  }

  Future<SnooperResponse> host({
    required String name,
    required String schemeId,
    required String password,
    required String channel,
    required String xsrf,
  }) async {
    final req =
        http.MultipartRequest('POST', _origin.resolve('/data/host'));
    req.fields['name'] = name;
    req.fields['scheme'] = schemeId;
    req.fields['password'] = password;
    req.fields['channel'] = channel;
    req.fields['xsrf'] = xsrf;
    final streamed = await _client.send(req);
    final r = await http.Response.fromStream(streamed);
    _expect200(r);
    return SnooperResponse.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  void _expect200(http.Response r) {
    if (r.statusCode != 200) {
      throw Exception('Server error ${r.statusCode} ("${r.reasonPhrase}")');
    }
  }
}
