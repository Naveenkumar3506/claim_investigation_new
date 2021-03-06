import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/screen/home_screen.dart';
import 'package:claim_investigation/screen/profile_screen.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:flutter/material.dart';

class TabBarScreen extends BasePage {
  static const routeName = '/tabBarScreen';

  @override
  _TabBarScreenState createState() => _TabBarScreenState();
}

class _TabBarScreenState extends BaseState<TabBarScreen> {
  @override
  int _selectedIndex = 0;

  static List<Widget> _pageList = <Widget>[
    HomeScreen(),
    ProfileScreen(),
  ];

  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pageList,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
