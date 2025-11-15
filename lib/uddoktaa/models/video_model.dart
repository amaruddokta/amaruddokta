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
      link: data['link'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
    );
  }

  get description => null;

  get views => null;

  get title => null;
}