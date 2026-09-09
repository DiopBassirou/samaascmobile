class MatchEvent {
  final int id;
  final int matchGameId;
  final int? playerId;
  final String? playerName;
  final String type; // BUT_ASC, BUT_ADV, MI_TEMPS, CARTON
  final int minute;
  final String? description;

  MatchEvent({
    required this.id,
    required this.matchGameId,
    this.playerId,
    this.playerName,
    required this.type,
    required this.minute,
    this.description,
  });

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      id: json['id'],
      matchGameId: json['match_game_id'],
      playerId: json['player_id'],
      playerName: json['player'] != null ? json['player']['nom'] : null,
      type: json['type'],
      minute: json['minute'] ?? 0,
      description: json['description'],
    );
  }
}

class MatchGame {
  final int id;
  final String ascCode;
  final String dateMatch;
  final int? scoreAsc;
  final int? scoreAdv;
  final String statut; // A_VENIR, EN_COURS, MI_TEMPS, DEUXIEME_MI_TEMPS, TERMINE
  final String? hommeDuMatch;
  final String opponentName;
  final List<MatchEvent> events;
  final DateTime? startedAt;
  final DateTime? secondHalfStartedAt;

  MatchGame({
    required this.id,
    required this.ascCode,
    required this.dateMatch,
    this.scoreAsc,
    this.scoreAdv,
    required this.statut,
    this.hommeDuMatch,
    this.opponentName = 'ASC Jaraaf',
    this.events = const [],
    this.startedAt,
    this.secondHalfStartedAt,
  });

  factory MatchGame.fromJson(Map<String, dynamic> json) {
    var rawEvents = json['events'] as List<dynamic>? ?? [];
    List<MatchEvent> parsedEvents = rawEvents.map((e) => MatchEvent.fromJson(e)).toList();

    return MatchGame(
      id: json['id'],
      ascCode: json['asc_code'] ?? 'Notre ASC',
      dateMatch: json['date_match']?.toString() ?? '',
      scoreAsc: json['score_asc'],
      scoreAdv: json['score_adv'],
      statut: json['statut'] ?? 'A_VENIR',
      hommeDuMatch: json['homme_du_match'],
      opponentName: json['opponent'] != null ? (json['opponent']['nom_equipe'] ?? 'Adversaire') : 'ASC Jaraaf',
      events: parsedEvents,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      secondHalfStartedAt: json['second_half_started_at'] != null ? DateTime.parse(json['second_half_started_at']) : null,
    );
  }
}
