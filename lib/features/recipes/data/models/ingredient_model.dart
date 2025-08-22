class Ingredient {
  // quantity is now a String to hold text like "a splash" or "2-3".
  final String quantity;
  // quantityNumeric is an optional double for scaling and calculations.
  final double? quantityNumeric;
  final String unit;
  final String name;
  final String notes;

  Ingredient({
    required this.quantity,
    this.quantityNumeric, // Now optional
    required this.unit,
    required this.name,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'quantityNumeric': quantityNumeric,
      'unit': unit,
      'name': name,
      'notes': notes,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      // The AI now provides 'quantity_display'.
      quantity: json['quantity_display'] ?? '',
      // The AI now provides 'quantity_numeric', which can be null.
      // We handle both int and double from JSON safely.
      quantityNumeric: (json['quantity_numeric'] as num?)?.toDouble(),
      unit: json['unit'] ?? '',
      name: json['name'] ?? 'Unknown Ingredient',
      notes: json['notes'] ?? '',
    );
  }

  // --- THIS IS THE FIX ---
  // Make the fromMap constructor defensive against null values.
  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      quantity: map['quantity'] ?? '', // Provide default value
      quantityNumeric: map['quantityNumeric'],
      unit: map['unit'] ?? '', // Provide default value
      name: map['name'] ?? 'Unknown Ingredient', // Provide default value
      notes: map['notes'] ?? '',
    );
  }
  // --- END OF FIX ---

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