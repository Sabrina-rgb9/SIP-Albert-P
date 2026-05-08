import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../models/rsa_manager.dart';
import '../widgets/file_selector.dart';
import '../widgets/file_selector.dart' show FileSaver;

class DecryptView extends StatefulWidget {
  const DecryptView({super.key});

  @override
  State<DecryptView> createState() => _DecryptViewState();
}

class _DecryptViewState extends State<DecryptView> {
  String? _privateKeyPath;
  String? _inputFilePath;
  String? _outputFilePath;
  bool _isDecrypting = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadDefaultPrivateKey();
  }

Future<void> _loadDefaultPrivateKey() async {
  final defaultKey = await RSAManager.getDefaultPrivateKeyPath();
  if (defaultKey != null) {
    setState(() {
      _privateKeyPath = defaultKey;
    });
    print('🔑 Clave por defecto cargada: $defaultKey');
  } else {
    print('⚠️ No se encontró clave por defecto');
  }
}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Desencriptar archivo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          FileSelector(
            label: 'Clave privada RSA',
            value: _privateKeyPath != null
                ? path.basename(_privateKeyPath!)
                : null,
            onSelect: _selectPrivateKey,
            onClear: _clearPrivateKey,
          ),
          const SizedBox(height: 8),
          // CORRECCIÓN: Mensaje más adecuado para entorno móvil.
          Text(
            'Por defecto: App Documents (private_key.pem)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          FileSelector(
            label: 'Archivo a desencriptar',
            value: _inputFilePath != null
                ? path.basename(_inputFilePath!)
                : null,
            onSelect: _selectInputFile,
            onClear: _clearInputFile,
          ),
          const SizedBox(height: 8),
          Text(
            'Archivos .enc generados por esta app',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          FileSaver(
            label: 'Archivo destino',
            value: _outputFilePath != null
                ? path.basename(_outputFilePath!)
                : null,
            onSelect: _selectOutputFile,
            onClear: _clearOutputFile,
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: (_privateKeyPath != null && 
                        _inputFilePath != null && 
                        _outputFilePath != null && 
                        !_isDecrypting)
                ? _decryptFile
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: _isDecrypting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Desencriptar',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          const SizedBox(height: 16),

          if (_statusMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusMessage!.startsWith('Error')
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusMessage!.startsWith('Error')
                      ? Colors.red.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusMessage!.startsWith('Error')
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: _statusMessage!.startsWith('Error')
                        ? Colors.red
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _statusMessage!.startsWith('Error')
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectPrivateKey() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Selecciona la clave privada RSA',
        allowedExtensions: ['rsa', 'pem', 'key'],
        type: FileType.custom,
      );

      if (result != null) {
        setState(() {
          _privateKeyPath = result.files.single.path;
          _statusMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error seleccionando clave: $e';
      });
    }
  }

  void _clearPrivateKey() {
    setState(() {
      _privateKeyPath = null;
      _statusMessage = null;
    });
  }

// Seleccionar archivo a desencriptar
  Future<void> _selectInputFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Selecciona el archivo a desencriptar',
        // 1. ELIMINAMOS LA LÍNEA: allowedExtensions: ['enc'],
        // 2. CAMBIAMOS EL TIPO A FileType.any
        type: FileType.any, 
      );

      if (result != null) {
        final inputPath = result.files.single.path!;
        
        setState(() {
          _inputFilePath = inputPath;
          _statusMessage = null;
          
          final dir = path.dirname(inputPath);
          final filename = path.basename(inputPath);
          
          if (filename.endsWith('.enc')) {
            _outputFilePath = path.join(dir, filename.substring(0, filename.length - 4));
          } else {
            _outputFilePath = path.join(dir, '$filename.dec');
          }
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error seleccionando archivo: $e';
      });
    }
  }

  void _clearInputFile() {
    setState(() {
      _inputFilePath = null;
      _outputFilePath = null;
      _statusMessage = null;
    });
  }

  Future<void> _selectOutputFile() async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo desencriptado',
        fileName: _outputFilePath != null 
            ? path.basename(_outputFilePath!)
            : 'archivo_desencriptado',
      );

      if (outputFile != null) {
        setState(() {
          _outputFilePath = outputFile;
          _statusMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error seleccionando destino: $e';
      });
    }
  }

  void _clearOutputFile() {
    setState(() {
      _outputFilePath = null;
      _statusMessage = null;
    });
  }

  Future<void> _decryptFile() async {
    if (_privateKeyPath == null || 
        _inputFilePath == null || 
        _outputFilePath == null) return;

    setState(() {
      _isDecrypting = true;
      _statusMessage = null;
    });

    try {
      final inputFile = File(_inputFilePath!);
      if (!await inputFile.exists()) {
        throw Exception('El archivo de entrada no existe');
      }

      await RSAManager.decryptFile(
        inputFile,
        _privateKeyPath!,
        _outputFilePath!,
      );

      final outputFile = File(_outputFilePath!);
      if (await outputFile.exists()) {
        final size = await outputFile.length();
        if (!mounted) return;
        setState(() {
          _isDecrypting = false;
          _statusMessage = '✅ Archivo desencriptado correctamente\n'
              'Tamaño: ${_formatFileSize(size)}\n'
              'Guardado en: $_outputFilePath';
        });
      } else {
        throw Exception('No se pudo crear el archivo de salida');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDecrypting = false;
        _statusMessage = '❌ Error desencriptando: $e';
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}