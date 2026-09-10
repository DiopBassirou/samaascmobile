import 'dart:convert';
import 'dart:io';
import 'lib/models/match_model.dart';

void main() {
  final file = File('../sama_asc_api/matches.json');
  final String jsonString = file.readAsStringSync();
  final List<dynamic> data = json.decode(jsonString);
  try {
    final matches = data.map((json) => MatchGame.fromJson(json)).toList();
    print('Parsed ${matches.length} matches successfully!');
    
    final currentMatches = matches.where((m) => m.statut == 'EN_COURS' || m.statut == 'MI_TEMPS').toList();
    final nextMatches = matches.where((m) => m.statut == 'A_VENIR').toList();
    final lastMatches = matches.where((m) => m.statut == 'TERMINE').toList();
    
    print('Current: ${currentMatches.length}, Next: ${nextMatches.length}, Last: ${lastMatches.length}');
  } catch (e, stack) {
    print('Error parsing matches: $e');
    print(stack);
  }
}
