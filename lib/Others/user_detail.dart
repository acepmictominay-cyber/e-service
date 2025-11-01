import 'package:flutter/material.dart';

class UserDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const UserDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail User'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nama: ${data['name']}", style: const TextStyle(fontSize: 18)),
                Text("ID: ${data['id']}", style: const TextStyle(fontSize: 16)),
                Text("Poin: ${data['points']}", style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
