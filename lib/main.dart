import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Telephony telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // Yêu cầu quyền truy cập
  void _requestPermissions() async {
    await [
      Permission.contacts,
      Permission.sms,
    ].request();
  }

  // Mở trang danh bạ
  Future<List<Contact>> _getContacts() async {
    if (await Permission.contacts.isGranted) {
      Iterable<Contact> contacts = await ContactsService.getContacts();
      return contacts.toList();
    } else {
      print('Quyền truy cập danh bạ bị từ chối');
      return [];
    }
  }

  // Mở trang tin nhắn
  Future<List<SmsMessage>> _getMessages() async {
    if (await Permission.sms.isGranted) {
      return await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
      );
    } else {
      print('Quyền truy cập tin nhắn bị từ chối');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh bạ & Tin nhắn"),
      ),
      body: Center(
        // Center widget để căn giữa toàn bộ nội dung
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Căn giữa theo chiều dọc
          children: [
            ElevatedButton(
              onPressed: () async {
                List<SmsMessage> messages = await _getMessages();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageScreen(messages: messages),
                  ),
                );
              },
              child: Text("Xem Tin nhắn"),
            ),
            SizedBox(height: 20), // Khoảng cách giữa các nút
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ContactScreen(getContacts: _getContacts),
                  ),
                );
              },
              child: Text("Xem Danh bạ"),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  final Future<List<Contact>> Function() getContacts;

  ContactScreen({required this.getContacts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh bạ"),
      ),
      body: FutureBuilder<List<Contact>>(
        future: getContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi khi tải danh bạ"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Chưa có danh bạ"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(snapshot.data![index].displayName ?? "No Name"),
                subtitle: Text(snapshot.data![index].phones!.isNotEmpty
                    ? snapshot.data![index].phones!.first.value!
                    : "No Phone Number"),
              );
            },
          );
        },
      ),
    );
  }
}

class MessageScreen extends StatelessWidget {
  final List<SmsMessage> messages;

  MessageScreen({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tin nhắn"),
      ),
      body: messages.isEmpty
          ? Center(child: Text("Chưa có tin nhắn"))
          : ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index].address ?? "Unknown"),
                  subtitle: Text(messages[index].body ?? "No message body"),
                );
              },
            ),
    );
  }
}
