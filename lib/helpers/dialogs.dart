import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_vua/views/page_matching.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/login_provider.dart';
import '../views/page_two_players.dart';

Future<String?> showConfirmDialog(BuildContext context, String dispMessage) async {
  AlertDialog dialog = AlertDialog(
    title: const Text("Xác nhận"),
    content: Text(dispMessage),
    actions: [
      ElevatedButton(
        onPressed: () => Navigator.of(context, rootNavigator: true).pop("cancel"),
        style:ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
        ),
        child: Text("Hủy",style: TextStyle(color: Colors.white),),
      ),
      ElevatedButton(
        onPressed: () => Navigator.of(context, rootNavigator: true).pop("ok"),
        style:ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
        ),
        child: Text("OK",style: TextStyle(color: Colors.white),),
      )
    ],
  );

  String? res = await showDialog<String?>(
    barrierDismissible: false,
    context: context,
    builder: (context) => dialog,
  );

  return res;
}

void showDialogEndGame(BuildContext context, String whiteName, String blackName, String winner, String typeDisplayImg,
    String whiteImg, String blackImg, int elo, int eloGain) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(winner=="black"
                    ? "Phe đen thắng"
                    : (winner=="white" ? "Phe trắng thắng" : "Hòa")
                  ,style: TextStyle(color: Colors.black54,fontWeight: FontWeight.bold,fontSize: 20,),
                  textAlign: TextAlign.center,),
              ),
              IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.close,))
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            if(winner=="black")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.fill,
                              image: typeDisplayImg == "assets" ?
                              AssetImage(whiteImg) : Image.network(whiteImg).image
                          ),
                          border: Border.all(
                            width: 5,
                            color:Colors.grey,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(whiteName,style: TextStyle(color: Colors.grey, fontSize: 10),)
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_alarm_rounded),
                      Text("0-1",style: TextStyle(fontSize: 15,color:Colors.grey ),)
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.fill,
                              image: typeDisplayImg == "assets" ?
                              AssetImage(blackImg) : Image.network(blackImg).image
                          ),
                          border: Border.all(
                            width: 5,
                            color:Colors.green,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(blackName,style: TextStyle(color: Colors.grey, fontSize: 10),)
                    ],
                  ),
                ],
              )
            else if(winner=="white")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.fill,
                              image: typeDisplayImg == "assets" ?
                              AssetImage(whiteImg) : Image.network(whiteImg).image
                          ),
                          border: Border.all(
                            width: 5,
                            color:Colors.green,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,),
                      Text(whiteName,style: TextStyle(color: Colors.grey, fontSize: 10),)
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_alarm_rounded),
                      Text("1-0",style: TextStyle(fontSize: 15,color:Colors.grey ),)
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.fill,
                              image: typeDisplayImg == "assets" ?
                              AssetImage(blackImg) : Image.network(blackImg).image
                          ),
                          border: Border.all(
                            width: 5,
                            color:Colors.grey,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,),
                      Text(blackName,style: TextStyle(color: Colors.grey, fontSize: 10),)
                    ],
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.fill,
                              image: typeDisplayImg == "assets" ?
                              AssetImage(whiteImg) : Image.network(whiteImg).image
                          ),
                          border: Border.all(
                            width: 5,
                            color:Colors.grey,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,),
                      Text(whiteName,style: TextStyle(color: Colors.grey, fontSize: 10),)
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_alarm_rounded),
                      Text("1/2-1/2",style: TextStyle(fontSize: 15,color:Colors.grey ),)
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.fill,
                              image: typeDisplayImg == "assets" ?
                              AssetImage(blackImg) : Image.network(blackImg).image
                          ),
                          border: Border.all(
                            width: 5,
                            color:Colors.grey,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,),
                      Text(blackName,style: TextStyle(color: Colors.grey, fontSize: 10),)
                    ],
                  ),
                ],
              ),
            if (typeDisplayImg == 'network')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$elo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                  SizedBox(width: 10,),
                  Text('${eloGain >= 0 ? '+' : ''}$eloGain', style: TextStyle(color: Colors.green),),
                ],
              )
          ],
        ),
        actions: [
          ElevatedButton(
            style:ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            child: Text("Ván mới",style: TextStyle(color: Colors.white),),
            onPressed: () {
              if (typeDisplayImg == 'assets'){
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => ProviderPageTwoPlayers()),
                );
              }
              else {
                // Update user: is matching
                GoogleLoginProvider g = context.read<GoogleLoginProvider>();
                FirebaseFirestore.instance.collection('UserInfo').doc(g.user?.uid)
                    .update({ 'isMatching': true });
                g.user?.isMatching = true;
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => PageMatching()),
                );
              }
            },
          ),
        ],
      );
    },
  );
}