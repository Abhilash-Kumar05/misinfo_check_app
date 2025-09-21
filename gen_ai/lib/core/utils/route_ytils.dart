import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../ui/screens/chat_screen.dart';
import '../constants/string.dart';

class Routeutlis{
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch(settings.name){
      case chat:
        return MaterialPageRoute(builder: (context) => EnhancedChatRoom());

      default:
        return MaterialPageRoute(builder: (context) => Scaffold(body: Center(child: Text('Page not found')),));

    }}}