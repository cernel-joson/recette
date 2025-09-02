import 'package:recette/core/data/models/list_item_model.dart';

class Location implements ListCategory {
  @override
  final int? id;
  @override
  final String name;
  final String? iconName;

  Location({this.id, required this.name, this.iconName});

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'icon_name': iconName};
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(id: map['id'], name: map['name'], iconName: map['icon_name']);
  }
}
