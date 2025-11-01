import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'detail_notifikasi.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> notifications = [];
  bool isSelectionMode = false;
  Set<int> selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final loaded = await NotificationService.getNotifications();
    setState(() {
      notifications = loaded;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        selectedIndices.clear();
      }
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (selectedIndices.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus ${selectedIndices.length} notifikasi yang dipilih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService.removeNotifications(selectedIndices.toList());
      await _loadNotifications();
      setState(() {
        selectedIndices.clear();
        isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedIndices.length} notifikasi dihapus')),
      );
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus Semua'),
        content: const Text('Hapus semua notifikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService.clearNotifications();
      await _loadNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua notifikasi dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/image/logo.png', // ganti sesuai logo kamu
              height: 40,
            ),
            const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox( height: 10),
          // Action buttons
          if (notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _toggleSelectionMode,
                    icon: Icon(isSelectionMode ? Icons.cancel : Icons.check_box),
                    label: Text(isSelectionMode ? 'Batal' : 'Pilih'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                  if (isSelectionMode && selectedIndices.isNotEmpty)
                    TextButton.icon(
                      onPressed: _deleteSelected,
                      icon: const Icon(Icons.delete),
                      label: Text('Hapus (${selectedIndices.length})'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _deleteAll,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Hapus Semua'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ),
          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text('Tidak ada notifikasi'))
                : ListView.builder(
                    itemCount: notifications.length,
                    padding: const EdgeInsets.all(10),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          await NotificationService.removeNotification(index);
                          await _loadNotifications();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.title} dihapus'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: BorderRadius.circular(15),
                            border: isSelectionMode && selectedIndices.contains(index)
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelectionMode)
                                  Checkbox(
                                    value: selectedIndices.contains(index),
                                    onChanged: (value) => _toggleSelection(index),
                                    activeColor: Colors.blue,
                                  ),
                                Icon(
                                  item.icon,
                                  color: item.textColor,
                                ),
                              ],
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.poppins(
                                    color: item.textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  TimeFormatter.formatRelativeTime(item.timestamp),
                                  style: GoogleFonts.poppins(
                                    color: item.textColor.withOpacity(0.6),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              item.subtitle,
                              style: GoogleFonts.poppins(
                                color: item.textColor.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            onTap: isSelectionMode
                                ? () => _toggleSelection(index)
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NotificationDetailPage(
                                          title: item.title,
                                          subtitle: item.subtitle,
                                          icon: item.icon,
                                          color: item.color,
                                          timestamp: item.timestamp,
                                        ),
                                      ),
                                    );
                                  },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
