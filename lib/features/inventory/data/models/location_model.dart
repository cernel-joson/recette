import 'package:recette/core/data/repositories/data_repository.dart';

/// A simple model for user-defined storage locations (e.g., 'Fridge', 'Pantry').
class Location implements DataModel {
  @override
  final int? id;
  final String name;
  final String? iconName;

  Location({this.id, required this.name, this.iconName});

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'],
      name: map['name'],
      iconName: map['icon_name'],
    );
  }
}