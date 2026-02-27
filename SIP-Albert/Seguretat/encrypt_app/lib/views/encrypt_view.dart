import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../models/rsa_manager.dart';
import '../widgets/file_selector.dart';

class EncryptView extends StatefulWidget {
  const EncryptView({super.key});

  @override
  State<EncryptView> createState() => _EncryptViewState();
}

class _EncryptViewState extends State<EncryptView> {
  String? _publicKeyPath;
  String? _inputFilePath;
  bool _isEncrypting = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título
          const Text(
            'Encriptar archivo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Selector de clave pública
          FileSelector(
            label: 'Clave pública RSA',
            value: _publicKeyPath != null
                ? path.basename(_publicKeyPath!)
                : null,
            onSelect: _selectPublicKey,
            onClear: _clearPublicKey,
          ),
          const SizedBox(height: 8),
          Text(
            'Formatos soportados: .pub, .pem (clave pública RSA)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Selector de archivo a encriptar
          FileSelector(
            label: 'Archivo a encriptar',
            value: _inputFilePath != null
                ? path.basename(_inputFilePath!)
                : null,
            onSelect: _selectInputFile,
            onClear: _clearInputFile,
          ),
          const SizedBox(height: 8),
          Text(
            'Cualquier archivo (texto, imagen, binario)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),

          // Botón de encriptar
          ElevatedButton(
            onPressed: (_publicKeyPath != null && _inputFilePath != null && !_isEncrypting)
                ? _encryptFile
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: _isEncrypting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Encriptar',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          const SizedBox(height: 16),

          // Mensaje de estado
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

  // Seleccionar clave pública
  Future<void> _selectPublicKey() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Selecciona la clave pública RSA',
        allowedExtensions: ['pub', 'pem'],
        type: FileType.custom,
      );

      if (result != null) {
        setState(() {
          _publicKeyPath = result.files.single.path;
          _statusMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error seleccionando clave: $e';
      });
    }
  }

  void _clearPublicKey() {
    setState(() {
      _publicKeyPath = null;
      _statusMessage = null;
    });
  }

  // Seleccionar archivo a encriptar
  Future<void> _selectInputFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Selecciona el archivo a encriptar',
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _inputFilePath = result.files.single.path;
          _statusMessage = null;
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
      _statusMessage = null;
    });
  }

  // Encriptar archivo
  Future<void> _encryptFile() async {
    if (_publicKeyPath == null || _inputFilePath == null) return;

    setState(() {
      _isEncrypting = true;
      _statusMessage = null;
    });

    try {
      // Preguntar dónde guardar el archivo encriptado
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo encriptado',
        fileName: '${path.basenameWithoutExtension(_inputFilePath!)}.enc',
      );

      if (outputFile == null) {
        setState(() {
          _isEncrypting = false;
          _statusMessage = 'Operación cancelada';
        });
        return;
      }

      // Encriptar usando RSA + AES (cifrado híbrido)
      await RSAManager.encryptFile(
        File(_inputFilePath!),
        _publicKeyPath!,
        outputFile,
      );

      if (!mounted) return;
      setState(() {
        _isEncrypting = false;
        _statusMessage = '✅ Archivo encriptado correctamente en:\n$outputFile';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEncrypting = false;
        _statusMessage = '❌ Error encriptando: $e';
      });
    }
  }
}