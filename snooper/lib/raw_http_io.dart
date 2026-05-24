import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

Future<String> rawPost(String url, String body) async {
  final uri = Uri.parse(url);
  final host = uri.host;
  final isHttps = uri.scheme == 'https';
  final port = uri.hasPort ? uri.port : (isHttps ? 443 : 80);
  final pathStart = url.indexOf('/', url.indexOf('://') + 3);
  final pathAndQuery = url.substring(pathStart);
  final bodyBytes = utf8.encode(body);

  final Socket socket;
  if (isHttps) {
    socket = await SecureSocket.connect(host, port);
  } else {
    socket = await Socket.connect(host, port);
  }
  try {
    socket.write('POST $pathAndQuery HTTP/1.1\r\n');
    socket.write('Host: $host\r\n');
    socket.write('Content-Length: ${bodyBytes.length}\r\n');
    socket.write('Connection: close\r\n');
    socket.write('\r\n');
    socket.add(bodyBytes);
    await socket.flush();

    final allBytes = BytesBuilder();
    await for (final chunk in socket) {
      allBytes.add(chunk);
      final soFar = utf8.decode(allBytes.toBytes(), allowMalformed: true);
      final headerEnd = soFar.indexOf('\r\n\r\n');
      if (headerEnd < 0) continue;

      final headerStr = soFar.substring(0, headerEnd);
      final clMatch = RegExp(r'Content-Length:\s*(\d+)', caseSensitive: false)
          .firstMatch(headerStr);
      if (clMatch != null) {
        final contentLength = int.parse(clMatch.group(1)!);
        final bodyStart = headerEnd + 4;
        if (allBytes.length >= bodyStart + contentLength) {
          final full = utf8.decode(allBytes.toBytes());
          final statusCode =
              int.parse(full.substring(0, full.indexOf('\r\n')).split(' ')[1]);
          final responseBody =
              full.substring(bodyStart, bodyStart + contentLength);
          if (statusCode != 200) throw Exception('Server error $statusCode');
          return responseBody;
        }
      }
    }
    throw Exception('Connection closed before response completed');
  } finally {
    socket.destroy();
  }
}
