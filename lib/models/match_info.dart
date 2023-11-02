import 'package:cloud_firestore/cloud_firestore.dart';

class MatchInfo {
  String? whiteUID, blackUID;
  List<String> whiteCaptured, blackCaptured;
  int whitePoint, blackPoint;
  List<String?> san;
  int matchState;
  int winner; // -1 black, 0 draw, 1 white, 101 in game
  String requestDrawUID;
  String fen;
  bool resign;

  MatchInfo({
    this.whiteUID,
    this.blackUID,
    required this.whiteCaptured,
    required this.blackCaptured,
    required this.whitePoint,
    required this.blackPoint,
    required this.san,
    required this.matchState,
    required this.winner,
    required this.requestDrawUID,
    required this.fen,
    required this.resign,
  });

  Map<String, dynamic> toJson() {
    return {
      'whiteUID': this.whiteUID,
      'blackUID': this.blackUID,
      'whiteCaptured': this.whiteCaptured,
      'blackCaptured': this.blackCaptured,
      'whitePoint': this.whitePoint,
      'blackPoint': this.blackPoint,
      'san': this.san,
      'matchState': this.matchState,
      'winner': this.winner,
      'requestDrawUID': this.requestDrawUID,
      'fen': this.fen,
      'resign': this.resign,
    };
  }

  factory MatchInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MatchInfo(
      whiteUID: data['whiteUID'] as String,
      blackUID: data['blackUID'] as String,
      whiteCaptured: (data['whiteCaptured'] as List<dynamic>).cast<String>(),
      blackCaptured: (data['blackCaptured'] as List<dynamic>).cast<String>(),
      whitePoint: data['whitePoint'] as int,
      blackPoint: data['blackPoint'] as int,
      san: (data['san'] as List<dynamic>).cast<String>(),
      matchState: data['matchState'] as int,
      winner: data['winner'] as int,
      requestDrawUID: data['requestDrawUID'] as String,
      fen: data['fen'] as String,
      resign: data['resign'] as bool,
    );
  }
}