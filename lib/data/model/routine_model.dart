class RoutineModel {
  final String id;
  final DateTime date;
  final String title;
  final String description;
  final String time;

  RoutineModel({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'time': time,
    };
  }

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      title: json['title'],
      description: json['description'],
      time: json['time'],
    );
  }
}
