class Player {
  final int id;
  final String ascCode;
  final String nom;
  final String poste;
  final bool isActive;
  String? statutConvocation; // TITULAIRE, REMPLACANT, REPOS

  Player({
    required this.id,
    required this.ascCode,
    required this.nom,
    required this.poste,
    required this.isActive,
    this.statutConvocation,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      ascCode: json['asc_code'],
      nom: json['nom'],
      poste: json['poste'],
      isActive: json['is_active'] == 1,
      statutConvocation: json['statut_convocation'],
    );
  }
}
