import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Log Notifikasi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const NotificationHomeScreen(),
    );
  }
}

// --- MODEL DATA ---
class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String? image;
  final String? url;
  final String target;
  final DateTime receivedAt;

  NotificationModel({
    required this.id, required this.title, required this.body, 
    this.image, this.url, required this.target, required this.receivedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No Title',
      body: json['body'] ?? 'No Body',
      image: json['image'],
      url: json['url'],
      target: json['target'] ?? 'all',
      receivedAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

// --- HALAMAN UTAMA (Hanya Notifikasi via Icon) ---
class NotificationHomeScreen extends StatefulWidget {
  const NotificationHomeScreen({super.key});

  @override
  State<NotificationHomeScreen> createState() => _NotificationHomeScreenState();
}

class _NotificationHomeScreenState extends State<NotificationHomeScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMsg;

  final String baseUrl = "http://172.16.186.100:8000/api";

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/notification-histories"),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        dynamic rawData = decodedData['data'];
        List<dynamic> listData = (rawData is Map && rawData.containsKey('data')) ? rawData['data'] : (rawData is List ? rawData : []);
        
        setState(() {
          _notifications = listData.map((json) => NotificationModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _errorMsg = "Gagal memuat log"; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _errorMsg = "Kesalahan koneksi"; _isLoading = false; });
    }
  }

  // Fungsi untuk menampilkan riwayat log di Bottom Sheet
  void _showNotificationLogs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Riwayat Notifikasi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _notifications.isEmpty 
                      ? const Center(child: Text("Tidak ada notifikasi"))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.notifications_none)),
                              title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(notif.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                              onTap: () {
                                Navigator.pop(context); // Tutup sheet
                                Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationDetailScreen(notification: notif)));
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Notifikasi"),
        actions: [
          // IKON LONCENG DI APPBAR
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, size: 28),
                onPressed: _showNotificationLogs,
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('${_notifications.length}', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_active_outlined, size: 100, color: Colors.indigo.withOpacity(0.3)),
            const SizedBox(height: 20),
            const Text("Klik ikon lonceng untuk melihat riwayat log", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- DETAIL SCREEN ---
class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;
  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Notifikasi"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Waktu: ${notification.receivedAt.toString()}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const Divider(height: 40),
            const Text("Isi Notifikasi:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            Text(notification.body, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 30),
            if (notification.url != null && notification.url!.isNotEmpty) ...[
              const Text("Link URL:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 8),
              SelectableText(notification.url!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
              const SizedBox(height: 20),
            ],
            if (notification.image != null) Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(notification.image!, errorBuilder: (c, e, s) => const SizedBox.shrink()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
