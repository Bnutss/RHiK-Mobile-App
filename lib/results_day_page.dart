import 'package:flutter/material.dart';

class ResultsDayPage extends StatelessWidget {
  const ResultsDayPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Итоги дня'),
      ),
      body: Center(
        child: Text(
          'В разработке...',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
