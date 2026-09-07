import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class AppLicensePage extends StatelessWidget {
  const AppLicensePage({Key? key}) : super(key: key);

  final Color hikRed = const Color(0xFFE31E24);
  final Color visionGray = const Color(0xFF707070);
  final Color darkGray = const Color(0xFF333333);

  static const _sections = <_LicenseSection>[
    _LicenseSection(
      title: '1. Предмет соглашения',
      body:
          'Настоящее лицензионное соглашение регулирует условия использования мобильного '
          'приложения RHiK, предназначенного для внутреннего использования сотрудниками '
          'компании при продаже и обслуживании оборудования видеонаблюдения брендов '
          'HIKVISION, Dahua Security и EZVIZ.',
    ),
    _LicenseSection(
      title: '2. Условия использования',
      body:
          'Приложение предоставляется для служебного использования и может применяться только '
          'авторизованными сотрудниками компании в рамках выполнения трудовых обязанностей.',
    ),
    _LicenseSection(
      title: '3. Ограничения',
      body:
          'Запрещается копирование, распространение, декомпиляция или иное использование '
          'приложения и его исходного кода без письменного разрешения правообладателя.',
    ),
    _LicenseSection(
      title: '4. Интеллектуальная собственность',
      body:
          'Все права на приложение, включая программный код, дизайн и товарный знак RHiK, '
          'принадлежат правообладателю и защищены законодательством об интеллектуальной '
          'собственности. Товарные знаки HIKVISION, Dahua Security и EZVIZ принадлежат их '
          'правообладателям и упоминаются исключительно в информационных целях.',
    ),
    _LicenseSection(
      title: '5. Ответственность',
      body:
          'Правообладатель не несёт ответственности за убытки, возникшие в результате '
          'неправомерного использования приложения или нарушения условий настоящего '
          'соглашения.',
    ),
    _LicenseSection(
      title: '6. Прекращение действия',
      body:
          'Доступ к приложению может быть прекращён при увольнении сотрудника или нарушении '
          'условий настоящего соглашения.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AdaptiveScaffold(
        appBar: AdaptiveAppBar(
          title: 'Лицензионное соглашение',
          useNativeToolbar: true,
          leading: SizedBox(
            width: 38,
            height: 38,
            child: AdaptiveButton.sfSymbol(
              onPressed: () => Navigator.of(context).pop(),
              sfSymbol: const SFSymbol('chevron.left', size: 20),
              useSmoothRectangleBorder: false,
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.grey[100]!, Colors.grey[200]!],
                ),
              ),
            ),
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hikRed.withOpacity(0.05),
                ),
              ),
            ),
            SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: hikRed,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          section.body,
                          style: GoogleFonts.montserrat(
                            fontSize: 13.5,
                            height: 1.5,
                            color: darkGray,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LicenseSection {
  final String title;
  final String body;

  const _LicenseSection({required this.title, required this.body});
}
