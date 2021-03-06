import 'dart:developer';

class AppLog {
  static void print(String message){
    log("=====>  $message <=====",name: 'Logging');
  }
}