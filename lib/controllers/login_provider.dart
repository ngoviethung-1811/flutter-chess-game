import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_vua/models/user_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleLoginProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoggedIn = false;
  UserInf? _user;

  bool get isLoggedIn => _isLoggedIn;
  UserInf? get user => _user;

  Future<void> signIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken
      );
      var userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential != null) {
        Fluttertoast.showToast(msg: 'Đăng nhập thành công');
        final DocumentReference userDocRef = FirebaseFirestore.instance.collection('UserInfo').doc(googleUser?.id);
        final DocumentSnapshot userDocSnapshot = await userDocRef.get();
          if (!userDocSnapshot.exists) {
          // Create new user
          final Map<String, dynamic> data = {
            'uid':googleUser?.id,
            'name': googleUser?.displayName,
            'email': googleUser?.email,
            'avatar': googleUser?.photoUrl,
            'elo': 1000,
            'isMatching': false,
          };
          await userDocRef.set(data);
        } else {
          _updateUserInfoOnFirebase(googleUser);
        }

        userDocRef.update({ 'isMatching': false });
        _isLoggedIn = true;
        _user = UserInf.fromFirestore(await userDocRef.get());

        notifyListeners();
      } else{
        Fluttertoast.showToast(msg: 'Đăng nhập thất bại');
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _isLoggedIn = false;
      _user = null;
      notifyListeners();
      Fluttertoast.showToast(msg: 'Đã đăng xuất');
    } catch (error) {
      print(error);
    }
  }

  void _updateUserInfoOnFirebase(GoogleSignInAccount? googleUser) async {
    if (googleUser == null) return;
    final DocumentReference userDocRef = FirebaseFirestore.instance.collection('UserInfo').doc(googleUser.id);
    userDocRef.update({
      'name': googleUser.displayName,
      'email': googleUser.email,
      'avatar': googleUser.photoUrl,
      'isMatching': false,
    }).catchError((error) {
      print(error);
    });
  }
}