import 'auth_manager.dart';
import 'package:flutter/material.dart';

class Auth0Manager extends AuthManager {
  @override
  Future<void> login(BuildContext context, [int type]) async {
    Navigator.pushNamed(context, '/oauth', arguments: type);
  }
}

AuthManager getManager() => Auth0Manager();
