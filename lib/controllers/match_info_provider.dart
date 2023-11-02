import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_vua/helpers/dialogs.dart';
import 'package:co_vua/models/match_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:chess/chess.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

class MatchInfoProvider extends ChangeNotifier {
  MatchInfo? _matchInfo;
  DocumentReference? _documentReference;

  MatchInfo get matchInfo => _matchInfo!;
  DocumentReference get documentReference => _documentReference!;

  void setMatchInfo(MatchInfo matchInfo) {
    _matchInfo = matchInfo;
  }

  void setMatchDocRef(DocumentReference documentReference) {
    _documentReference = documentReference;
  }

  void checkCaptured(Color turn, String? pieceName) {
    List<String> sortOrder = ['p', 'n', 'b', 'r', 'q'];
    Map<String, int> pointMap = {
      'p': 1,
      'n': 3,
      'b': 3,
      'r': 5,
      'q': 9,
    };

    if (pieceName == null) return;
    if (turn == Color.WHITE) {
      matchInfo.whiteCaptured.add(pieceName);
      matchInfo.whiteCaptured.sort((a, b) =>
          sortOrder.indexOf(a).compareTo(sortOrder.indexOf(b)));
      matchInfo.whitePoint += pointMap[pieceName]!;
    }
    else {
      matchInfo.blackCaptured.add(pieceName);
      matchInfo.blackCaptured.sort((a, b) =>
          sortOrder.indexOf(a).compareTo(sortOrder.indexOf(b)));
      matchInfo.blackPoint += pointMap[pieceName]!;
    }

    notifyListeners();
  }

  String getPoint(Color turn) {
    if (turn == Color.WHITE) {
      int point = matchInfo.whitePoint - matchInfo.blackPoint;
      if (point <= 0) return "";
      else return "+$point";
    }
    else {
      int point = matchInfo.blackPoint - matchInfo.whitePoint;
      if (point <= 0) return "";
      else return "+$point";
    }
  }

  void updateSAN(List<String?> san) {
    matchInfo.san = san;
    notifyListeners();
  }

  void onEndGame(BuildContext context, String whiteName, String blackName, int winner, String displayImgType,
      String whiteImg, String blackImg, int elo, int eloGain) {
    matchInfo.matchState = 1;
    matchInfo.winner = winner;
    if (winner == 0) {
      showDialogEndGame(context, whiteName, blackName, "", displayImgType, whiteImg, blackImg, elo, eloGain);
    }
    else {
      if (winner == 1) {
        showDialogEndGame(context, whiteName, blackName, "white", displayImgType, whiteImg, blackImg, elo, eloGain);
      }
      else {
        showDialogEndGame(context, whiteName, blackName, "black", displayImgType, whiteImg, blackImg, elo, eloGain);
      }
    }
    notifyListeners();
  }

  static Future<DocumentReference> addMatchOnFirebase(MatchInfo matchInfo) async {
    return FirebaseFirestore.instance.collection("MatchInfo").add(matchInfo.toJson());
  }

  Future<void> updateMatchInfo() async {
    return _documentReference!.update(_matchInfo!.toJson());
  }

  void listenToMatchInfo() {
    _documentReference!.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        MatchInfo newMatchInfo = MatchInfo.fromFirestore(snapshot);
        if (_matchInfo?.fen != newMatchInfo.fen) { // Opponent move
          _matchInfo = newMatchInfo;
          _matchInfo!.matchState = -1;
          notifyListeners();
        }
        else if (newMatchInfo.matchState == 1
          && newMatchInfo.resign == true) { // Opponent resign
          _matchInfo = newMatchInfo;
          _matchInfo!.matchState = -2;
          notifyListeners();
        }
        else if (newMatchInfo.matchState == 1
            && newMatchInfo.requestDrawUID != "") { // Opponent agree draw
          _matchInfo = newMatchInfo;
          _matchInfo!.matchState = -3;
          notifyListeners();
        }
        else {
          _matchInfo = newMatchInfo;
          notifyListeners();
        }
      }
    });
  }
}