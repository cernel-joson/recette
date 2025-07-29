/// A new class to represent a labeled duration.
class TimingInfo {
  final String label;
  final String duration;

  TimingInfo({required this.label, required this.duration});

  Map<String, dynamic> toMap() {
    return {'label': label, 'duration': duration};
  }

  factory TimingInfo.fromMap(Map<String, dynamic> map) {
    return TimingInfo(
      label: map['label'] ?? '',
      duration: map['duration'] ?? '',
    );
  }

  @override
  String toString() {
    return '$label: $duration';
  }
}