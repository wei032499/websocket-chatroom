import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loadmore/loadmore.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class Message {
  String uid;
  String text;
  Message({this.uid, this.text});
}

class ChatPage extends StatefulWidget {
  ChatPage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Message> listItems = [];
  final TextEditingController _chatController = new TextEditingController();
  final FocusNode myFocuseNode = FocusNode();
  bool _isFinish = true;
  bool _isConnected = false;
  String cid;
  String token;
  WebSocketChannel channel;
  Stream stream;
  String finishText = "Waiting for connection...";

  @override
  void initState() {
    super.initState();
    // listItems.add(Message(uid: 'system', text: 'Waiting for connection...'));
    _chatController.addListener(() {
      if (lastKey == "Enter" || lastKey == "NumpadEnter") {
        lastKey = '';
        if (_chatController.text.length > 0) {
          _chatController.text = _chatController.text
              .substring(0, _chatController.text.length - 1);
        }
        _sendMessage();
      }
    });
  }

  @override
  void dispose() {
    print("dispose");
    super.dispose();
  }

  Future<bool> _loadMore() async {
    print("onLoadMore");
    setState(() {});
    await Future.delayed(Duration(seconds: 0, milliseconds: 100));

    return true;
  }

  void _sendMessage() {
    String text = _chatController.text;
    _chatController.clear();

    myFocuseNode.requestFocus();
    if (text != "") {
      channel.sink
          .add(jsonEncode({'type': 'message', 'token': token, 'text': text}));
    }
  }

  String lastKey = '';
  void handleKeyPress(event) {
    if (event is RawKeyDownEvent && event.data is RawKeyEventDataWeb) {
      RawKeyEventDataWeb data = event.data as RawKeyEventDataWeb;
      lastKey = data.code;
      if (event.isShiftPressed) lastKey += "+shift";
    }
  }

  void _initChatPage() async {
    // listen to the websocket channel
    StreamSubscription subscription;
    subscription = stream.listen((message) {
      Map<String, dynamic> msg = jsonDecode(message);
      print(msg);
      if (mounted) {
        setState(() {
          if (msg['type'] == 'new') {
            cid = msg['cid'];
            channel.sink
                .add(jsonEncode({'type': 'join', 'token': msg['token']}));
          } else if (msg['type'] == 'connection') {
            if (cid == msg['cid']) {
              myUID = msg['uid'];
              token = msg['token'];
              _isConnected = true;
              finishText = "connected " + msg['cid'];
            }
          } else if (msg['type'] == 'message') {
            if (cid == msg['cid'])
              listItems.insert(0, Message(uid: msg['uid'], text: msg['text']));
          }
        });
      } else
        subscription.cancel();
    }, onDone: () {
      Navigator.of(context).pop();
      subscription.cancel();
    }, onError: (error) {
      Navigator.of(context).pop();
      subscription.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (channel == null) {
      Map<String, dynamic> arguments =
          ModalRoute.of(context).settings.arguments;
      channel = arguments['channel'];
      stream = arguments['stream'];
      cid = arguments['cid'];
      myUID = arguments['uid'];
      token = arguments['token'];
      _initChatPage();
      if (cid == null)
        channel.sink.add(jsonEncode({'type': 'new'}));
      else {
        _isConnected = true;
        finishText = "connected " + cid;
        // channel.sink.add(jsonEncode({'type': 'join', 'token': arguments['token']}));
      }
    }
    // bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    // final google_backgroundColor = isDarkMode? Color(0xff1877f2):Colors.black.withOpacity(0.8);
    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.background, //Colors.grey[200]
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: Column(
            children: <Widget>[
              Expanded(
                  child: Scrollbar(
                child: Align(
                    alignment: Alignment.topCenter,
                    child: LoadMore(
                        whenEmptyLoad: true,
                        textBuilder: _buildTraditionalChineseText,
                        onLoadMore: _loadMore,
                        isFinish: _isFinish,
                        delegate: _LoadMoreDelegate(),
                        child: ListView.builder(
                            reverse: true,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount: listItems.length,
                            itemBuilder: (context, index) {
                              return MessageBox(message: listItems[index]);
                            }))),
              )),
              Container(
                  padding: const EdgeInsets.all(8.0),
                  child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 500),
                      child: _isConnected
                          ? Row(
                              children: <Widget>[
                                Flexible(
                                  child: RawKeyboardListener(
                                      onKey: handleKeyPress,
                                      focusNode: FocusNode(),
                                      child: TextField(
                                        focusNode: myFocuseNode,
                                        controller: _chatController,
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                        decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.all(16.0),
                                            border: OutlineInputBorder(),
                                            hintText: 'Type something...'),
                                      )),
                                ),
                                IconButton(
                                  icon: Icon(Icons.send),
                                  onPressed: () => _sendMessage(),
                                ),
                              ],
                            )
                          : Row()))
            ],
          ),
        ),
      ),
    );
  }

  String _buildTraditionalChineseText(LoadMoreStatus status) {
    String text;
    switch (status) {
      case LoadMoreStatus.fail:
        text = "載入失敗，請點擊重試";
        break;
      case LoadMoreStatus.idle:
        text = "等待載入更多";
        break;
      case LoadMoreStatus.loading:
        text = "載入中，請稍後...";
        break;
      case LoadMoreStatus.nomore:
        text = finishText; // 已無更多資料
        break;
      default:
        text = "";
    }
    return text;
  }
}

String myUID;

class MessageBox extends StatelessWidget {
  final Message message;

  MessageBox({Key key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(myUID);
    print(message.uid + "!");
    Widget content;
    if (message == null)
      return null;
    else if (message.uid == "system")
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 350),
              padding: EdgeInsets.all(10.0),
              child: SelectableText(message.text),
            ),
          )
        ],
      );
    else if (message.uid == myUID)
      content = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 350),
              color: Colors.green,
              padding: EdgeInsets.all(10.0),
              child: SelectableText(message.text,
                  style: TextStyle(fontSize: 18.0, color: Colors.white)),
            ),
          ),
          Icon(Icons.person, size: 32)
        ],
      );
    else
      content = Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.person, size: 32),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 350),
              color: Colors.pink,
              padding: EdgeInsets.all(10.0),
              child: SelectableText(message.text,
                  style: TextStyle(fontSize: 18.0, color: Colors.white)),
            ),
          ),
        ],
      );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: content,
    );
  }
}

class _LoadMoreDelegate extends LoadMoreDelegate {
  static const _defaultLoadMoreHeight = 80.0;
  static const _loadmoreIndicatorSize = 33.0;
  static const _loadMoreDelay = 16;

  /*@override
  double widgetHeight(LoadMoreStatus status) {
    if (status == LoadMoreStatus.nomore) return 0;

    return _defaultLoadMoreHeight;
  }*/

  @override
  Widget buildChild(LoadMoreStatus status,
      {builder = DefaultLoadMoreTextBuilder.chinese}) {
    String text = builder(status);
    if (status == LoadMoreStatus.fail) {
      return Container(
        child: Text(text),
      );
    }
    if (status == LoadMoreStatus.idle) {
      return Text(text);
    }
    if (status == LoadMoreStatus.loading) {
      return Container(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: _loadmoreIndicatorSize,
              height: _loadmoreIndicatorSize,
              child: CircularProgressIndicator(
                backgroundColor: Colors.blue,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(text),
            ),
          ],
        ),
      );
    }
    if (status == LoadMoreStatus.nomore) {
      return Text(text);
    }

    return Text(text);
  }
}
