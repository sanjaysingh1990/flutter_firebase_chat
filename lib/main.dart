// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memechat/chatmodel/ChatKeyModel.dart';

import 'platform_adaptive.dart';
import 'type_meme.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Memechat',
      theme: defaultTargetPlatform == TargetPlatform.iOS
          ? kIOSTheme
          : kDefaultTheme,
      home: new ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  List<ChatMessage> _messages = [];
  DatabaseReference _messagesReference = FirebaseDatabase.instance.reference()
      .child('1')
      .child('461');
  TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;
  GoogleSignIn _googleSignIn = new GoogleSignIn();

  @override
  void initState() {
    super.initState();
    // _googleSignIn.signInSilently();
    FirebaseAuth.instance.signInAnonymously().then((user) {
      _messagesReference.onChildAdded.listen((Event event) {
        var val = event.snapshot.value;
        var _messagekey = val['messageId'];
        print(_messagekey);
        getMessage(_messagekey);
      });
    });
  }

  Future<ChatKeyModel> getMessage(String messageKey) async {
    Completer<ChatKeyModel> completer = new Completer<ChatKeyModel>();


    FirebaseDatabase.instance
        .reference()
        .child("messages")
        .child(messageKey)
        .once()
        .then((DataSnapshot snapshot) {
      var val = snapshot.value;
      _addMessage(
          created: val['created'],
          msg: val['message'],
          msgId: val['messageId'],
          recId: val['recieverId'],
          sendId: val['senderId']);
    });

    return completer.future;
  }


  @override
  void dispose() {
    for (ChatMessage message in _messages) {
      message.animationController.dispose();
    }
    super.dispose();
  }

  void _handleMessageChanged(String text) {
    setState(() {
      _isComposing = text.length > 0;
    });
  }

  void _handleSubmitted(String text) {
    _textController.clear();
//    _googleSignIn.signIn().then((user) {
//
//    });

    var key=_messagesReference.push().key;
    var currentDateTime=new DateTime.now().millisecondsSinceEpoch;
    var keyNode = {
      'created': currentDateTime,
      'messageId': key,

    };
    var message = {
      'created': currentDateTime,
      'message': text,
      'messsageId': key,
      'recieverId': '461',
      'senderId': '1',

    };
    DatabaseReference _messageKeyNode = FirebaseDatabase.instance.reference()
        .child('1')
        .child('461');
    DatabaseReference _message = FirebaseDatabase.instance.reference()
        .child('messages');


    _messageKeyNode.child(key).set(keyNode);
    _message.child(key).set(message);


  }

  void _addMessage({
    num created,
    String msg,
    String msgId,
    String recId,
    String sendId
  }) {
    var animationController = new AnimationController(
      duration: new Duration(milliseconds: 700),
      vsync: this,
    );
    var message = new ChatMessage(
        createdAt: created,
        message: msg,
        messageId: msgId,
        receiverId: recId,
        senderId: sendId,
        animationController: animationController);
    setState(() {
      _messages.insert(0, message);
    });
    animationController?.forward();
//    if (imageUrl != null) {
//      NetworkImage image = new NetworkImage(imageUrl);
//      image
//          .resolve(createLocalImageConfiguration(context))
//          .addListener((_, __) {
//        animationController?.forward();
//      });
//    } else {
//      animationController?.forward();
//    }
  }

  Future<Null> _handlePhotoButtonPressed() async {
//    var account = await _googleSignIn.signIn();
//    var imageFile = await ImagePicker.pickImage();
//    var random = new Random().nextInt(10000);
//    var ref = FirebaseStorage.instance.ref().child('image_$random.jpg');
//    var uploadTask = ref.put(imageFile);
//    var textOverlay =
//        await Navigator.push(context, new TypeMemeRoute(imageFile));
//    if (textOverlay == null) return;
//    var downloadUrl = (await uploadTask.future).downloadUrl;
//    var message = {
//      'sender': {'name': account.displayName, 'imageUrl': account.photoUrl},
//      'imageUrl': downloadUrl.toString(),
//      'textOverlay': textOverlay,
//    };
//    _messagesReference.push().set(message);
  }

  Widget _buildTextComposer() {
    return new IconTheme(
        data: new IconThemeData(color: Theme
            .of(context)
            .accentColor),
        child: new PlatformAdaptiveContainer(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: new Row(children: [
              new Container(
                margin: new EdgeInsets.symmetric(horizontal: 4.0),
                child: new IconButton(
                  icon: new Icon(Icons.photo),
                  onPressed: _handlePhotoButtonPressed,
                ),
              ),
              new Flexible(
                child: new TextField(
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  onChanged: _handleMessageChanged,
                  decoration:
                  new InputDecoration.collapsed(hintText: 'Send a message'),
                ),
              ),
              new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 4.0),
                  child: new PlatformAdaptiveButton(
                    icon: new Icon(Icons.send),
                    onPressed: _isComposing
                        ? () => _handleSubmitted(_textController.text)
                        : null,
                    child: new Text('Send'),
                  )),
            ])));
  }

  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new PlatformAdaptiveAppBar(
          title: new Text('Memechat'),
          platform: Theme
              .of(context)
              .platform,
        ),
        body: new Column(children: [
          new Flexible(
              child: new ListView.builder(
                padding: new EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) =>
                new ChatMessageListItem(_messages[index]),
                itemCount: _messages.length,
              )),
          new Divider(height: 1.0),
          new Container(
              decoration: new BoxDecoration(color: Theme
                  .of(context)
                  .cardColor),
              child: _buildTextComposer()),
        ]));
  }
}

