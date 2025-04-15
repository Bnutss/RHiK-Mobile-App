import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditOrderPage extends StatefulWidget {
  final int orderId;

  const EditOrderPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _EditOrderPageState createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _vatController = TextEditingController();
  final _additionalExpensesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    _loadOrder();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _vatController.dispose();
    _additionalExpensesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _showSnackBar('Токен авторизации не найден', true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
            'https://rhik.pythonanywhere.com/sales/api/orders/${widget.orderId}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> orderData =
            json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          _clientController.text = orderData['client'] ?? '';
          _vatController.text = (orderData['vat'] ?? 0).toString();
          _additionalExpensesController.text =
              (orderData['additional_expenses'] ?? 0).toString();
          _isLoading = false;
        });
      } else {
        _showSnackBar(
            'Ошибка загрузки данных заказа: ${response.statusCode}', true);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Не удалось загрузить заказ: $e', true);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');

        if (token == null) {
          _showSnackBar('Токен авторизации не найден', true);
          setState(() {
            _isSaving = false;
          });
          return;
        }

        final response = await http.put(
          Uri.parse(
              'https://rhik.pythonanywhere.com/sales/api/orders/${widget.orderId}/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'client': _clientController.text,
            'vat': double.tryParse(_vatController.text) ?? 0.0,
            'additional_expenses':
                double.tryParse(_additionalExpensesController.text) ?? 0.0,
          }),
        );

        if (response.statusCode == 200) {
          _showSnackBar('Заказ успешно обновлен!', false);
          Navigator.pop(context, true);
        } else {
          _showSnackBar(
              'Ошибка обновления заказа: ${response.statusCode}', true);
          setState(() {
            _isSaving = false;
          });
        }
      } catch (e) {
        _showSnackBar('Не удалось обновить заказ: $e', true);
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: isError ? Colors.red.shade700 : Color(0xFF303F9F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        action: isError
            ? null
            : SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Редактировать заказ',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // Темно-синий
              Color(0xFF3949AB), // Индиго
              Color(0xFF303F9F), // Синий
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF4081)),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Заголовок страницы
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    color: Color(0xFFFF4081),
                                    size: 30,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Обновление данных заказа #${widget.orderId}',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: -0.1, end: 0),

                          SizedBox(height: 30),

                          // Форма редактирования
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildFormField(
                                  controller: _clientController,
                                  label: 'Клиент',
                                  hint: 'Введите имя клиента',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Введите имя клиента';
                                    }
                                    return null;
                                  },
                                  delay: 100,
                                ),

                                SizedBox(height: 20),

                                _buildFormField(
                                  controller: _vatController,
                                  label: 'НДС (%)',
                                  hint: 'Введите процент НДС',
                                  icon: Icons.attach_money,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Введите процент НДС';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Введите корректное число';
                                    }
                                    return null;
                                  },
                                  delay: 200,
                                ),

                                SizedBox(height: 20),

                                _buildFormField(
                                  controller: _additionalExpensesController,
                                  label: 'Прочие расходы (%)',
                                  hint:
                                      'Введите процент дополнительных расходов',
                                  icon: Icons.account_balance_wallet_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Введите процент дополнительных расходов';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Введите корректное число';
                                    }
                                    return null;
                                  },
                                  delay: 300,
                                ),

                                SizedBox(height: 40),

                                // Кнопка сохранения
                                Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFF4081), // Розовый
                                        Color(0xFFF50057), // Малиновый
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color(0xFFFF4081).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _isSaving ? null : _submitOrder,
                                    icon: _isSaving
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Icon(Icons.save_outlined,
                                            color: Colors.white),
                                    label: Text(
                                      _isSaving
                                          ? 'Сохранение...'
                                          : 'Сохранить изменения',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: 400.ms)
                                    .slideY(begin: 0.1, end: 0),

                                SizedBox(height: 20),

                                // Кнопка отмены
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: Icon(Icons.cancel_outlined,
                                      color: Colors.white70),
                                  label: Text(
                                    'Отменить',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    side: BorderSide(color: Colors.white30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: 500.ms),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int delay = 0,
  }) {
    return Animate(
      effects: [
        FadeEffect(duration: 400.ms, delay: delay.ms),
        SlideEffect(
            begin: Offset(0, 0.1),
            end: Offset.zero,
            duration: 400.ms,
            delay: delay.ms)
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: Icon(icon, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Color(0xFFFF4081)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              errorStyle: TextStyle(color: Colors.red.shade300),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            ),
            keyboardType: keyboardType,
            validator: validator,
          ),
        ],
      ),
    );
  }
}
