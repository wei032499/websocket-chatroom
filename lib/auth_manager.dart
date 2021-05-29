import 'package:flutter/material.dart';

import 'auth0_manager_stub.dart'
if (dart.library.io) 'auth0_manager.dart'
if (dart.library.js) 'auth0_manager_for_web.dart';

abstract class AuthManager {
  static AuthManager _instance;

  static AuthManager get instance {
    _instance ??= getManager();
    return _instance;
  }
  Future<void> login(BuildContext context,[int type]);
}