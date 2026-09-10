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
  final String statut; // A_VENIR, EN_COURS, MI_TEMPS, TERMINE
  final String? hommeDuMatch;
  final String teamAName;
  final String? teamALogo;
  final String teamBName;
  final String? teamBLogo;
  final List<MatchEvent> events;
  final DateTime? startedAt;
  final DateTime? secondHalfStartedAt;

  // Nouveaux champs (Catégorie, Lieu, Phase, Poule)
  final String categorie;  // CADET ou SENIOR
  final String? lieu;      // Terrain / Stade
  final String? phase;     // Phase de Groupes, 1/4 Finale...
  final String? pouleName; // Nom de la poule (ex: Poule A)

  MatchGame({
    required this.id,
    required this.ascCode,
    required this.dateMatch,
    this.scoreAsc,
    this.scoreAdv,
    required this.statut,
    this.hommeDuMatch,
    this.teamAName = 'Equipe A',
    this.teamALogo,
    this.teamBName = 'Equipe B',
    this.teamBLogo,
    this.events = const [],
    this.startedAt,
    this.secondHalfStartedAt,
    this.categorie = 'SENIOR',
    this.lieu,
    this.phase,
    this.pouleName,
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
      teamAName: json['team_a_name'] ?? 'Equipe A',
      teamALogo: json['team_a_logo'],
      teamBName: json['team_b_name'] ?? 'Equipe B',
      teamBLogo: json['team_b_logo'],
      events: parsedEvents,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      secondHalfStartedAt: json['second_half_started_at'] != null
          ? DateTime.parse(json['second_half_started_at'])
          : null,
      categorie: json['categorie'] ?? 'SENIOR',
      lieu: json['lieu'],
      phase: json['phase'],
      pouleName: json['opponent']?['poule']?['nom'] ?? json['phase'],
    );
  }

  /// Retourne true si le match est aujourd'hui
  bool get isToday {
    final dt = DateTime.tryParse(dateMatch);
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Retourne true si le match était hier
  bool get isYesterday {
    final dt = DateTime.tryParse(dateMatch);
    if (dt == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
  }

  /// Retourne true si le match est demain
  bool get isTomorrow {
    final dt = DateTime.tryParse(dateMatch);
    if (dt == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;
  }
}
