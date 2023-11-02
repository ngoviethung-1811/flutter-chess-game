import 'package:co_vua/controllers/login_provider.dart';
import 'package:co_vua/views/page_home.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'helpers/common.dart';

bool isOnline = false;

void main()
{
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context)  => GoogleLoginProvider(),
        child: MaterialApp(
        title: 'Cờ vua',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: PageHome(),
      )
    );
  }
}