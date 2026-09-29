import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'team_logo.dart';

class MatchPoll extends StatefulWidget {
  final int matchId;
  final String teamAName;
  final String teamBName;
  final String? teamALogo;
  final String? teamBLogo;
  final int initialVotesA;
  final int initialVotesB;

  const MatchPoll({
    super.key,
    required this.matchId,
    required this.teamAName,
    required this.teamBName,
    this.teamALogo,
    this.teamBLogo,
    this.initialVotesA = 0,
    this.initialVotesB = 0,
  });

  @override
  State<MatchPoll> createState() => _MatchPollState();
}

class _MatchPollState extends State<MatchPoll> {
  bool _hasVoted = false;
  int _votesA = 0;
  int _votesB = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _votesA = widget.initialVotesA;
    _votesB = widget.initialVotesB;
    _checkIfVoted();
  }

  Future<void> _checkIfVoted() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasVoted = prefs.getBool('voted_match_${widget.matchId}') ?? false;
      });
    }
  }

  Future<void> _vote(bool isTeamA) async {
    if (_hasVoted || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.sunugalsolutiongroup.com/api';
      final response = await http.post(
        Uri.parse('$baseUrl/matches/${widget.matchId}/vote'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'team': isTeamA ? 'home' : 'away'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('voted_match_${widget.matchId}', true);

        if (mounted) {
          setState(() {
            _hasVoted = true;
            _votesA = data['votes_home'] ?? _votesA;
            _votesB = data['votes_away'] ?? _votesB;
          });
        }
      }
    } catch (e) {
      // Ignorer l'erreur et procéder localement en cas de problème de réseau
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voted_match_${widget.matchId}', true);
      if (mounted) {
        setState(() {
          _hasVoted = true;
          if (isTeamA) _votesA++; else _votesB++;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _votesA + _votesB;
    final percentA = total > 0 ? (_votesA / total) : 0.5;
    final percentB = total > 0 ? (_votesB / total) : 0.5;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🔥 SONDAGE DU MATCH 🔥', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Qui va gagner cette rencontre ?', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          
          if (!_hasVoted)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _vote(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0A5C36),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.teamALogo != null) ...[
                          TeamLogo(teamName: widget.teamAName, logoUrl: widget.teamALogo, size: 24, fallbackColor: Colors.greenAccent),
                          const SizedBox(width: 6),
                        ],
                        Flexible(child: Text(widget.teamAName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _vote(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0A5C36),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.teamBLogo != null) ...[
                          TeamLogo(teamName: widget.teamBName, logoUrl: widget.teamBLogo, size: 24, fallbackColor: Colors.green),
                          const SizedBox(width: 6),
                        ],
                        Flexible(child: Text(widget.teamBName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(percentA * 100).round()}% ${widget.teamAName}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('${widget.teamBName} ${(percentB * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentA,
                    backgroundColor: Colors.blueAccent,
                    color: Colors.orangeAccent,
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 6),
                    Text('Vote pris en compte ! ($total votes)', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
