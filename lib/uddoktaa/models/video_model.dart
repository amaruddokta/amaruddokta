class Video {
  final String id;
  final String link;
  final DateTime timestamp;

  Video({
    required this.id,
    required this.link,
    required this.timestamp,
  });

  factory Video.fromFirestore(Map<String, dynamic> data, String id) {
    return Video(
      id: id,
      link: data['adminurlvideos'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
    );
  }

  factory Video.fromMap(Map<String, dynamic> data) {
    return Video(
      id: data['id'],
      link: data['adminurlvideos'] ?? '',
      timestamp: DateTime.parse(data['timestamp']),
    );
  }

  get description => null;

  get views => null;

  get title => null;
}
