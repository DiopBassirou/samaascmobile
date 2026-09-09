class Announcement {
  final int id;
  final String title;
  final String message;
  final String type;
  final String timeAgo;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timeAgo,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    String timeAgo = 'À L\'INSTANT';
    if (json.containsKey('timeAgo')) {
      timeAgo = json['timeAgo'];
    } else if (json.containsKey('created_at')) {
      try {
        final date = DateTime.parse(json['created_at']);
        final diff = DateTime.now().difference(date);
        if (diff.inDays > 0) {
          timeAgo = 'Il y a ${diff.inDays}j';
        } else if (diff.inHours > 0) {
          timeAgo = 'Il y a ${diff.inHours}h';
        } else if (diff.inMinutes > 0) {
          timeAgo = 'Il y a ${diff.inMinutes}m';
        }
      } catch (e) {
        // ignore
      }
    }
    
    return Announcement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'ANNONCE',
      timeAgo: timeAgo,
    );
  }
}
