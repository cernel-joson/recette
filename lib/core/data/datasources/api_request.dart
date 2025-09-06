abstract class ApiRequest {
  String get endpoint => 'test';
  
  Map<String, dynamic> toJson() => {'key': 'value'};
}