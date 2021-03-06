import 'package:test/test.dart';
import 'package:collection/collection.dart';
import 'package:contentful/includes.dart';

void main() {
  Function deepEq = const DeepCollectionEquality().equals;

  group('Includes', () {
    final Map<String, Map<String, dynamic>> linkedEntry = {
      "sys": {
        "type": "Entry",
        "id": "A",
      },
      "fields": {
        "title": "title",
      },
    };

    final Map<String, Map<String, dynamic>> linkedEntry2 = {
      "sys": {
        "type": "Entry",
        "id": "B",
      },
      "fields": {
        "title": "title2",
      },
    };

    final Map<String, Map<String, dynamic>> linkedEntryWithLinks = {
      "sys": {
        "type": "Entry",
        "id": "C",
      },
      "fields": {
        "title": "title",
        "child": {
          "sys": {
            "type": "Link",
            "linkType": "Entry",
            "id": "B",
          }
        },
        "children": [
          {
            "sys": {
              "type": "Link",
              "linkType": "Entry",
              "id": "A",
            }
          },
          {
            "sys": {
              "type": "Link",
              "linkType": "Entry",
              "id": "B",
            }
          },
        ]
      },
    };

    final includes = Includes.fromJson({
      "Entry": [
        linkedEntry,
        linkedEntry2,
        linkedEntryWithLinks,
      ],
    });

    test('links should be resolved', () {
      final linkingList = [
        {
          "sys": {
            "type": "Entry",
            "id": "B",
          },
          "fields": {
            "links": [
              {
                "sys": {"type": "Link", "linkType": "Entry", "id": "A"}
              },
            ],
            "nestedLinks": {
              "sys": {"type": "Link", "linkType": "Entry", "id": "C"}
            },
          },
        }
      ];

      final expectedList = [
        {
          "sys": {
            "type": "Entry",
            "id": "B",
          },
          "fields": {
            "links": [
              linkedEntry,
            ],
            "nestedLinks": {
              "sys": {
                "type": "Entry",
                "id": "C",
              },
              "fields": {
                "title": "title",
                "child": linkedEntry2,
                "children": [linkedEntry, linkedEntry2],
              },
            }
          },
        }
      ];

      final resolvedList = includes.resolveLinks(linkingList);

      expect(deepEq(resolvedList, expectedList), true);
    });

    test('list of strings should be preserved', () {
      final linkingList = [
        {
          "sys": {
            "type": "Entry",
            "id": "B",
          },
          "fields": {
            "stringlist": ["str1", "str2"],
          },
        }
      ];

      final expectedList = [
        {
          "sys": {
            "type": "Entry",
            "id": "B",
          },
          "fields": {
            "stringlist": ["str1", "str2"],
          },
        }
      ];

      final resolvedList = includes.resolveLinks(linkingList);

      expect(deepEq(resolvedList, expectedList), true);
    });
  });
}
