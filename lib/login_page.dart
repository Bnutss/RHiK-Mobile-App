import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'menu_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _checkBiometricPreference();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } catch (e) {
      canCheckBiometrics = false;
    }
    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  Future<void> _checkBiometricPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? useBiometrics = prefs.getBool('useBiometrics');

    if (useBiometrics ?? false) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to login',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      authenticated = false;
    }
    if (!mounted) return;

    if (authenticated) {
      _loginWithBiometrics();
    } else {
      _showError('Биометрическая аутентификация не удалась');
    }
  }

  Future<void> _loginWithBiometrics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      await _fetchUserData(token);
    } else {
      _showError('Токен не найден');
    }
  }

  Future<void> _fetchUserData(String token) async {
    final userResponse = await http.get(
      Uri.parse('https://rhik.pythonanywhere.com/api/user/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (userResponse.statusCode == 200) {
      final userData = json.decode(utf8.decode(userResponse.bodyBytes));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MenuPage(userData: userData, token: token)),
      );
    } else if (userResponse.statusCode == 401) {
      await _refreshToken();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final newToken = prefs.getString('access_token');
      if (newToken != null) {
        await _fetchUserData(newToken);
      } else {
        _showError('Не удалось обновить токен');
      }
    } else {
      _showError('Не удалось получить данные пользователя');
    }
  }

  Future<void> _refreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken != null) {
      try {
        final response = await http.post(
          Uri.parse('https://rhik.pythonanywhere.com/api/token/refresh/'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'refresh': refreshToken,
          }),
        );

        if (response.statusCode == 200) {
          final refreshData = json.decode(utf8.decode(response.bodyBytes));
          final newAccessToken = refreshData['access'];
          await prefs.setString('access_token', newAccessToken);
        } else {
          _showError('Не удалось обновить токен');
        }
      } catch (e) {
        _showError('Ошибка сети: $e');
      }
    } else {
      _showError('Токен обновления не найден');
    }
  }

  Future<void> _login() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('https://rhik.pythonanywhere.com/api/login/'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final loginData = json.decode(utf8.decode(response.bodyBytes));
        final accessToken = loginData['access'];
        final refreshToken = loginData['refresh'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);

        await _fetchUserData(accessToken);
      } else {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final String errorMessage = responseData['detail'] ?? 'Ошибка при входе';
        _showError(errorMessage);
      }
    } catch (e) {
      _showError('Ошибка сети: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey, Colors.red],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 3),
                  Image.asset('assets/icon/logo.png', width: 300),
                  SizedBox(height: 10),
                  SizedBox(height: 10),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Логин',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      'Войти',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
