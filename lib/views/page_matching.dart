import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_vua/controllers/match_info_provider.dart';
import 'package:co_vua/models/match_info.dart';
import 'package:co_vua/views/page_play_online.dart';
import 'package:co_vua/views/page_two_players.dart';
import 'package:flutter/material.dart';
import 'package:co_vua/helpers/common.dart';
import 'package:provider/provider.dart';
import '../controllers/login_provider.dart';
import '../models/user_info.dart';
class PageMatching extends StatefulWidget {
  @override
  State<PageMatching> createState() => _PageMatchingState();
}

class _PageMatchingState extends State<PageMatching> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cờ vua"),
        centerTitle: true,
        backgroundColor: getColor(MyColor.AppBarColor),
      ),
      backgroundColor: getColor(MyColor.BodyColor),
      body: Stack(
        children: [
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text('Đang tìm trận', style: TextStyle(color: Colors.white,
                  fontSize: 30)),
            ),
          ),
          // Show a blurred background image
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Image.asset(
              'assets/images/chess_board.png',
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.contain,
            ),
          ),
          // Show a white box with text inside
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white.withOpacity(0.7),
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: 0,
            left: 0,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _cancelMatching(),
              icon: Icon(Icons.close),
              label: Text('Hủy'),
              style: ElevatedButton.styleFrom(
                primary: Colors.grey.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _listenToMatchingPlayers();
  }

  void _cancelMatching() {
    // Update user: is matching
    GoogleLoginProvider g = context.read<GoogleLoginProvider>();
    FirebaseFirestore.instance.collection('UserInfo').doc(g.user?.uid)
        .update({ 'isMatching': false });
    g.user?.isMatching = false;

    Navigator.pop(context);
  }

  void _listenToMatchingPlayers() {
    Stream<QuerySnapshot> streamUserMatching = FirebaseFirestore.instance
        .collection('UserInfo')
        .where('isMatching', isEqualTo: true)
        .snapshots();
    streamUserMatching.listen((snapshot) {
      List<UserInf> matchingPlayers = [];
      snapshot.docs.forEach((playerDoc) {
        UserInf player = UserInf.fromFirestore(playerDoc);
        matchingPlayers.add(player);
      });

      List<UserInf>? pairPlayers;

      for (int i = 0; i < matchingPlayers.length; i++) {
        UserInf player1 = matchingPlayers[i];

        for (int j = i + 1; j < matchingPlayers.length; j++) {
          UserInf player2 = matchingPlayers[j];

          if ((player1.elo! - player2.elo!).abs() <= 300) {
            pairPlayers = [player1, player2];
          }
        }
      }

      if (pairPlayers == null) return;

      _pairPlayersSuccess(pairPlayers[0], pairPlayers[1]);
    });
  }

  void _pairPlayersSuccess(UserInf player1, UserInf player2) async {
    GoogleLoginProvider g = context.read<GoogleLoginProvider>();

    if (g.user?.uid != player1.uid && g.user?.uid != player2.uid) return;

    // Cancel Matching
    FirebaseFirestore.instance.collection('UserInfo').doc(player1.uid)
        .update({ 'isMatching': false });
    FirebaseFirestore.instance.collection('UserInfo').doc(player2.uid)
        .update({ 'isMatching': false });
    g.user?.isMatching = false;

    if (g.user?.uid == player1.uid) {
      var randomRole = Random().nextInt(2);

      String? wUID, bUID;
      if (randomRole == 0) {
        wUID = player1.uid;
        bUID = player2.uid;
      }
      else {
        wUID = player2.uid;
        bUID = player1.uid;
      }

      // Create match
      MatchInfo match = MatchInfo(whiteUID: wUID, blackUID: bUID,
          whiteCaptured: [], blackCaptured: [], san: [], winner: 101, fen: "",
          whitePoint: 0, blackPoint: 0, matchState: 0, requestDrawUID: "", resign: false);
      DocumentReference matchDocRef = await MatchInfoProvider.addMatchOnFirebase(match);

      // Add players into match
      FirebaseFirestore.instance.collection('UserInfo').doc(player1.uid)
        .update({ 'currentMatchID': matchDocRef.id });
      FirebaseFirestore.instance.collection('UserInfo').doc(player2.uid)
          .update({ 'currentMatchID': matchDocRef.id });

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (BuildContext context) => ProviderPagePlayOnline()),
      );
    }
    else {
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (BuildContext context) => ProviderPagePlayOnline()),
        );
      },);
    }
  }
}