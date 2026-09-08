import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'privacy_policy_page.dart';
import 'license_page.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const SettingsPage({Key? key, required this.userData, required this.token})
      : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canUseFaceId = false;
  bool _useFaceId = false;

  static const String _appVersion = '1.0.0 (1)';
  static const String _developerName = 'Bakhrom Narzullaev';
  static const String _telegramHandle = '@bnutss';
  static const String _telegramUrl = 'https://t.me/bnutss';

  // Цвета Hikvision
  final Color hikRed = Color(0xFFE31E24);
  final Color visionGray = Color(0xFF707070);
  final Color darkGray = Color(0xFF333333);
  final Color lightGray = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _loadFaceIdState();
  }

  Future<void> _loadFaceIdState() async {
    bool canCheck = false;
    try {
      canCheck = await _auth.canCheckBiometrics;
    } catch (_) {
      canCheck = false;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _canUseFaceId = canCheck;
      _useFaceId = prefs.getBool('useBiometrics') ?? false;
    });
  }

  Future<void> _toggleFaceId(bool value) async {
    if (value) {
      bool authenticated = false;
      try {
        authenticated = await _auth.authenticate(
          localizedReason: 'Подтвердите включение входа по Face ID',
          options: const AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
      } catch (_) {
        authenticated = false;
      }
      if (!authenticated) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useBiometrics', value);
    if (!mounted) return;
    setState(() => _useFaceId = value);
  }

  String get _displayName {
    final firstName = (widget.userData['first_name'] as String?)?.trim();
    final lastName = (widget.userData['last_name'] as String?)?.trim();
    final fullName = [firstName, lastName]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty) return fullName;
    return (widget.userData['username'] as String?)?.trim() ?? 'Пользователь';
  }

  Future<void> _openTelegram() async {
    final uri = Uri.parse(_telegramUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AdaptiveScaffold(
        useHeroBackButton: false,
        appBar: AdaptiveAppBar(
          useNativeToolbar: true,
          title: 'Настройки',
        ),
        body: Container(
          color: Colors.grey[100],
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              minimum: EdgeInsets.only(
                bottom: PlatformInfo.isIOS26OrHigher() ? 90.0 : 0.0,
              ),
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
                        icon: Icons.face_retouching_natural,
                        title: 'Вход по Face ID',
                        subtitle: _canUseFaceId
                            ? 'Использовать Face ID для входа в приложение'
                            : 'Недоступно на этом устройстве',
                        value: _useFaceId,
                        onChanged: _canUseFaceId ? _toggleFaceId : null,
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
                        icon: Icons.privacy_tip_outlined,
                        title: 'Политика конфиденциальности',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyPage(),
                            ),
                          );
                        },
                      ),
                      _buildSettingsItem(
                        context,
                        icon: Icons.description_outlined,
                        title: 'Лицензионное соглашение',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AppLicensePage(),
                            ),
                          );
                        },
                      ),
                      _buildInfoRow(
                        icon: Icons.info_outline,
                        title: 'Версия',
                        value: _appVersion,
                      ),
                      _buildSettingsItem(
                        context,
                        icon: Icons.telegram,
                        iconColor: const Color(0xFF29A9EA),
                        title: 'Разработчик',
                        subtitle: '$_developerName · $_telegramHandle',
                        onTap: _openTelegram,
                      ),
                    ],
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
          ),
        ),
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
                  _displayName.substring(0, 1).toUpperCase(),
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
                    _displayName,
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
      Color? iconColor,
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
              color: (iconColor ?? hikRed).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? hikRed, size: 22),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
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
        trailing: Text(
          value,
          style: GoogleFonts.montserrat(
            color: visionGray,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSettingsItem(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      required bool value,
      required ValueChanged<bool>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (onChanged == null ? visionGray : hikRed).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: onChanged == null ? visionGray : hikRed, size: 22),
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
        trailing: AdaptiveSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: hikRed,
        ),
      ),
    );
  }
}
