import 'package:flutter/material.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

import '../../../domain/entities/user.dart';
import '../../../service/user_service.dart';

class HomePage extends StatelessWidget {
  User get user => IN.get<UserService>().user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              RM.getSetState<UserService>((s) => s.signOut());
            },
          )
        ],
      ),
      body: Center(child: Text('Welcome ${user.email ?? user.uid}!')),
    );
  }
}
