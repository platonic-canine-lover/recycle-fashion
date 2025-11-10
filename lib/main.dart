import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';   // <-- added for Clipboard
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RecycleFashionApp());
}

class RecycleFashionApp extends StatelessWidget {
  const RecycleFashionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecycleFashion',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/* ---------- HomeScreen ---------- */
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double points = 0.0;
  List<String> vouchers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      points = prefs.getDouble('points') ?? 0.0;
      vouchers = prefs.getStringList('vouchers') ?? [];
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('points', points);
    await prefs.setStringList('vouchers', vouchers);
  }

  void _addPoints(double newPoints) {
    setState(() {
      points += newPoints;
      while (points >= 100) {
        points -= 100;
        final voucherCode =
            'RF-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';
        vouchers.insert(0, voucherCode);
      }
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RecycleFashion - Earn Vouchers'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.recycling, size: 60, color: Colors.green),
                    const SizedBox(height: 12),
                    Text(
                      'Your Points: ${points.toStringAsFixed(1)}',
                      style:
                          const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('100 points = £10 voucher'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Your Vouchers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: vouchers.isEmpty
                  ? const Center(
                      child: Text('No vouchers yet. Recycle clothes to earn!'))
                  : ListView.builder(
                      itemCount: vouchers.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.card_giftcard,
                                color: Colors.green),
                            title: Text(vouchers[index]),
                            subtitle: const Text('£10 off at partner stores'),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: vouchers[index]));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Voucher code copied!')),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubmitScreen(onApproved: (weight) {
                _addPoints(weight * 10);
              }),
            ),
          ).then((_) => setState(() {}));
        },
        label: const Text('Recycle Clothes'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green[700],
      ),
    );
  }
}

/* ---------- SubmitScreen ---------- */
class SubmitScreen extends StatefulWidget {
  final Function(double weight) onApproved;
  const SubmitScreen({super.key, required this.onApproved});

  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked =
        await _picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  void _submit() {
    if (_image == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please add a photo')));
      return;
    }
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter weight')));
      return;
    }
    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid weight')));
      return;
    }

    // Demo auto-approval
    widget.onApproved(weight);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Success! $weight kg approved. You earned ${(weight * 10).toStringAsFixed(1)} points!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Clothes for Recycling')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _image == null
                  ? const Text('No photo yet', style: TextStyle(fontSize: 18))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!,
                          height: 300, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'e.g. 2.5',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. 3 cotton t-shirts, 2 jeans',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Submit for Approval',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            const Text(
              '* In the real app, an admin (or AI) reviews the photo & weight. '
              'Approved clothes earn 10 points per kg. 100 points = £10 voucher.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