class ChatMessage {
  ChatMessage({this.createdAt,
    this.messageId,
    this.message,
    this.receiverId,
    this.senderId,
    this.animationController});

  final num createdAt;
  final String message;
  final String messageId;
  final String receiverId;
  final String senderId;
  final AnimationController animationController;
}

class ChatMessageListItem extends StatelessWidget {
  ChatMessageListItem(this.message);

  final ChatMessage message;

  Widget build(BuildContext context) {
    return new SizeTransition(
        sizeFactor: new CurvedAnimation(
            parent: message.animationController, curve: Curves.easeOut),
        axisAlignment: 0.0,
        child: new Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
//              new Container(
//                margin: const EdgeInsets.only(right: 16.0),
//                child: new CircleAvatar(
//                    backgroundImage: new NetworkImage(message.sender.imageUrl)),
//              ),

              new Text(message.message,
                  style: Theme
                      .of(context)
                      .textTheme
                      .subhead),

              new Text(
                  getEpocFromMillseconds(message.createdAt)
                  ,
                  style: Theme
                      .of(context)
                      .textTheme
                      .subhead),
            ],
          ),
        ));
  }

  String getEpocFromMillseconds(num time)
  {
    DateTime date = new DateTime.fromMillisecondsSinceEpoch(time);
    var format = new DateFormat("yMd");
    return format.format(date);
  }
}

//class ChatMessageContent extends StatelessWidget {
//  ChatMessageContent(this.message);
//
//  final ChatMessage message;
//
//  Widget build(BuildContext context) {
//    if (message.imageUrl != null) {
//      var image = new Image.network(message.imageUrl, width: 200.0);
//      if (message.textOverlay == null) {
//        return image;
//      } else {
//        return new Stack(
//          alignment: FractionalOffset.topCenter,
//          children: [
//            image,
//            new Container(
//                alignment: FractionalOffset.topCenter,
//                width: 200.0,
//                child: new Text(message.textOverlay,
//                    style: const TextStyle(
//                        fontFamily: 'Anton',
//                        fontSize: 30.0,
//                        color: Colors.white),
//                    softWrap: true,
//                    textAlign: TextAlign.center)),
//          ],
//        );
//      }
//    } else
//      return new Text(message.text);
//  }
//}
