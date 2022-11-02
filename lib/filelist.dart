
import 'package:archive/archive_io.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Archive> fetchFiles() async {

  var url =
      'https://deep-sea.ru/spool-view?docNumber=210101-819-0001&spool=006';

  List data = ['', '', '0'];
  RegExp exp = RegExp('(?<=\=)[^&]+');
  Iterable<RegExpMatch> matches = exp.allMatches(url);
  int i = 0;

  for (final m in matches) {
    data[i] = m[0];
    i++;
  }

  var getUrl =
      'https://deep-sea.ru/rest-spec/spoolFiles?docNumber=${data[0]}&spool=${data[1]}&isom=${data[2]}';

  final response = await http.get(Uri.parse(getUrl));

  if (response.statusCode == 200) {
    Archive archive = ZipDecoder().decodeBytes(response.bodyBytes);
    return archive;
  } else {
    throw Exception('failslsls');
  }
}
