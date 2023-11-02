import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_vua/main.dart';
import 'package:co_vua/views/page_login.dart';
import 'package:co_vua/views/page_matching.dart';
import 'package:co_vua/views/page_profile.dart';
import 'package:co_vua/views/page_two_players.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../controllers/login_provider.dart';
import '../helpers/common.dart';
import '../helpers/dialogs.dart';

class PageHome extends StatefulWidget {
  const PageHome({Key? key}) : super(key: key);

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {

  @override
  Widget build(BuildContext context) {
    return Consumer<GoogleLoginProvider>(
        builder: (context,googleSignIn,child){
          return Scaffold(
            resizeToAvoidBottomInset: false,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: getColor(MyColor.AppBarColor),
              elevation: 0,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  (googleSignIn.isLoggedIn==false)
                  ? GestureDetector(
                    onTap: () {
                      _signIn();
                    },
                    child: CircleAvatar(radius: 15, backgroundImage: AssetImage('assets/images/default_avatar.png'))
                    ): GestureDetector(
                      onTap: () {
                        _viewProfile();
                      },
                      child: CircleAvatar(radius: 15, backgroundImage: NetworkImage(googleSignIn.user?.avatar ?? ''),)
                  ) ,
                  Text(
                    'Cờ vua',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pacifico',
                    ),
                  ),
                  (googleSignIn.isLoggedIn==true)
                    ? SizedBox(
                    width: 30,
                    child: IconButton(
                      icon: Icon(Icons.logout),
                      onPressed: () {
                        _signOut();
                      },
                    )
                  )
                      : SizedBox(
                    width: 30,
                  )
                ],
              ),
            ),
            body: Container(
              color: getColor(MyColor.BodyColor),
              child: Expanded(
                child: Center(
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 1,
                    padding: EdgeInsets.all(20.0),
                    mainAxisSpacing: 20.0,
                    childAspectRatio: 4.0,
                    children: [
                      _buildGameTypeCard(
                          context,
                          '2 người 1 máy',
                          'assets/images/chess_board.png',
                          'Đấu với bạn bè trên cùng một thiết bị',
                              () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => ProviderPageTwoPlayers(),
                            ));
                          }
                      ),
                      _buildGameTypeCard(
                          context,
                          'Chơi Online',
                          'assets/images/chess_board.png',
                          'Khiêu chiến với những người chơi khác',
                              () {
                                btnPlayOnlinePress();
                          }
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildGameTypeCard(
      BuildContext context, String title, String imagePath, String description,
      Function callback) {
    return GestureDetector(
      onTap: () {
        callback();
      },
      child: Card(
        color: Colors.white.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                imagePath,
                height: 64.0,
                width: 64.0,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void btnPlayOnlinePress() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
      isOnline = true;
    } else {
      isOnline = false;
    }

    if (isOnline == false) {
      Fluttertoast.showToast(msg: 'Không có kết nối mạng');
    }
    else {
      final provider = Provider.of<GoogleLoginProvider>(context,listen:false);
      if (provider.isLoggedIn == false) {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => PageLogin(),
        ));
      }
      else {
        // Update user: is matching
        GoogleLoginProvider g = context.read<GoogleLoginProvider>();
        FirebaseFirestore.instance.collection('UserInfo').doc(g.user?.uid)
          .update({ 'isMatching': true });
        g.user?.isMatching = true;

        Navigator.push(context, MaterialPageRoute(
          builder: (context) => PageMatching(),
        ));
      }
    }
}

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
          isOnline = true;
        } else {
          isOnline = false;
        }
      });
    });
  }

  Future<void> _signOut() async {
    String? confirm = await showConfirmDialog(context, "Đăng xuất");
    if (confirm == "ok") {
      GoogleLoginProvider g = context.read<GoogleLoginProvider>();
      g.signOut();
    }
  }

  void _signIn() {
    if (isOnline == false) {
      Fluttertoast.showToast(msg: 'Không có kết nối mạng');
    }
    else {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => PageLogin(),
      ));
    }
  }

  void _viewProfile() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => PageProfile(),
    ));
  }
}
