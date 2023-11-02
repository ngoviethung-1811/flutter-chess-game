import 'package:co_vua/controllers/login_provider.dart';
import 'package:co_vua/helpers/common.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class PageProfile extends StatefulWidget {
  @override
  State<PageProfile> createState() => _PageProfileState();
}

class _PageProfileState extends State<PageProfile> {

  String? name;
  int? elo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: getColor(MyColor.AppBarColor),
        title: Text('Hồ sơ cá nhân'),
      ),
      body: Container(
        color: getColor(MyColor.BodyColor),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/chess_profile.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 78,
                      backgroundColor: Colors.black,
                      backgroundImage: _userAvatar(),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.green,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name ?? 'Bobby Team',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Elo: ${elo ?? 0}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
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

    GoogleLoginProvider g = context.read<GoogleLoginProvider>();
    name = g.user?.name;
    elo = g.user?.elo;
  }

  ImageProvider _userAvatar() {
    if (isOnline) {
      GoogleLoginProvider g = context.read<GoogleLoginProvider>();
      return NetworkImage(g.user?.avatar ?? '');
    }
    return AssetImage('assets/images/default_avatar.png');
  }
}