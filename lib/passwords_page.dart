import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PasswordsPage extends StatefulWidget {
  const PasswordsPage({Key? key}) : super(key: key);

  @override
  State<PasswordsPage> createState() => _PasswordsPageState();
}

class _PasswordsPageState extends State<PasswordsPage> {
  List<dynamic> passwords = [];
  List<dynamic> filteredPasswords = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPasswords();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> fetchPasswords() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Токен не найден. Пожалуйста, войдите заново.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://rhik.pythonanywhere.com/sales/api/passwords/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          passwords = json.decode(response.body);
          filteredPasswords = passwords;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка подключения к серверу.')),
      );
    }
  }

  void filterPasswords(String query) {
    setState(() {
      filteredPasswords = passwords.where((password) {
        final organizationName =
            password['organization_name'].toString().toLowerCase();
        return organizationName.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> addOrEditPassword({
    int? id,
    required String organizationName,
    required String nvrPassword,
    required String cameraPassword,
  }) async {
    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Токен не найден. Пожалуйста, войдите заново.')),
      );
      return;
    }

    try {
      final response = id == null
          ? await http.post(
              Uri.parse('https://rhik.pythonanywhere.com/sales/api/passwords/'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'organization_name': organizationName,
                'nvr_password': nvrPassword,
                'camera_password': cameraPassword,
              }),
            )
          : await http.put(
              Uri.parse(
                  'https://rhik.pythonanywhere.com/sales/api/passwords/$id/'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'organization_name': organizationName,
                'nvr_password': nvrPassword,
                'camera_password': cameraPassword,
              }),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchPasswords();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(id == null
                ? 'Запись успешно добавлена'
                : 'Запись успешно обновлена'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении записи')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка подключения к серверу.')),
      );
    }
  }

  void _showAddOrEditPasswordDialog({dynamic password}) {
    final TextEditingController organizationController =
        TextEditingController(text: password?['organization_name'] ?? '');
    final TextEditingController nvrController =
        TextEditingController(text: password?['nvr_password'] ?? '');
    final TextEditingController cameraController =
        TextEditingController(text: password?['camera_password'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              password == null ? 'Добавить запись' : 'Редактировать запись'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: organizationController,
                decoration: const InputDecoration(
                  labelText: 'Название организации',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              TextField(
                controller: nvrController,
                decoration: const InputDecoration(
                  labelText: 'Пароль NVR',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              TextField(
                controller: cameraController,
                decoration: const InputDecoration(
                  labelText: 'Пароль камеры',
                  prefixIcon: Icon(Icons.videocam),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                addOrEditPassword(
                  id: password?['id'],
                  organizationName: organizationController.text.trim(),
                  nvrPassword: nvrController.text.trim(),
                  cameraPassword: cameraController.text.trim(),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deletePassword(int id) async {
    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Токен не найден. Пожалуйста, войдите заново.')),
      );
      return;
    }
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Подтверждение удаления'),
          content: const Text('Вы уверены, что хотите удалить эту запись?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (!confirmDelete) {
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('https://rhik.pythonanywhere.com/sales/api/passwords/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          passwords.removeWhere((password) => password['id'] == id);
          filteredPasswords.removeWhere((password) => password['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запись успешно удалена'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка подключения к серверу.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.business, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Пароли (${filteredPasswords.length})',
              style: const TextStyle(color: Colors.white),
            ),
          ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchPasswords,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск по организации',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: filterPasswords,
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredPasswords.isEmpty
                      ? const Center(
                          child: Text(
                            'Нет доступных паролей',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredPasswords.length,
                          itemBuilder: (context, index) {
                            final password = filteredPasswords[index];
                            return Dismissible(
                              key: ValueKey(password['id']),
                              background: Container(
                                color: Colors.green,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                child:
                                    const Icon(Icons.edit, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                if (direction == DismissDirection.startToEnd) {
                                  _showAddOrEditPasswordDialog(
                                      password: password);
                                } else if (direction ==
                                    DismissDirection.endToStart) {
                                  deletePassword(password['id']);
                                }
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: ListTile(
                                  leading: const Icon(Icons.vpn_key,
                                      color: Colors.blue),
                                  title: Text(
                                    password['organization_name'] ??
                                        'Без названия',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.lock,
                                              size: 16, color: Colors.green),
                                          const SizedBox(width: 4),
                                          Text(
                                              'Пароль NVR: ${password['nvr_password']}'),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.videocam,
                                              size: 16, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Text(
                                              'Пароль камеры: ${password['camera_password']}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddOrEditPasswordDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
