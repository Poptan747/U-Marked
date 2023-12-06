class Subject {
  final String name;
  final String subjectID;

  Subject({
    required this.name,
    required this.subjectID,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      subjectID: map['subjectID'] ?? '',
      name: map['name'] ?? '',
    );
  }
}