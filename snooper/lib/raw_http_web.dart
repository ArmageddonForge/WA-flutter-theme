import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String> rawPost(String url, String body) async {
  final bodyBytes = utf8.encode(body);
  final resp = await web.window.fetch(
    url.toJS,
    web.RequestInit(
      method: 'POST',
      body: bodyBytes.toJS,
      credentials: 'same-origin',
      headers: <String, Object>{
        'content-type': 'text/plain; charset=utf-8',
        'content-length': bodyBytes.length,
      }.jsify()! as web.HeadersInit,
    ),
  ).toDart;
  if (resp.status != 200) {
    throw Exception('Server error ${resp.status}');
  }
  return (await resp.text().toDart).toDart;
}
