import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'confidentiality_page.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const SettingsPage({Key? key, required this.userData, required this.token})
      : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isUpdating = false;
  bool _isDarkMode = false;
  bool _useFingerprint = true;
  bool _notifications = true;

  // Цвета Hikvision
  final Color hikRed = Color(0xFFE31E24);
  final Color visionGray = Color(0xFF707070);
  final Color darkGray = Color(0xFF333333);
  final Color lightGray = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: hikRed,
        title: Text(
          'Настройки',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.grey[100],
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildProfileCard(),
                const SizedBox(height: 24),
                _buildSettingsSection(
                  context,
                  'Основные настройки',
                  [
                    _buildToggleSettingsItem(
                      context,
                      icon: Icons.dark_mode_outlined,
                      title: 'Темная тема',
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          _isDarkMode = value;
                        });
                      },
                    ),
                    _buildToggleSettingsItem(
                      context,
                      icon: Icons.fingerprint,
                      title: 'Вход по отпечатку',
                      value: _useFingerprint,
                      onChanged: (value) {
                        setState(() {
                          _useFingerprint = value;
                        });
                      },
                    ),
                    _buildToggleSettingsItem(
                      context,
                      icon: Icons.notifications_none_outlined,
                      title: 'Уведомления',
                      value: _notifications,
                      onChanged: (value) {
                        setState(() {
                          _notifications = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsSection(
                  context,
                  'Учетная запись',
                  [
                    _buildSettingsItem(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Конфиденциальность',
                      subtitle: 'Настройки конфиденциальности',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConfidentialityPage(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.security_outlined,
                      title: 'Безопасность',
                      subtitle: 'Изменить пароль, двухфакторная аутентификация',
                      onTap: () {
                        _showComingSoonDialog();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsSection(
                  context,
                  'О приложении',
                  [
                    _buildSettingsItem(
                      context,
                      icon: Icons.info_outline,
                      title: 'Информация',
                      subtitle: 'Версия, лицензии, политика',
                      onTap: () {
                        _showComingSoonDialog();
                      },
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.help_outline,
                      title: 'Помощь',
                      subtitle: 'Часто задаваемые вопросы, поддержка',
                      onTap: () {
                        _showComingSoonDialog();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showLogoutDialog();
                    },
                    icon: Icon(Icons.logout, color: Colors.white),
                    label: Text(
                      'Выйти из аккаунта',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hikRed,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'XVAN RUSLAN PRODUCTION',
                    style: GoogleFonts.montserrat(
                      color: visionGray.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isUpdating)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  color: hikRed,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hikRed,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  widget.userData['username']?.substring(0, 1).toUpperCase() ??
                      'U',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userData['username'] ?? 'Пользователь',
                    style: GoogleFonts.montserrat(
                      color: darkGray,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.userData['email'] ?? 'email@example.com',
                    style: GoogleFonts.montserrat(
                      color: visionGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: visionGray,
              ),
              onPressed: () {
                _showComingSoonDialog();
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSettingsSection(
      BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 10.0),
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: visionGray,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSettingsItem(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hikRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: hikRed, size: 22),
          ),
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              color: darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    color: visionGray,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing:
              Icon(Icons.chevron_right, color: visionGray.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildToggleSettingsItem(BuildContext context,
      {required IconData icon,
      required String title,
      required bool value,
      required Function(bool) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hikRed.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: hikRed, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            color: darkGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: hikRed,
          activeTrackColor: hikRed.withOpacity(0.5),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: visionGray.withOpacity(0.3),
        ),
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Скоро будет доступно',
            style: GoogleFonts.montserrat(
              color: hikRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Эта функция находится в разработке и будет доступна в ближайшем обновлении.',
            style: GoogleFonts.montserrat(
              color: darkGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Понятно',
                style: GoogleFonts.montserrat(
                  color: hikRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Выйти из аккаунта',
            style: GoogleFonts.montserrat(
              color: hikRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите выйти из своего аккаунта?',
            style: GoogleFonts.montserrat(
              color: darkGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Отмена',
                style: GoogleFonts.montserrat(
                  color: visionGray,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: hikRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Выйти',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
