import 'package:flutter/material.dart';
import 'info_page.dart';
import 'results_day_page.dart';
import 'orders_page.dart';
import 'passwords_page.dart';

class MenuPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String token;

  const MenuPage({Key? key, required this.userData, required this.token}) : super(key: key);

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage(userData: userData, token: token)),
    );
  }

  void _openPartyStatusPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrdersPage()),
    );
  }

  void _openMonitoringPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultsDayPage()),
    );
  }

  void _openPasswordsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PasswordsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Главное меню',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey, Colors.red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _openSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey, Colors.red],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: () => _openPartyStatusPage(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Заказы',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    elevation: 5,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _openMonitoringPage(context),
                  icon: const Icon(Icons.restore_outlined, color: Colors.white),
                  label: const Text(
                    'Итоги дня',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    elevation: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPasswordsPage(context),
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.vpn_key, color: Colors.white),
      ),
    );
  }
}