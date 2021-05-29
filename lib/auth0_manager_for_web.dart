import 'package:flutter/material.dart';
import 'package:toast/toast.dart';
import 'auth_manager.dart';
import 'dart:js' as js;

class Auth0ManagerForWeb extends AuthManager {
  BuildContext context;
  Future<void> onSuccess(String token) async {
    print(token);
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.setString('token', token);
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    Toast.show("Login Success", context,
        duration: Toast.LENGTH_LONG,
        gravity: Toast.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        textColor: Theme.of(context).colorScheme.surface);
  }

  void onFailure(String error) {
    print(error);
    Navigator.of(context).pop();
    Toast.show("Login Failure", context,
        duration: Toast.LENGTH_LONG,
        gravity: Toast.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        textColor: Theme.of(context).colorScheme.surface);
  }

  @override
  Future<void> login(BuildContext context, [int type]) async {
    this.context = context;
    js.context['onSuccessFlutter'] = onSuccess;
    js.context['onFailureFlutter'] = onFailure;
    js.context.callMethod('openOauth', [type]);
  }
}

AuthManager getManager() => Auth0ManagerForWeb();
