import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  final Color hikRed = const Color(0xFFE31E24);
  final Color visionGray = const Color(0xFF707070);
  final Color darkGray = const Color(0xFF333333);

  static const _sections = <_PolicySection>[
    _PolicySection(
      title: '1. Общие положения',
      body:
          'Настоящая Политика конфиденциальности определяет порядок обработки и защиты '
          'персональных данных пользователей мобильного приложения RHiK, используемого '
          'сотрудниками компании для работы с заказами, клиентами и внутренней отчётностью по '
          'продаже и обслуживанию оборудования видеонаблюдения брендов HIKVISION, Dahua '
          'Security и EZVIZ.',
    ),
    _PolicySection(
      title: '2. Какие данные обрабатываются',
      body:
          'Приложение обрабатывает учётные данные пользователя (логин, ФИО, e-mail), данные '
          'о заказах, клиентах и продажах, а также технические данные, необходимые для '
          'авторизации и работы с сервером компании.',
    ),
    _PolicySection(
      title: '3. Цели обработки данных',
      body:
          'Данные используются исключительно для авторизации в приложении, оформления и '
          'учёта заказов, формирования отчётов по итогам дня и обеспечения корректной работы '
          'функций приложения.',
    ),
    _PolicySection(
      title: '4. Хранение и защита данных',
      body:
          'Данные передаются по защищённому каналу и хранятся на сервере компании. Доступ к '
          'данным имеют только авторизованные сотрудники в рамках служебных обязанностей.',
    ),
    _PolicySection(
      title: '5. Права пользователя',
      body:
          'Пользователь вправе запросить информацию об обрабатываемых данных, а также их '
          'исправление или удаление, обратившись к администратору системы.',
    ),
    _PolicySection(
      title: '6. Изменения политики',
      body:
          'Компания оставляет за собой право вносить изменения в настоящую политику. '
          'Актуальная версия всегда доступна в разделе «Настройки» приложения.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AdaptiveScaffold(
        appBar: AdaptiveAppBar(
          title: 'Политика конфиденциальности',
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

class _PolicySection {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});
}
