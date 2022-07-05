extension StringCapitalize on String {
  String capitalize() => this.isEmpty // ignore: unnecessary_this
      ? this
      : this.length > 1 // ignore: unnecessary_this
          ? this[0].toUpperCase() + this.substring(1) // ignore: unnecessary_this
          : this[0].toUpperCase();
}

class ApiError {
  ApiError.fromEntry(MapEntry<String, dynamic> e)
      : key = e.key,
        messages = List<String>.from(e.value as List<dynamic>);

  ApiError.fromString(String e)
      : key = '',
        messages = [e];

  final String key;
  final List<String> messages;

  @override
  String toString() => [key.capitalize(), ' ', messages.join(' and ')].join();
}

class ApiErrors {
  ApiErrors._fromMap(Map<String, Object> m) : _all = m.entries.map((e) => ApiError.fromEntry(e)).toList();

  ApiErrors._fromList(List<String> l) : _all = l.map((e) => ApiError.fromString(e)).toList();

  factory ApiErrors.fromResponse(Object data) => data.runtimeType.toString().contains('List')
      ? ApiErrors._fromList(List<String>.from(data as List<dynamic>))
      : ApiErrors._fromMap(Map<String, Object>.from(data as Map<dynamic, dynamic>));

  final List<ApiError> _all;

  @override
  String toString() => _all.map((e) => e.toString()).join("\n");
}
