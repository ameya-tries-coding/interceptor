import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../payments/payment_details_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact>? _contacts;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      setState(() => _permissionDenied = true);
    } else {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() => _contacts = contacts);
    }
  }

  void _onContactSelected(Contact contact) {
    if (contact.phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number found for this contact')),
      );
      return;
    }

    String rawNumber = contact.phones.first.number;
    String sanitizedNumber = rawNumber.replaceAll(RegExp(r'\D'), '');
    
    if (sanitizedNumber.startsWith('91') && sanitizedNumber.length == 12) {
      sanitizedNumber = sanitizedNumber.substring(2);
    } else if (sanitizedNumber.length > 10) {
       sanitizedNumber = sanitizedNumber.substring(sanitizedNumber.length - 10);
    }

    final String vpa = '$sanitizedNumber@paytm';
    final String payeeName = contact.displayName;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentDetailsScreen(
          payeeAddress: vpa,
          payeeName: payeeName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contacts')),
        body: const Center(child: Text('Permission denied to access contacts.')),
      );
    }
    if (_contacts == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contacts')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final contactsWithPhones = _contacts!.where((c) => c.phones.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        itemCount: contactsWithPhones.length,
        itemBuilder: (context, index) {
          final contact = contactsWithPhones[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            title: Text(contact.displayName),
            subtitle: Text(contact.phones.first.number),
            onTap: () => _onContactSelected(contact),
          );
        },
      ),
    );
  }
}
