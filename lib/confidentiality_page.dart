import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfidentialityPage extends StatefulWidget {
  @override
  _ConfidentialityPageState createState() => _ConfidentialityPageState();
}

class _ConfidentialityPageState extends State<ConfidentialityPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isAuthenticated = false;
  bool _useBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadBiometricPreference();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    List<BiometricType> availableBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
      availableBiometrics = await auth.getAvailableBiometrics();
      print("Available biometrics: $availableBiometrics");
    } catch (e) {
      canCheckBiometrics = false;
      availableBiometrics = <BiometricType>[];
      print("Error checking biometrics: $e");
    }
    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _loadBiometricPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? useBiometrics = prefs.getBool('useBiometrics');
    setState(() {
      _useBiometrics = useBiometrics ?? false;
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access confidentiality settings',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      print("Authentication successful");
    } catch (e) {
      authenticated = false;
      print("Authentication error: $e");
    }
    if (!mounted) return;

    setState(() {
      _isAuthenticated = authenticated;
    });
  }

  Future<void> _toggleBiometricPreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _useBiometrics = value;
    });
    await prefs.setBool('useBiometrics', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Конфиденциальность', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey, Colors.red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Center(
        child: _isAuthenticated
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 100, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'Настройки конфиденциальности',
                style: TextStyle(fontSize: 22, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              ListTile(
                leading: Icon(Icons.fingerprint, color: Colors.red),
                title: Text(
                  'Использовать биометрическую аутентификацию',
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
                trailing: Switch(
                  value: _useBiometrics,
                  onChanged: _canCheckBiometrics ? _toggleBiometricPreference : null,
                  activeColor: Colors.red,
                ),
              ),
            ],
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.lock_outline, size: 100, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'Пожалуйста, пройдите биометрическую аутентификацию для доступа к настройкам конфиденциальности.',
                style: TextStyle(fontSize: 18, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: Icon(Icons.fingerprint),
                label: Text('Аутентификация'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontSize: 16),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
