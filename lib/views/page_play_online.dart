import 'package:audioplayers/audioplayers.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_vua/controllers/login_provider.dart';
import 'package:co_vua/models/match_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:provider/provider.dart';

import '../controllers/match_info_provider.dart';
import '../helpers/common.dart';
import '../helpers/dialogs.dart';
import '../models/user_info.dart';

class ProviderPagePlayOnline extends StatelessWidget {
  const ProviderPagePlayOnline({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MatchInfoProvider(),
      child: MaterialApp(
        title: "Cờ Vua",
        debugShowCheckedModeBanner: false,
        home: PagePlayOnline(),
      ),
    );
  }
}

class PagePlayOnline extends StatefulWidget {
  const PagePlayOnline({Key? key}) : super(key: key);

  @override
  State<PagePlayOnline> createState() => _PagePlayOnlineState();
}

class _PagePlayOnlineState extends State<PagePlayOnline> {

  ChessBoardController chessBoardController = ChessBoardController();
  final _scrollController = ScrollController();
  List<BoardArrow> _arrows = [];
  late int _eloWin, _eloDraw, _eloLost;
  late String _oppoUID, _oppoName, _oppoImg;
  late String _playerUID, _playerName, _playerImg;
  late int _playerElo, _oppoElo;

  late bool canMove;
  late Color playerColor, opponentColor;
  bool buttonClickable = true;
  bool isLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: getColor(MyColor.AppBarColor),
          centerTitle: true,
          title: Text("Cờ vua",
            style: TextStyle(color: Colors.white),),
        ),
        body: isLoaded ?
        Consumer<MatchInfoProvider>(
          builder: (context, match, child) {
            if (match.matchInfo.matchState == -3) { // Opponent agree draw
              // Check this is actually opponent agree draw
              if (match.matchInfo.requestDrawUID == _playerUID) { // Our request has been accepted
                Future.delayed(Duration(seconds: 1), () { // Wait a little bit to build Consumer
                  _onOpponentAgreeDraw();
                },);
              }
            }
            else if (match.matchInfo.matchState == -2) { // Opponent resign
              // Check this is actually opponent resign
              if (playerColor == Color.WHITE) {
                if (match.matchInfo.winner == 1) {
                  Future.delayed(Duration(seconds: 1), () { // Wait a little bit to build Consumer
                    _onOpponentResign();
                  },);
                }
              }
              else {
                if (match.matchInfo.winner == -1)
                  Future.delayed(Duration(seconds: 1), () {
                    _onOpponentResign();
                  },);
              }
            }
            else if (match.matchInfo.matchState == -1) { // Opponent moved but didn't update yet
              String? lastString = match.matchInfo.san.last;
              if (lastString != null) {
                // Make move for opponent
                String lastMove = lastString.split(" ").last;
                chessBoardController.makeMoveWithNormalNotation(lastMove);
              }
              match.matchInfo.matchState = 0;
              updateUI();
              Future.delayed(Duration(seconds: 1), () {
                _checkEndGame();
              },);
            }
            return Column(
              children: [
                Container(
                    color: getColor(MyColor.BodyColor),
                    child: Column(
                      children: [
                        SizedBox(height: 5,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text("Thắng +$_eloWin", style: TextStyle(color: Colors.white),),
                            Text("Hòa ${_eloDraw >= 0 ? '+' : ''}$_eloDraw", style: TextStyle(color: Colors.white)),
                            Text("Thua $_eloLost", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ],
                    )
                ),
                Expanded(
                  child: Container(
                    color: getColor(MyColor.BodyColor),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 30,
                          child: ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: match.matchInfo.san.length,
                            itemBuilder: (context, index) {
                              String? move = match.matchInfo.san[index];
                              if (move == null) return SizedBox.shrink();
                              return Container(
                                padding: EdgeInsets.all(8),
                                child: Text(move, style: TextStyle(color: Colors.white70),),
                              );
                            },
                          ),
                        ),
                        ListTile(
                          leading: Container(
                            height: 35,
                            child: Image.network(_oppoImg),
                          ),
                          title: Text("$_oppoName ($_oppoElo)",
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          subtitle: Row(
                            children: [
                              Expanded(
                                  child: _displayCapturedPieces(opponentColor,
                                      opponentColor == Color.WHITE ? match.matchInfo.whiteCaptured : match.matchInfo.blackCaptured)
                              ),
                              Text(match.getPoint(opponentColor), style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        ChessBoard(
                          controller: chessBoardController,
                          boardColor: BoardColor.brown,
                          boardOrientation: playerColor == Color.WHITE ? PlayerColor.white
                              : PlayerColor.black,
                          enableUserMoves: canMove,
                          onMove: () {
                            match.matchInfo.requestDrawUID = "";
                            updateUI();
                            updateMatchInfo();
                          },
                          arrows: _arrows,
                        ),
                        match.matchInfo.requestDrawUID == _oppoUID ?
                        Container(
                          color: getColor(MyColor.BodyColor),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.cancel_sharp, color: Colors.white70,),
                                onPressed: buttonClickable ? () => _onCancelDrawButtonClicked() : null,
                              ),
                              Expanded(
                                child: Center(
                                  child: Text('Hòa cờ?',
                                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.check_circle_sharp, color: Colors.white70,),
                                onPressed: buttonClickable ? () => _onCheckDrawButtonClicked() : null,
                              ),
                            ],
                          ),
                        )
                            : ListTile(
                          leading: Container(
                            height: 35,
                            child: Image.network(_playerImg),
                          ),
                          title: Text("$_playerName ($_playerElo)",
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          subtitle: Row(
                            children: [
                              Expanded(
                                  child: _displayCapturedPieces(playerColor,
                                      playerColor == Color.WHITE ? match.matchInfo.whiteCaptured : match.matchInfo.blackCaptured)
                              ),
                              Text(match.getPoint(playerColor), style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: getColor(MyColor.AppBarColor),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InkWell(
                        onTap: buttonClickable ? () => _onResignButtonClicked() : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag, color: Colors.white ),
                            Text("Đầu hàng",
                              style: TextStyle(color: Colors.white),)
                          ],
                        ),
                        splashColor: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      InkWell(
                        onTap: buttonClickable ? () => _onDrawButtonClicked() : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.handshake, color: Colors.white ),
                            Text("Hòa cờ",
                              style: TextStyle(color: Colors.white),)
                          ],
                        ),
                        splashColor: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        )
            : Center(child: CircularProgressIndicator()),
      );
  }

  @override
  void initState() {
    super.initState();
    _initMatch();
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (buttonClickable) { // Ingame
      _onResignButtonClicked();
      return true;
    }
    return false;
  }

  void _initMatch() async {
    GoogleLoginProvider g = context.read<GoogleLoginProvider>();
    MatchInfoProvider m = context.read<MatchInfoProvider>();

    g.user?.currentMatchID = UserInf.fromFirestore(await
      FirebaseFirestore.instance.collection('UserInfo')
          .doc(g.user?.uid).get()).currentMatchID;

    DocumentReference matchDocRef = FirebaseFirestore.instance
        .collection('MatchInfo').doc(g.user?.currentMatchID);
    m.setMatchDocRef(matchDocRef);
    DocumentSnapshot matchDocSnap = await matchDocRef.get();
    m.setMatchInfo(MatchInfo.fromFirestore(matchDocSnap));

    if (m.matchInfo.whiteUID == g.user?.uid) { // Current user is WHITE
      playerColor = Color.WHITE;
      opponentColor = Color.BLACK;
      _oppoUID = m.matchInfo.blackUID!;
    }
    else { // Current user is BLACK
      playerColor = Color.BLACK;
      opponentColor = Color.WHITE;
      _oppoUID = m.matchInfo.whiteUID!;
    }

    canMove = (playerColor == chessBoardController.game.turn);
    m.listenToMatchInfo();

    _playerUID = g.user!.uid!;
    _playerName = g.user!.name!;
    _playerElo = g.user!.elo!;
    _playerImg = g.user!.avatar!;

    UserInf opponent = UserInf.fromFirestore(await FirebaseFirestore.instance
        .collection('UserInfo').doc(_oppoUID)
        .get());
    _oppoName = opponent.name!;
    _oppoElo = opponent.elo!;
    _oppoImg = opponent.avatar!;

    _eloWin = _getEloPoint(1);
    _eloDraw = _getEloPoint(0.5);
    _eloLost = _getEloPoint(0);

    isLoaded = true;
    setState(() { });

    _playSoundStart();
  }

  void _playSoundStart() {
    AudioCache player = AudioCache(prefix: 'assets/sounds/');
    player.play('game_start.mp3');
  }

  Widget _displayCapturedPieces(Color turn, List<String> capturedPieces) {
    Map<String, Image> imageMap;
    if (turn == Color.WHITE) {
      imageMap = {
        'p': Image.asset('assets/images/pawn_black.png'),
        'n': Image.asset('assets/images/knight_black.png'),
        'b': Image.asset('assets/images/bishop_black.png'),
        'r': Image.asset('assets/images/rook_black.png'),
        'q': Image.asset('assets/images/queen_black.png'),
      };
    }
    else {
      imageMap = {
        'p': Image.asset('assets/images/pawn_white.png'),
        'n': Image.asset('assets/images/knight_white.png'),
        'b': Image.asset('assets/images/bishop_white.png'),
        'r': Image.asset('assets/images/rook_white.png'),
        'q': Image.asset('assets/images/queen_white.png'),
      };
    }

    return Container(
      height: 15,
      child: Row(
        children: [
          for (int i = 0; i < capturedPieces.length; i++)
            imageMap[capturedPieces[i]]!
        ],
      ),
    );
  }

  void playSound() {
    AudioCache player = AudioCache(prefix: 'assets/sounds/');
    if (chessBoardController.isGameOver()) {
      if (chessBoardController.isDraw()) {
        player.play("gameover_stalemate.mp3");
      }
      else {
        player.play("gameover_checkmate.mp3");
      }
    }
    else {
      if (chessBoardController.isInCheck()) {
        player.play("check.mp3");
      }
      else if (chessBoardController.game.history.last.move.flags == 32 ||
          chessBoardController.game.history.last.move.flags == 64) {
        player.play("castling.mp3");
      }
      else if (chessBoardController.game.history.last.move.captured != null) {
        player.play("captured.mp3");
      }
      else {
        player.play("move.mp3");
      }
    }
  }

  void displayArrow() {
    int from = chessBoardController.game.history.last.move.from;
    int to = chessBoardController.game.history.last.move.to;
    if (_arrows.isNotEmpty) {
      _arrows = [];
    }
    _arrows.add(
        BoardArrow(
          from: findSquare(from),
          to: findSquare(to),
        )
    );
  }

  String findSquare(int num) {
    dynamic square = "";
    Chess.SQUARES.forEach((key, value) {
      if (value == num) {
        square = key;
      }
    });
    return square as String;
  }

  void updateMatchInfo() {
    MatchInfoProvider matchInfoProvider = context.read<MatchInfoProvider>();
    GoogleLoginProvider g = context.read<GoogleLoginProvider>();

    matchInfoProvider.updateSAN(chessBoardController.getSan());
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.easeOut,
    );

    matchInfoProvider.checkCaptured(
        chessBoardController.game.history.last.turn,
        chessBoardController.game.history.last.move.captured?.name
    );

    if (chessBoardController.isGameOver()) {
      setState(() {
        canMove = false;
        buttonClickable = false;
      });
      if (chessBoardController.isDraw()) {
        // Update player's elo
        g.user!.elo = g.user!.elo! + _eloDraw;
        g.user?.currentMatchID = null;
        FirebaseFirestore.instance
            .collection('UserInfo').doc(g.user?.uid)
            .update({
          'elo': g.user?.elo,
          'currentMatchID': null,
        });

        // Update match info
        matchInfoProvider.onEndGame(context, playerColor == Color.WHITE ? _playerName : _oppoName,
            playerColor == Color.WHITE ? _oppoName : _playerName,
            0,
            'network', playerColor == Color.WHITE ? _playerImg : _oppoImg,
            playerColor == Color.WHITE ? _oppoImg : _playerImg, g.user!.elo!, _eloDraw);
      }
      else {
        // Because this function is only called when user moved, so if not draw, it is win
        // Update player's elo
        g.user!.elo = g.user!.elo! + _eloWin;
        g.user?.currentMatchID = null;
        FirebaseFirestore.instance
            .collection('UserInfo').doc(g.user?.uid)
            .update({
          'elo': g.user?.elo,
          'currentMatchID': null,
        });

        // Update match info
        matchInfoProvider.onEndGame(context, playerColor == Color.WHITE ? _playerName : _oppoName,
            playerColor == Color.WHITE ? _oppoName : _playerName,
            playerColor == Color.WHITE ? 1 : -1,
            'network', playerColor == Color.WHITE ? _playerImg : _oppoImg,
            playerColor == Color.WHITE ? _oppoImg : _playerImg, g.user!.elo!, _eloWin);
      }
    }

    matchInfoProvider.matchInfo.fen = chessBoardController.getFen();

    _updateMatchOnFirebase();
  }

  void _updateMatchOnFirebase() {
    MatchInfoProvider m = context.read<MatchInfoProvider>();
    m.updateMatchInfo();
  }

  void updateUI() {
    canMove = (playerColor == chessBoardController.game.turn);
    displayArrow();
    playSound();
  }

  int _getEloPoint(double score)  {
    return calculateElo(_playerElo, _oppoElo, score) - _playerElo;
  }

  void _onResignButtonClicked() async {
    String? confirm = await showConfirmDialog(context, "Chấp nhận thua");
    if (confirm == "ok") {
      AudioCache player = AudioCache(prefix: 'assets/sounds/');
      player.play("gameover.mp3");
      setState(() {
        canMove = false;
        buttonClickable = false;
      });

      MatchInfoProvider matchInfoProvider = context.read<MatchInfoProvider>();
      GoogleLoginProvider g = context.read<GoogleLoginProvider>();

      // Update player's elo
      g.user!.elo = g.user!.elo! + _eloLost;
      g.user?.currentMatchID = null;
      FirebaseFirestore.instance
          .collection('UserInfo').doc(g.user?.uid)
          .update({
        'elo': g.user?.elo,
        'currentMatchID': null,
      });

      // Update match info
      matchInfoProvider.matchInfo.resign = true;
      matchInfoProvider.onEndGame(context, playerColor == Color.WHITE ? _playerName : _oppoName,
          playerColor == Color.WHITE ? _oppoName : _playerName,
          playerColor == Color.WHITE ? -1 : 1,
          'network', playerColor == Color.WHITE ? _playerImg : _oppoImg,
          playerColor == Color.WHITE ? _oppoImg : _playerImg, g.user!.elo!, _eloLost);

      _updateMatchOnFirebase();
    }
  }

  void _onDrawButtonClicked() {
    MatchInfoProvider matchInfoProvider = context.read<MatchInfoProvider>();
    if (matchInfoProvider.matchInfo.requestDrawUID != "") return;
    matchInfoProvider.matchInfo.requestDrawUID = _playerUID;
    _updateMatchOnFirebase();
  }

  void _onCancelDrawButtonClicked() {
    MatchInfoProvider matchInfoProvider = context.read<MatchInfoProvider>();
    matchInfoProvider.matchInfo.requestDrawUID = "";
    _updateMatchOnFirebase();
  }

  void _onCheckDrawButtonClicked() {
    AudioCache player = AudioCache(prefix: 'assets/sounds/');
    player.play("gameover_stalemate.mp3");
    setState(() {
      canMove = false;
      buttonClickable = false;
    });

    MatchInfoProvider matchInfoProvider = context.read<MatchInfoProvider>();
    GoogleLoginProvider g = context.read<GoogleLoginProvider>();

    // Update player's elo
    g.user!.elo = g.user!.elo! + _eloDraw;
    g.user?.currentMatchID = null;
    FirebaseFirestore.instance
        .collection('UserInfo').doc(g.user?.uid)
        .update({
      'elo': g.user?.elo,
      'currentMatchID': null,
    });

    // Update match info
    matchInfoProvider.onEndGame(context, playerColor == Color.WHITE ? _playerName : _oppoName,
        playerColor == Color.WHITE ? _oppoName : _playerName,
        0,
        'network', playerColor == Color.WHITE ? _playerImg : _oppoImg,
        playerColor == Color.WHITE ? _oppoImg : _playerImg, g.user!.elo!, _eloDraw);

    _updateMatchOnFirebase();
  }

  void _checkEndGame() {
    MatchInfoProvider matchInfoProvider = context.read<MatchInfoProvider>();
    GoogleLoginProvider g = context.read<GoogleLoginProvider>();

    if (chessBoardController.isGameOver()) {
      setState(() {
        canMove = false;
        buttonClickable = false;
      });
      if (chessBoardController.isDraw()) {
        // Update player's elo
        g.user!.elo = g.user!.elo! + _eloDraw;
        g.user?.currentMatchID = null;
        FirebaseFirestore.instance
            .collection('UserInfo').doc(g.user?.uid)
            .update({
          'elo': g.user?.elo,
          'currentMatchID': null,
        });

        // Update match info
        matchInfoProvider.onEndGame(context, playerColor == Color.WHITE ? _playerName : _oppoName,
            playerColor == Color.WHITE ? _oppoName : _playerName,
            0,
            'network', playerColor == Color.WHITE ? _playerImg : _oppoImg,
            playerColor == Color.WHITE ? _oppoImg : _playerImg, g.user!.elo!, _eloDraw);
      }
      else {
        // Because this function is only called when opponent moved, so if not draw, it is lost
        // Update player's elo
        g.user!.elo = g.user!.elo! + _eloLost;
        g.user?.currentMatchID = null;
        FirebaseFirestore.instance
            .collection('UserInfo').doc(g.user?.uid)
            .update({
          'elo': g.user?.elo,
          'currentMatchID': null,
        });

        // Update match info
        matchInfoProvider.onEndGame(context, playerColor == Color.WHITE ? _playerName : _oppoName,
            playerColor == Color.WHITE ? _oppoName : _playerName,
            playerColor == Color.WHITE ? -1 : 1,
            'network', playerColor == Color.WHITE ? _playerImg : _oppoImg,
            playerColor == Color.WHITE ? _oppoImg : _playerImg, g.user!.elo!, _eloLost);
      }
    }
  }

  void _onOpponentResign() {
    AudioCache player = AudioCache(prefix: 'assets/sounds/');
    player.play("gameover.mp3");
    setState(() {
      canMove = false;
      buttonClickable = false;
    });

    GoogleLoginProvider g = context.read<GoogleLoginProvider>();
    MatchInfoProvider m = context.read<MatchInfoProvider>();

    // Update player's elo
    g.user!.elo = g.user!.elo! + _eloWin;
    g.user?.currentMatchID = null;
    FirebaseFirestore.instance
        .collection('UserInfo').doc(g.user?.uid)
        .update({
      'elo': g.user?.elo,
      'currentMatchID': null,
    });

    // Update match info
    m.onEndGame(context, playerColor == Color.WHITE ? _playerName : _oppoName,
        playerColor == Color.WHITE ? _oppoName : _playerName,
        playerColor == Color.WHITE ? 1 : -1,
        'network', playerColor == Color.WHITE ? _playerImg : _oppoImg,
        playerColor == Color.WHITE ? _oppoImg : _playerImg, g.user!.elo!, _eloWin);
  }

  void _onOpponentAgreeDraw() {
    AudioCache player = AudioCache(prefix: 'assets/sounds/');
    player.play("gameover_stalemate.mp3");
    setState(() {
      canMove = false;
      buttonClickable = false;
    });

    MatchInfoProvider matchInfoProvider = context.read<MatchInfoProvider>();
    GoogleLoginProvider g = context.read<GoogleLoginProvider>();

    // Update player's elo
    g.user!.elo = g.user!.elo! + _eloDraw;
    g.user?.currentMatchID = null;
    FirebaseFirestore.instance
        .collection('UserInfo').doc(g.user?.uid)
        .update({
      'elo': g.user?.elo,
      'currentMatchID': null,
    });

    // Update match info
    matchInfoProvider.onEndGame(context, playerColor == Color.WHITE ? _playerName : _oppoName,
        playerColor == Color.WHITE ? _oppoName : _playerName,
        0,
        'network', playerColor == Color.WHITE ? _playerImg : _oppoImg,
        playerColor == Color.WHITE ? _oppoImg : _playerImg, g.user!.elo!, _eloDraw);
  }
}
