import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/match_model.dart';

class MatchTimer extends StatefulWidget {
  final MatchGame match;

  const MatchTimer({Key? key, required this.match}) : super(key: key);

  @override
  State<MatchTimer> createState() => _MatchTimerState();
}

class _MatchTimerState extends State<MatchTimer> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isAdditionalTime = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant MatchTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.statut != widget.match.statut || 
        oldWidget.match.startedAt != widget.match.startedAt || 
        oldWidget.match.secondHalfStartedAt != widget.match.secondHalfStartedAt) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _calculateTime();

    if (widget.match.statut == 'EN_COURS' || widget.match.statut == 'DEUXIEME_MI_TEMPS') {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _calculateTime();
      });
    }
  }

  void _calculateTime() {
    final now = DateTime.now();
    int seconds = 0;

    if (widget.match.statut == 'EN_COURS' && widget.match.startedAt != null) {
      seconds = now.difference(widget.match.startedAt!).inSeconds;
    } else if (widget.match.statut == 'MI_TEMPS') {
      seconds = 40 * 60; // 40 minutes at half time
    } else if (widget.match.statut == 'DEUXIEME_MI_TEMPS' && widget.match.secondHalfStartedAt != null) {
      seconds = (40 * 60) + now.difference(widget.match.secondHalfStartedAt!).inSeconds;
    } else if (widget.match.statut == 'TERMINE') {
      // Just show 80:00 or stop
      seconds = 80 * 60;
    }

    if (mounted) {
      setState(() {
        _elapsedSeconds = seconds;
        
        if (widget.match.statut == 'EN_COURS' && seconds > (40 * 60)) {
          _isAdditionalTime = true;
        } else if (widget.match.statut == 'DEUXIEME_MI_TEMPS' && seconds > (80 * 60)) {
           _isAdditionalTime = true;
        } else {
          _isAdditionalTime = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int displayMinutes = _elapsedSeconds ~/ 60;
    int displaySeconds = _elapsedSeconds % 60;
    
    String timeString;
    
    if (_isAdditionalTime) {
        int baseTime = widget.match.statut == 'EN_COURS' ? 40 : 80;
        int additionalMinutes = displayMinutes - baseTime;
        timeString = "$baseTime + $additionalMinutes";
    } else {
        timeString = "${displayMinutes.toString().padLeft(2, '0')}:${displaySeconds.toString().padLeft(2, '0')}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.match.statut == 'MI_TEMPS' || widget.match.statut == 'TERMINE' ? Colors.grey : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.match.statut == 'MI_TEMPS' ? 'MI-TEMPS' : 
        widget.match.statut == 'TERMINE' ? 'FIN' : timeString,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
