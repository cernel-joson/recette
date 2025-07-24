class Ingredient {
  final String quantity;
  final String unit;
  final String name;
  final String notes;

  Ingredient({
    required this.quantity,
    required this.unit,
    required this.name,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'unit': unit,
      'name': name,
      'notes': notes,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      quantity: json['quantity'] ?? '',
      unit: json['unit'] ?? '',
      name: json['name'] ?? 'Unknown Ingredient',
      notes: json['notes'] ?? '',
    );
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      quantity: map['quantity'],
      unit: map['unit'],
      name: map['name'],
      notes: map['notes'] ?? '',
    );
  }

  factory Ingredient.fromString(String text) {
    final parts = text.split(' ');
    if (parts.length > 2) {
      return Ingredient(
        quantity: parts[0],
        unit: parts[1],
        name: parts.sublist(2).join(' '),
      );
    } else if (parts.length == 2) {
      return Ingredient(quantity: parts[0], unit: '', name: parts[1]);
    } else {
      return Ingredient(quantity: '', unit: '', name: text);
    }
  }

  @override
  String toString() {
    final parts = [quantity, unit, name];
    String mainString = parts.where((p) => p.isNotEmpty).join(' ').trim();
    if (notes.isNotEmpty) {
      return '$mainString ($notes)';
    }
    return mainString;
  }
}