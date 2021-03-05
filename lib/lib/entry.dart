import 'package:dartz/dartz.dart';

String id(Map<String, dynamic> entry) => entry['sys']['id'];

String type(Map<String, dynamic> entry) => entry['sys']['type'];

bool isLink(Map<String, dynamic> entry) => type(entry) == 'Link';

Option<Map<String, dynamic>> fields(Map<String, dynamic> entry) =>
    optionOf<dynamic>(entry['fields'])
        .map((fields) => Map<String, dynamic>.from(fields));
