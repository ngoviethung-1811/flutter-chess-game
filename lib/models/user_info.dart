import 'package:cloud_firestore/cloud_firestore.dart';

class UserInf {
  String? uid;
  String? name;
  String? email;
  String? avatar;
  int? elo;
  bool? isMatching;
  String? currentMatchID;

  UserInf({
    this.uid,
    this.name,
    this.email,
    this.avatar,
    this.elo,
    this.isMatching,
    this.currentMatchID
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatarUrl': avatar,
      'elo': elo,
      'isMatching': isMatching,
      'currentMatchID': currentMatchID,
    };
  }

  factory UserInf.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserInf(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      avatar: data['avatar'],
      elo: data['elo'],
      isMatching: data['isMatching'],
      currentMatchID: data['currentMatchID'],
    );
  }
}