import 'package:claim_investigation/screen/case_details_screen.dart';
import 'package:claim_investigation/screen/case_list_screen.dart';
import 'package:claim_investigation/screen/change_password_screen.dart';
import 'package:claim_investigation/screen/edit_profile_screen.dart';
import 'package:claim_investigation/screen/forgotpassword_screen.dart';
import 'package:claim_investigation/screen/forms_piv.dart';
import 'package:claim_investigation/screen/forms_piv_others.dart';
import 'package:claim_investigation/screen/full_image_screen.dart';
import 'package:claim_investigation/screen/home_screen.dart';
import 'package:claim_investigation/screen/login_screen.dart';
import 'package:claim_investigation/screen/otp_screen.dart';
import 'package:claim_investigation/screen/pdfView_screen.dart';
import 'package:claim_investigation/screen/profile_screen.dart';
import 'package:claim_investigation/screen/tabbar_screen.dart';
import 'package:claim_investigation/widgets/video_player_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case TabBarScreen.routeName:
        {
          return MaterialPageRoute(
              builder: (_) => TabBarScreen(), settings: settings);
        }
        break;
      case HomeScreen.routeName:
        {
          return MaterialPageRoute(
              builder: (_) => HomeScreen(), settings: settings);
        }
        break;
      case ProfileScreen.routeName:
        {
          return MaterialPageRoute(
              builder: (_) => ProfileScreen(), settings: settings);
        }
        break;
      case EditProfileScreen.routeName:
        {
          return MaterialPageRoute(
              builder: (_) => EditProfileScreen(), settings: settings);
        }
        break;
      case CaseListScreen.routeName:
        {
          return MaterialPageRoute(
              builder: (_) => CaseListScreen(), settings: settings);
        }
        break;
      case CaseDetailsScreen.routeName:
        {
          return MaterialPageRoute(
              builder: (_) => CaseDetailsScreen(), settings: settings);
        }
        break;
      case ForgotPasswordScreen.routeName:
        {
          return MaterialPageRoute(
            builder: (_) => ForgotPasswordScreen(),
            settings: settings,
          );
        }
        break;
      case ChangePasswordScreen.routeName:
        {
          return MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(), settings: settings);
        }
        break;
      case VideoPlayerScreen.routeName:
        {
          return MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(),
            settings: settings,
          );
        }
      case PDFViewerCachedFromUrl.routeName:
        {
          return MaterialPageRoute(
            builder: (_) => PDFViewerCachedFromUrl(),
            settings: settings,
          );
        }
        break;
      case FullImageViewScreen.routeName:
        {
          return MaterialPageRoute(
            builder: (_) => FullImageViewScreen(),
            settings: settings,
            fullscreenDialog: true
          );
        }
        break;
      case PIVFormsScreen.routeName:
        {
          return MaterialPageRoute(
              builder: (_) => PIVFormsScreen(),
              settings: settings,
              fullscreenDialog: true
          );
        }
        break;
      case PIVOthersForm.routeName:
        {
          return MaterialPageRoute(
              builder: (_) => PIVOthersForm(),
              settings: settings,
              fullscreenDialog: true
          );
        }
        break;
      case OtpScreen.routeName:
        {
          return MaterialPageRoute(
              builder: (_) => OtpScreen(),
              settings: settings,
          );
        }
        break;
      default:
        {
          return MaterialPageRoute(
              builder: (_) => LoginScreen(), settings: settings);
        }
    }
  }
}
