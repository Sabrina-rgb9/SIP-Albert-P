import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'views/encrypt_view.dart';
import 'views/decrypt_view.dart';
import 'models/rsa_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encriptador RSA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _views = const [
    EncryptView(),
    DecryptView(),
  ];

Future<void> _generateTestKeys() async {
  try {
    final docs = await getApplicationDocumentsDirectory();
    
    // Mostrar diálogo de progreso
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generando claves RSA...'),
            ],
          ),
        );
      },
    );
    
    // Usar generateKeyPairSecure en lugar de generateKeyPair
    await RSAManager.generateKeyPairSecure(docs.path);
    
    if (!mounted) return;
    
    // Cerrar diálogo de progreso
    Navigator.of(context).pop();
    
    // Mostrar éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Claves generadas en:\n${docs.path}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    
    // Cerrar diálogo de progreso si está abierto
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error generando claves: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encriptador RSA'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            onPressed: _generateTestKeys,
            tooltip: 'Generar claves de prueba',
          ),
        ],
      ),
      body: _views[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lock),
            label: 'Encriptar',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_open),
            label: 'Desencriptar',
          ),
        ],
      ),
    );
  }
}