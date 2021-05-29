import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_mode_handler/theme_mode_manager_interface.dart';
import 'package:toast/toast.dart';
import 'package:websocket/setting.dart';
import 'chat.dart';
import 'login.dart';
import 'package:theme_mode_handler/theme_mode_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyApp createState() => _MyApp();

  static _MyApp of(BuildContext context) =>
      context.findAncestorStateOfType<_MyApp>();
}

class _MyApp extends State<MyApp> {
  Locale _locale;

  @override
  void initState() {
    super.initState();
    setLocal();
  }

  void setLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString('locale');
    setState(() {
      if (languageCode != null) _locale = Locale(languageCode);
    });
  }

  // ThemeMode themeMode = ThemeMode.system;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ThemeModeHandler(
        manager: MyManager(),
        builder: (ThemeMode themeMode) {
          return MaterialApp(
              title: 'Flutter Demo',
              theme: ThemeData(
                  primarySwatch: Colors.blue, colorScheme: ColorScheme.light()),
              darkTheme: ThemeData(colorScheme: ColorScheme.dark()),
              themeMode: themeMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              // supportedLocales: AppLocalizations.supportedLocales,
              supportedLocales: [
                const Locale('en', ''),
                const Locale.fromSubtags(languageCode: 'zh'),
              ],
              locale: _locale,
              // home: MyHomePage(title: 'Flutter Demo Home Page'),
              initialRoute: '/',
              routes: {
                '/': (_) => MyHomePage(title: 'List'),
                '/chat': (_) => ChatPage(title: 'Chat'),
                '/login': (_) => LoginPage(),
                '/oauth': (_) => Webview(),
                '/setting': (_) => SettingPage(),
              });
        });
  }
}

class MyManager implements IThemeModeManager {
  @override
  Future<String> loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('themeMode');
  }

  @override
  Future<bool> saveThemeMode(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString('themeMode', value);
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Room {
  String cid;
  String token;
  String text;
  String uid;
  Room({this.cid, this.uid, this.token, this.text});
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _isVisible = true;
  final List<Room> listItems = [];

  WebSocketChannel channel;
  Timer timmer;

  /*void _incrementCounter() async {
    Navigator.pushNamed(context, '/chat',
        arguments: {"channel": channel, "stream": stream});
    // Navigator.pushNamed(context, '/login');
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
      // _isVisible = false;
    });
  }*/

  @override
  void initState() {
    super.initState();
    _initWebsocket();
  }

  Stream stream;
  void _initWebsocket() async {
    print("_initWebsocket");
    // initial the websocket channel
    channel = WebSocketChannel.connect(
        Uri.parse('wss://shachikuengineer.tk/websocket'));

    // listen to the websocket channel
    stream = channel.stream.asBroadcastStream();
    stream.listen((message) {
      Map<String, dynamic> msg = jsonDecode(message);
      if (msg['type'] == 'connection') //token_refresh();
        setState(() {
          listItems.insert(
              0, Room(cid: msg['cid'], token: msg['token'], uid: msg['uid']));
        });
    }, onDone: () {
      print(channel.closeCode);
      print(channel.closeReason);
      _initWebsocket();
    }, onError: (error) {
      print("onError:" + error);
      _initWebsocket();
    });

    await setRefreshTimmer();
  }

  Future<void> setRefreshTimmer() async {
    // token refresh
    dynamic result = await token_refresh();
    int expires_in = 3600;
    if (result != null && result.containsKey(expires_in))
      expires_in = result.expires_in;
    if (timmer != null) timmer.cancel();
    timmer = Timer.periodic(new Duration(seconds: (expires_in * 2 / 3).round()),
        (timer) {
      token_refresh();
      // debugPrint(timer.tick.toString());
    });
    print("timmer set");
  }

  Future<dynamic> token_refresh() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');

    var response;
    if (token != null && !kIsWeb)
      response = await http.post(
          Uri.parse('https://shachikuengineer.tk/websocket/token/refresh'),
          body: {'token': token});
    else
      response = await http.post(
          Uri.parse('https://shachikuengineer.tk/websocket/token/refresh'));
    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      if (!kIsWeb) await prefs.setString('token', json['access_token']);

      // manual get authorization
      channel.sink
          .add(jsonEncode({'type': 'auth', 'token': json['access_token']}));

      response = await http.post(
          Uri.parse('https://shachikuengineer.tk/websocket/me/roomlist'),
          body: {'token': json['access_token']});
      var list = jsonDecode(response.body);
      if (mounted)
        setState(() {
          listItems.clear();
          list.forEach((element) => listItems.add(Room(
              cid: element["cid"],
              uid: element["uid"],
              token: element["token"])));
        });

      return json;
    } else {
      Toast.show("Please login...", context,
          duration: Toast.LENGTH_LONG,
          gravity: Toast.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          textColor: Theme.of(context).colorScheme.surface);
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', ModalRoute.withName('/'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: AppLocalizations.of(context).menuIconTip,
            );
          },
        ),
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: Column(
            children: <Widget>[
              Expanded(
                  child: Scrollbar(
                child: ListView.builder(
                    // shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    itemCount: listItems.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/chat', arguments: {
                              "channel": channel,
                              "stream": stream,
                              "cid": listItems[index].cid,
                              "token": listItems[index].token,
                              "uid": listItems[index].uid,
                            });
                          },
                          child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(listItems[index].cid,
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w500)),
                                  Text('',
                                      style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w300))
                                ],
                              )));
                    }) /*Align(
                    alignment: Alignment.topCenter,
                    child: )*/
                ,
              ))
            ],
          ),
        ),
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Drawer Header'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.login),
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(AppLocalizations.of(context).login),
                  )
                ],
              ),
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.logout),
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(AppLocalizations.of(context).logout),
                  )
                ],
              ),
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.settings),
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(AppLocalizations.of(context).setting),
                  )
                ],
              ),
              onTap: () {
                Navigator.pushNamed(context, '/setting');
              },
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: _isVisible
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chat',
                        arguments: {"channel": channel, "stream": stream});
                  }, //_incrementCounter,
                  tooltip: 'Increment',
                  child: Icon(Icons.add),
                )
              : null), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
