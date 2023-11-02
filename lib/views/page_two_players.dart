import 'package:audioplayers/audioplayers.dart';
import 'package:co_vua/controllers/match_info_provider.dart';
import 'package:co_vua/helpers/common.dart';
import 'package:co_vua/helpers/dialogs.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/match_info.dart';

class ProviderPageTwoPlayers extends StatelessWidget {
  const ProviderPageTwoPlayers({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MatchInfoProvider(),
      child: MaterialApp(
        title: "Cờ Vua",
        debugShowCheckedModeBanner: false,
        home: PageTwoPlayers(),
      ),
    );
  }
}


class PageTwoPlayers extends StatefulWidget {
  const PageTwoPlayers({Key? key}) : super(key: key);

  @override
  State<PageTwoPlayers> createState() => _PageTwoPlayersState();
}

class _PageTwoPlayersState extends State<PageTwoPlayers> {

  ChessBoardController chessBoardController = ChessBoardController();
  final _scrollController = ScrollController();
  List<BoardArrow> _arrows = [];

  bool canMove = true;
  bool buttonClickable = true;

  @override
  void initState() {
    super.initState();

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
          isOnline = true;
        } else {
          isOnline = false;
        }
      });
    });

    MatchInfoProvider matchInfoProvider = context.read<MatchInfoProvider>();
    matchInfoProvider.setMatchInfo(
        MatchInfo(whiteCaptured: [], blackCaptured: [], whitePoint: 0, blackPoint: 0,
          san: [], matchState: 0, requestDrawUID: "", winner: 101, fen: "", resign: false)
    );
    _playSoundStart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: getColor(MyColor.AppBarColor),
        centerTitle: true,
        title: Text("2 người 1 máy",
          style: TextStyle(color: Colors.white),),
      ),
      body: Consumer<MatchInfoProvider>(
        builder: (context, match, child) => Column(
          children: [
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
                        child: Image.asset('assets/images/king_black.png'),
                      ),
                      title: Text("Đen",
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: _displayCapturedPieces(Color.BLACK,
                                match.matchInfo.blackCaptured)
                          ),
                          Text(match.getPoint(Color.BLACK), style: TextStyle(color: Colors.white70),),
                        ],
                      )
                    ),
                    ChessBoard(
                      controller: chessBoardController,
                      boardColor: BoardColor.brown,
                      boardOrientation: PlayerColor.white,
                      enableUserMoves: canMove,
                      onMove: () {
                        _displayArrow();
                        _playSound();
                        _updateMatchInfo();
                      },
                      arrows: _arrows,
                    ),
                    ListTile(
                      leading: Container(
                        height: 35,
                        child: Image.asset('assets/images/king_white.png'),
                      ),
                      title: Text("Trắng",
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          Expanded(
                              child: _displayCapturedPieces(Color.WHITE,
                                  match.matchInfo.whiteCaptured)
                          ),
                          Text(match.getPoint(Color.WHITE), style: TextStyle(color: Colors.white70)),
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
        ),
      ),
    );
  }

  void _updateMatchInfo() {
    MatchInfoProvider matchInfoProvider = context.read<MatchInfoProvider>();

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
        matchInfoProvider.onEndGame(context, 'Trắng', 'Đen', 0,
            'assets', 'assets/images/king_white.png', 'assets/images/king_black.png', 0, 0);
      }
      else {
        matchInfoProvider.onEndGame(context, 'Trắng', 'Đen', chessBoardController.game.history.last.turn == Color.WHITE ? 1 : -1,
            'assets', 'assets/images/king_white.png', 'assets/images/king_black.png', 0, 0);
      }
    }

    matchInfoProvider.matchInfo.fen = chessBoardController.getFen();
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

  void _onDrawButtonClicked() async {
    String? confirm = await showConfirmDialog(context, "Hòa cờ");
    if (confirm == "ok") {
      AudioCache player = AudioCache(prefix: 'assets/sounds/');
      player.play("gameover_stalemate.mp3");
      setState(() {
        canMove = false;
        buttonClickable = false;
      });
      MatchInfoProvider matchInfoProvider = context.read<MatchInfoProvider>();
      matchInfoProvider.onEndGame(context, 'Trắng', 'Đen', 0,
          'assets', 'assets/images/king_white.png', 'assets/images/king_black.png', 0, 0);
    }
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
      matchInfoProvider.matchInfo.resign = true;
      if (chessBoardController.game.turn == Color.WHITE) {
        matchInfoProvider.onEndGame(context, 'Trắng', 'Đen', -1,
            'assets', 'assets/images/king_white.png', 'assets/images/king_black.png', 0, 0);
      }
      else {
        matchInfoProvider.onEndGame(context, 'Trắng', 'Đen', 1,
            'assets', 'assets/images/king_white.png', 'assets/images/king_black.png', 0, 0);
      }
    }
  }

  void _playSoundStart() {
    AudioCache player = AudioCache(prefix: 'assets/sounds/');
    player.play('game_start.mp3');
  }

  void _playSound() {
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

  void _displayArrow() {
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
}
