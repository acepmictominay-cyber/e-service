import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditBirthdayPage extends StatefulWidget {
  const EditBirthdayPage({super.key});

  @override
  State<EditBirthdayPage> createState() => _EditBirthdayPageState();
}

class _EditBirthdayPageState extends State<EditBirthdayPage> {
  final TextEditingController birthdayController = TextEditingController(text: '01 - Juli - 2004');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // === APP BAR ===
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: const [
          Icon(Icons.chat_bubble_outline, color: Colors.white),
          SizedBox(width: 12),
        ],
      ),

      // === BODY ===
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tombol kembali
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Kembali",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // === DATE PICKER FIELD ===
            TextField(
              controller: birthdayController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Tanggal Lahir',
                labelStyle: const TextStyle(color: Colors.black54),
                suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1),
                ),
              ),
              onTap: _selectDate,
            ),

            const Spacer(),

            // Tombol Simpan
            Center(
              child: SizedBox(
                width: 180,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Tanggal lahir disimpan: ${birthdayController.text}")),
                    );
                  },
                  child: const Text(
                    "Simpan",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        birthdayController.text = DateFormat('dd - MMMM - yyyy').format(pickedDate);
      });
    }
  }
}
