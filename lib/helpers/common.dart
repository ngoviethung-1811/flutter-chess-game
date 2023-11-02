import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum MyColor {
  AppBarColor,
  BodyColor,
}

Color getColor(MyColor color) {
  switch (color) {
    case MyColor.AppBarColor:
      return Color.fromRGBO(0, 77, 26, 0.9);
    case MyColor.BodyColor:
      return Color.fromRGBO(0, 102, 34, 0.75);
    default:
      return Colors.white;
  }
}

Future<bool> CheckConnection() async{
  var connectivityResult = await (Connectivity().checkConnectivity());
  if(connectivityResult==ConnectivityResult.mobile){
    return true;
  }else if(connectivityResult==ConnectivityResult.wifi){
    return true;
  }else{
    return false;
  }
}

int calculateElo(int playerElo, int opponentElo, double score) {
  double expectedScore = 1 / (1 + pow(10, (opponentElo - playerElo) / 400));
  double kFactor = 32;
  double newElo = playerElo + kFactor * (score - expectedScore);
  return newElo.round();
}