import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_manager.dart' as auth;
import 'package:toast/toast.dart';

class Webview extends StatelessWidget {
  Webview({Key key}) : super(key: key);
  static const _urls = [
    'https://shachikuengineer.tk/websocket/oauth/google',
    'https://shachikuengineer.tk/websocket/oauth/facebook',
    'https://shachikuengineer.tk/websocket/oauth/line'
  ];

  @override
  Widget build(BuildContext context) {
    /*final _loginWebView = FlutterWebviewPlugin();
    _loginWebView.onStateChanged.listen((WebViewStateChanged viewState) {
      print(viewState.url);
      // print(viewState.navigationType);
      if (viewState.type == WebViewState.finishLoad &&
          viewState.url.startsWith('https://shachikuengineer.tk')) {
        // Navigator.pop(context);
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
        Toast.show("Login Success", context,
            duration: Toast.LENGTH_LONG,
            gravity: Toast.BOTTOM,
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            textColor: Theme.of(context).colorScheme.surface);
        _loginWebView.close();
        _loginWebView.dispose();
      }
    });*/
    return new WebviewScaffold(
      url: _urls[ModalRoute.of(context).settings.arguments],
      userAgent:
          'Mozilla/5.0 (Linux; Android 10; ASUS_Z01RD) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.105 Mobile Safari/537.36',
      appBar: new AppBar(
        title: Text(AppLocalizations.of(context).login),
      ),
      javascriptChannels: Set.from([
        JavascriptChannel(
            name: 'Success',
            onMessageReceived: (JavascriptMessage message) async {
              FlutterWebviewPlugin().close();
              FlutterWebviewPlugin().dispose();
              Object payload = json.decode(
                  utf8.decode(base64Decode(message.message.split('.')[1])));
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('token', message.message);
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/', (Route<dynamic> route) => false);
              Toast.show("Login Success", context,
                  duration: Toast.LENGTH_LONG,
                  gravity: Toast.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  textColor: Theme.of(context).colorScheme.surface);
            }),
        JavascriptChannel(
            name: 'Failure',
            onMessageReceived: (JavascriptMessage message) {
              FlutterWebviewPlugin().close();
              FlutterWebviewPlugin().dispose();
              Navigator.of(context).pop();
              Toast.show("Login Failure", context,
                  duration: Toast.LENGTH_LONG,
                  gravity: Toast.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  textColor: Theme.of(context).colorScheme.surface);
            })
      ]),
      withZoom: true,
      withLocalStorage: true,
      hidden: true,
      initialChild: Container(
        color: Theme.of(context).colorScheme.background,
        child: const Center(
          child: Text('Waiting.....'),
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  LoginPage({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    // final google_backgroundColor = isDarkMode? Color(0xff1877f2):Colors.black.withOpacity(0.8);
    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.background, //Colors.grey[200]
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(AppLocalizations.of(context).login),
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          height: 300,
          child: Card(
            color: Theme.of(context).primaryColorLight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.black)),
                    icon: Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Image.asset(
                          "images/google.png",
                          width: 24.0,
                          height: 24.0,
                        )),
                    label:
                        Text('Google', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      btnLoginClickEvent(context, 0);
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Color(0xff1877f2))),
                    icon: Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Image.asset(
                          "images/fb.png",
                          width: 24.0,
                          height: 24.0,
                        )),
                    label:
                        Text('Facebook', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      btnLoginClickEvent(context, 1);
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Color(0xff00c300))),
                    icon: Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Image.asset(
                          "images/line.png",
                          width: 24.0,
                          height: 24.0,
                        )),
                    label: Text('LINE', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      btnLoginClickEvent(context, 2);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> btnLoginClickEvent(context, type) async {
  print('btnClickEvent...');
  await auth.AuthManager.instance.login(context, type);
  // _loginWebView = await auth.AuthManager.instance.login(type);
  // if(_loginWebView!=null)
  //   _loginWebView.close();
  print("end");
}
