import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:co_vua/helpers/common.dart';
import 'package:provider/provider.dart';

import '../controllers/login_provider.dart';
import '../main.dart';

class PageLogin extends StatefulWidget {
  @override
  _PageLoginState createState() => _PageLoginState();
}

class _PageLoginState extends State<PageLogin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: getColor(MyColor.AppBarColor),
        title: Text('Đăng nhập'),
      ),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/bishop_black.png',
              height: 100.0,
              width: 100.0,
            ),
            SizedBox(height: 20.0),
            Text(
              'Mỗi bậc thầy cờ vua đều đã từng là người mới bắt đầu.',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _handleSignIn,
              child: Text('Đăng nhập với Google'),
            ),
          ],
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          color: getColor(MyColor.BodyColor),
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
  }

  Future<void> _handleSignIn() async {
    GoogleLoginProvider g = context.read<GoogleLoginProvider>();
    g.signIn();
    Navigator.pop(context);
  }
}