import 'package:claim_investigation/providers/auth_provider.dart';
import 'package:claim_investigation/providers/claim_provider.dart';
import 'package:claim_investigation/providers/multipart_upload_provider.dart';
import 'package:claim_investigation/router/app_routes.dart';
import 'package:claim_investigation/screen/home_screen.dart';
import 'package:claim_investigation/screen/login_screen.dart';
import 'package:claim_investigation/screen/tabbar_screen.dart';
import 'package:claim_investigation/service/api_client.dart';
import 'package:claim_investigation/storage/app_pref.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/util/color_contants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'base/base_provider.dart';

GetIt getIt = GetIt.I;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupDI().then((value) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
        .then((_) {
      runApp(PreClaimApp());
    });
  });
}

Future<void> setupDI() async {
  var instance = await AppSharedPref.getInstance();
  getIt.registerSingleton<AppSharedPref>(instance);
  getIt.registerSingleton(ApiClient());
  var appHelper = await AppHelper.getInstance();
  getIt.registerSingleton(appHelper);
}

class PreClaimApp extends StatefulWidget {
  @override
  _PreClaimAppState createState() => _PreClaimAppState();
}

class _PreClaimAppState extends State<PreClaimApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClaimProvider()),
        ChangeNotifierProvider(create: (_) => MultiPartUploadProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MVC',
          theme: ThemeData(
            textTheme: TextTheme(
              headline1: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.black),
              headline2: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  color: Colors.black),
              headline3: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Colors.black),
              subtitle1: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Colors.black38),
              subtitle2: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Colors.black38),
              bodyText2: TextStyle(fontSize: 15, color: Colors.black),
            ),
            primaryColor: const Color(0xFF0E4179),
          ),
          home: auth.isAuth
                  ? TabBarScreen()
                  : LoginScreen(),
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }
}
