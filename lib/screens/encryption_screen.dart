import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encryption_service.dart';

class EncryptionScreen extends StatefulWidget {
  const EncryptionScreen({Key? key}) : super(key: key);

  @override
  State<EncryptionScreen> createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  final _keyController = TextEditingController();
  final _resultController = TextEditingController();
  
  String _selectedMethod = 'Caesar Cipher';
  final List<String> _methods = ['Caesar Cipher', 'Base64 XOR'];
  List<String> _savedKeys = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedKeys();
  }

  Future<void> _loadSavedKeys() async {
    final keys = await EncryptionService.getSavedKeys();
    setState(() {
      _savedKeys = keys;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enkripsi & Dekripsi'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Enkripsi/Dekripsi'),
            Tab(text: 'Kelola Kunci'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEncryptionTab(),
          _buildKeyManagementTab(),
        ],
      ),
    );
  }

  Widget _buildEncryptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Metode Enkripsi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedMethod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _methods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value!;
                        _keyController.clear();
                        _resultController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teks Input',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan teks yang akan dienkripsi/dekripsi...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedMethod == 'Caesar Cipher' ? 'Kunci (Angka)' : 'Kunci (Teks)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _generateKey,
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Generate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_savedKeys.isNotEmpty)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.key),
                              tooltip: 'Pilih kunci tersimpan',
                              onSelected: (key) async {
                                final savedKey = await EncryptionService.loadKey(key);
                                if (savedKey != null) {
                                  _keyController.text = savedKey;
                                }
                              },
                              itemBuilder: (context) {
                                return _savedKeys.map((key) {
                                  return PopupMenuItem<String>(
                                    value: key,
                                    child: Text(key),
                                  );
                                }).toList();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyController,
                    keyboardType: _selectedMethod == 'Caesar Cipher' 
                        ? TextInputType.number 
                        : TextInputType.text,
                    decoration: InputDecoration(
                      hintText: _selectedMethod == 'Caesar Cipher' 
                          ? 'Masukkan angka 1-25' 
                          : 'Masukkan kunci teks',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        tooltip: 'Simpan kunci',
                        onPressed: _saveCurrentKey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _encrypt,
                  icon: const Icon(Icons.lock),
                  label: const Text('Enkripsi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _decrypt,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Dekripsi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hasil',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _copyResult,
                        icon: const Icon(Icons.copy),
                        tooltip: 'Salin hasil',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _resultController,
                    maxLines: 4,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: 'Hasil enkripsi/dekripsi akan muncul di sini...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kunci Tersimpan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelola kunci enkripsi yang telah Anda simpan',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _savedKeys.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.key_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada kunci tersimpan',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Simpan kunci dari tab Enkripsi/Dekripsi',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _savedKeys.length,
                    itemBuilder: (context, index) {
                      final keyName = _savedKeys[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.key, color: Colors.blue),
                          title: Text(keyName),
                          subtitle: FutureBuilder<String?>(
                            future: EncryptionService.loadKey(keyName),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final key = snapshot.data!;
                                return Text(
                                  key.length > 20 ? '${key.substring(0, 20)}...' : key,
                                  style: const TextStyle(fontFamily: 'monospace'),
                                );
                              }
                              return const Text('Loading...');
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () => _copyKey(keyName),
                                tooltip: 'Salin kunci',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteKey(keyName),
                                tooltip: 'Hapus kunci',
                              ),
                            ],
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

  void _generateKey() {
    String key;
    if (_selectedMethod == 'Caesar Cipher') {
      key = EncryptionService.generateRandomNumber().toString();
    } else {
      key = EncryptionService.generateRandomKey();
    }
    
    setState(() {
      _keyController.text = key;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kunci berhasil di-generate!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _encrypt() {
    if (_textController.text.isEmpty) {
      _showMessage('Masukkan teks yang akan dienkripsi');
      return;
    }
    
    if (_keyController.text.isEmpty) {
      _showMessage('Masukkan kunci enkripsi');
      return;
    }

    String result;
    try {
      if (_selectedMethod == 'Caesar Cipher') {
        final shift = int.parse(_keyController.text);
        if (shift < 1 || shift > 25) {
          _showMessage('Kunci Caesar Cipher harus antara 1-25');
          return;
        }
        result = EncryptionService.caesarEncrypt(_textController.text, shift);
      } else {
        result = EncryptionService.base64Encrypt(_textController.text, _keyController.text);
      }
      
      setState(() {
        _resultController.text = result;
      });
      
      _showMessage('Teks berhasil dienkripsi!', isSuccess: true);
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
  }

  void _decrypt() {
    if (_textController.text.isEmpty) {
      _showMessage('Masukkan teks yang akan didekripsi');
      return;
    }
    
    if (_keyController.text.isEmpty) {
      _showMessage('Masukkan kunci dekripsi');
      return;
    }

    String result;
    try {
      if (_selectedMethod == 'Caesar Cipher') {
        final shift = int.parse(_keyController.text);
        if (shift < 1 || shift > 25) {
          _showMessage('Kunci Caesar Cipher harus antara 1-25');
          return;
        }
        result = EncryptionService.caesarDecrypt(_textController.text, shift);
      } else {
        result = EncryptionService.base64Decrypt(_textController.text, _keyController.text);
      }
      
      setState(() {
        _resultController.text = result;
      });
      
      _showMessage('Teks berhasil didekripsi!', isSuccess: true);
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
  }

  void _copyResult() {
    if (_resultController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _resultController.text));
      _showMessage('Hasil disalin ke clipboard!', isSuccess: true);
    }
  }

  Future<void> _saveCurrentKey() async {
    if (_keyController.text.isEmpty) {
      _showMessage('Tidak ada kunci untuk disimpan');
      return;
    }

    final keyName = await _showSaveKeyDialog();
    if (keyName != null && keyName.isNotEmpty) {
      await EncryptionService.saveKey(keyName, _keyController.text);
      await _loadSavedKeys();
      _showMessage('Kunci berhasil disimpan!', isSuccess: true);
    }
  }

  Future<String?> _showSaveKeyDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan Kunci'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berikan nama untuk kunci ini:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nama kunci',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyKey(String keyName) async {
    final key = await EncryptionService.loadKey(keyName);
    if (key != null) {
      Clipboard.setData(ClipboardData(text: key));
      _showMessage('Kunci disalin ke clipboard!', isSuccess: true);
    }
  }

  Future<void> _deleteKey(String keyName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kunci'),
        content: Text('Apakah Anda yakin ingin menghapus kunci "$keyName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await EncryptionService.deleteKey(keyName);
      await _loadSavedKeys();
      _showMessage('Kunci berhasil dihapus!', isSuccess: true);
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _keyController.dispose();
    _resultController.dispose();
    super.dispose();
  }
}