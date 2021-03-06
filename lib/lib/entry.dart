import 'package:dartz/dartz.dart';
import 'package:contentful/lib/conversion.dart' as convert;

Option<String> id(Map<String, dynamic> entry) => optionOf(entry['sys']?['id']);

Option<String> type(Map<String, dynamic> entry) =>
    optionOf(entry['sys']?['type']);

bool isLink(Map<String, dynamic> entry) => type(entry) == some('Link');

Option<Map<String, dynamic>> fields(Map<String, dynamic> entry) =>
    optionOf(entry['fields']).map(convert.map);
