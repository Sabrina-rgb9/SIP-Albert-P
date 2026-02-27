import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FileSelector extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onSelect;
  final VoidCallback? onClear;

  const FileSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onSelect,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? 'No seleccionado',
                  style: TextStyle(
                    color: value == null ? Colors.grey : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: onSelect,
                tooltip: 'Seleccionar archivo',
              ),
              if (onClear != null && value != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                  tooltip: 'Limpiar selección',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Selector para guardar archivo (diálogo "guardar como")
class FileSaver extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onSelect;
  final VoidCallback? onClear;

  const FileSaver({
    super.key,
    required this.label,
    required this.value,
    required this.onSelect,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? 'No seleccionado',
                  style: TextStyle(
                    color: value == null ? Colors.grey : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: onSelect,
                tooltip: 'Seleccionar destino',
              ),
              if (onClear != null && value != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                  tooltip: 'Limpiar selección',
                ),
            ],
          ),
        ),
      ],
    );
  }
}