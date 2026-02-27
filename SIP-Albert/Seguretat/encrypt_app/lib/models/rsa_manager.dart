import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asn1.dart';
import 'package:path/path.dart' as path;
import 'dart:math' as Math;  // Añade esto con las otras importaciones

class RSAManager {
  static const int AES_KEY_SIZE = 32; // 256 bits
  static const int IV_SIZE = 16; // 128 bits
  static const String HEADER = 'RSA_ENC_V1';

  // Encriptar archivo usando RSA + AES (cifrado híbrido)
  static Future<void> encryptFile(
    File inputFile,
    String publicKeyPath,
    String outputPath,
  ) async {
    try {
      print('📝 Leyendo clave pública: $publicKeyPath');
      
      // 1. Leer clave pública
      final publicKey = await _loadPublicKey(publicKeyPath);
      
      // 2. Generar clave AES aleatoria
      final aesKey = _generateRandomBytes(AES_KEY_SIZE);
      final iv = _generateRandomBytes(IV_SIZE);
      
      // 3. Encriptar la clave AES con RSA
      final rsaEncrypter = RSAEngine()
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
      final encryptedAesKey = rsaEncrypter.process(aesKey);
      
      // 4. Encriptar el archivo con AES
      final fileBytes = await inputFile.readAsBytes();
      final encryptedData = _aesEncrypt(fileBytes, aesKey, iv);
      
      // 5. Crear archivo de salida
      final outputFile = File(outputPath);
      final sink = outputFile.openWrite();
      
      // Formato: [HEADER(8)][Longitud clave AES(4)][Clave AES encriptada][IV(16)][Datos encriptados]
      sink.add(utf8.encode(HEADER));
      
      final keyLengthBytes = Uint8List(4);
      ByteData.view(keyLengthBytes.buffer).setUint32(0, encryptedAesKey.length);
      sink.add(keyLengthBytes);
      
      sink.add(encryptedAesKey);
      sink.add(iv);
      sink.add(encryptedData);
      
      await sink.flush();
      await sink.close();
      
      print('✅ Archivo encriptado correctamente');
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Error encriptando archivo: $e');
    }
  }

  // Desencriptar archivo
  static Future<void> decryptFile(
    File inputFile,
    String privateKeyPath,
    String outputPath,
  ) async {
    try {
      print('📝 Leyendo clave privada: $privateKeyPath');
      
      // 1. Leer clave privada
      final privateKey = await _loadPrivateKey(privateKeyPath);
      
      // 2. Leer archivo encriptado
      final fileBytes = await inputFile.readAsBytes();
      var offset = 0;
      
      // Verificar header
      final header = utf8.decode(fileBytes.sublist(offset, offset + 8));
      if (header != HEADER) {
        throw Exception('Formato de archivo no válido');
      }
      offset += 8;
      
      // Leer longitud de clave AES encriptada
      final keyLength = ByteData.sublistView(fileBytes, offset, offset + 4).getUint32(0);
      offset += 4;
      
      // Leer clave AES encriptada
      final encryptedAesKey = fileBytes.sublist(offset, offset + keyLength);
      offset += keyLength;
      
      // Leer IV
      final iv = fileBytes.sublist(offset, offset + IV_SIZE);
      offset += IV_SIZE;
      
      // Leer datos encriptados
      final encryptedData = fileBytes.sublist(offset);
      
      // 3. Desencriptar clave AES con RSA
      final rsaDecrypter = RSAEngine()
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      final aesKey = rsaDecrypter.process(encryptedAesKey);
      
      // 4. Desencriptar datos con AES
      final decryptedData = _aesDecrypt(encryptedData, aesKey, iv);
      
      // 5. Guardar archivo
      await File(outputPath).writeAsBytes(decryptedData);
      
      print('✅ Archivo desencriptado correctamente');
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Error desencriptando archivo: $e');
    }
  }

 // Cargar clave pública desde archivo PEM (VERSIÓN CORREGIDA)
static Future<RSAPublicKey> _loadPublicKey(String path) async {
  try {
    final pemString = await File(path).readAsString();
    print('📄 Contenido PEM público: ${pemString.substring(0, Math.min(50, pemString.length))}...');
    
    // Extraer la parte base64 de forma más robusta
    final RegExp regex = RegExp(r'-----BEGIN.*?-----(.*?)-----END.*?-----', dotAll: true);
    final match = regex.firstMatch(pemString);
    
    if (match == null) {
      throw Exception('Formato PEM no válido');
    }
    
    String base64String = match.group(1)?.replaceAll(RegExp(r'\s'), '') ?? '';
    if (base64String.isEmpty) {
      throw Exception('No se encontró contenido base64');
    }
    
    print('🔑 Base64 público: ${base64String.substring(0, Math.min(30, base64String.length))}...');
    
    final keyBytes = base64.decode(base64String);
    print('📊 Bytes público: ${keyBytes.length} bytes');
    
    // Parsear ASN.1
    final parser = ASN1Parser(keyBytes);
    final topLevel = parser.nextObject();
    
    if (topLevel is ASN1Sequence) {
      print('📋 Secuencia ASN.1 encontrada');
      final elements = topLevel.elements;
      
      if (elements != null && elements.length >= 2) {
        final modulusObj = elements[0];
        final exponentObj = elements[1];
        
        if (modulusObj is ASN1Integer && exponentObj is ASN1Integer) {
          print('✅ Módulo y exponente extraídos');
          return RSAPublicKey(
            modulusObj.integer!,
            exponentObj.integer!,
          );
        }
      }
    }
    
    throw Exception('No se pudo parsear la clave pública');
  } catch (e) {
    print('❌ Error parseando clave pública: $e');
    rethrow;
  }
}

// Cargar clave privada desde archivo PEM (VERSIÓN CORREGIDA)
static Future<RSAPrivateKey> _loadPrivateKey(String path) async {
  try {
    final pemString = await File(path).readAsString();
    print('📄 Contenido PEM privado: ${pemString.substring(0, Math.min(50, pemString.length))}...');
    
    // Extraer la parte base64 de forma más robusta
    final RegExp regex = RegExp(r'-----BEGIN.*?-----(.*?)-----END.*?-----', dotAll: true);
    final match = regex.firstMatch(pemString);
    
    if (match == null) {
      throw Exception('Formato PEM no válido');
    }
    
    String base64String = match.group(1)?.replaceAll(RegExp(r'\s'), '') ?? '';
    if (base64String.isEmpty) {
      throw Exception('No se encontró contenido base64');
    }
    
    print('🔑 Base64 privado: ${base64String.substring(0, Math.min(30, base64String.length))}...');
    
    final keyBytes = base64.decode(base64String);
    print('📊 Bytes privado: ${keyBytes.length} bytes');
    
    // Parsear ASN.1
    final parser = ASN1Parser(keyBytes);
    final topLevel = parser.nextObject();
    
    if (topLevel is ASN1Sequence) {
      print('📋 Secuencia ASN.1 encontrada');
      final elements = topLevel.elements;
      
      if (elements != null && elements.length >= 9) {
        print('📊 Elementos encontrados: ${elements.length}');
        
        final modulus = elements[1] as ASN1Integer;
        final publicExponent = elements[2] as ASN1Integer;
        final privateExponent = elements[3] as ASN1Integer;
        final prime1 = elements[4] as ASN1Integer;
        final prime2 = elements[5] as ASN1Integer;
        
        print('✅ Componentes extraídos:');
        print('   modulus: ${modulus.integer}');
        print('   publicExponent: ${publicExponent.integer}');
        print('   prime1: ${prime1.integer}');
        print('   prime2: ${prime2.integer}');
        
        return RSAPrivateKey(
          privateExponent.integer!,
          modulus.integer!,
          publicExponent.integer!,
          prime1.integer!,
          prime2.integer!,
        );
      }
    }
    
    throw Exception('No se pudo parsear la clave privada');
  } catch (e) {
    print('❌ Error parseando clave privada: $e');
    rethrow;
  }
}

  // Generar bytes aleatorios
  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  // Encriptar AES (modo CBC)
  static Uint8List _aesEncrypt(Uint8List data, Uint8List key, Uint8List iv) {
    final aesKey = KeyParameter(key);
    final ivParam = ParametersWithIV(aesKey, iv);
    
    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ivParam);
    
    return _processInBlocks(cipher, data);
  }

  // Desencriptar AES (modo CBC)
  static Uint8List _aesDecrypt(Uint8List encryptedData, Uint8List key, Uint8List iv) {
    final aesKey = KeyParameter(key);
    final ivParam = ParametersWithIV(aesKey, iv);
    
    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ivParam);
    
    return _processInBlocks(cipher, encryptedData);
  }

  // Procesar datos en bloques para AES
  static Uint8List _processInBlocks(BlockCipher cipher, Uint8List data) {
    final blockSize = cipher.blockSize;
    final output = BytesBuilder();
    
    for (var i = 0; i < data.length; i += blockSize) {
      final end = min(i + blockSize, data.length);
      final block = data.sublist(i, end);
      
      if (block.length < blockSize) {
        // Rellenar último bloque con ceros (simplificado)
        final padded = Uint8List(blockSize)..setAll(0, block);
        output.add(cipher.process(padded));
      } else {
        output.add(cipher.process(block));
      }
    }
    
    return output.toBytes();
  }

 // Generar par de claves RSA con generador seguro
static Future<void> generateKeyPairSecure(String directory) async {
  try {
    print('🔑 Generando par de claves RSA con generador seguro...');
    
    // Configurar generador de números aleatorios seguro
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(
        Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256)))
      ));
    
    // Configurar generador de claves RSA (512 bits para prueba)
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 512, 64),
        secureRandom,
      ));
    
    // Generar par de claves
    final keyPair = keyGen.generateKeyPair();
    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;
    
    print('✅ Claves generadas con RSAKeyGenerator');
    
    // Guardar clave pública - FORMATO CORREGIDO
    final publicKeyPath = '$directory/public_key.pem';
    final publicKeyBytes = _encodePublicKey(publicKey);
    if (publicKeyBytes.isEmpty) {
      throw Exception('Error codificando clave pública');
    }
    
    final publicKeyBase64 = base64.encode(publicKeyBytes);
    final publicKeyChunks = _chunk(publicKeyBase64, 64);
    final publicKeyPem = '''
-----BEGIN PUBLIC KEY-----
$publicKeyChunks
-----END PUBLIC KEY-----
''';
    await File(publicKeyPath).writeAsString(publicKeyPem);
    
    // Guardar clave privada - FORMATO CORREGIDO
    final privateKeyPath = '$directory/private_key.pem';
    final privateKeyBytes = _encodePrivateKey(privateKey);
    if (privateKeyBytes.isEmpty) {
      throw Exception('Error codificando clave privada');
    }
    
    final privateKeyBase64 = base64.encode(privateKeyBytes);
    final privateKeyChunks = _chunk(privateKeyBase64, 64);
    final privateKeyPem = '''
-----BEGIN RSA PRIVATE KEY-----
$privateKeyChunks
-----END RSA PRIVATE KEY-----
''';
    await File(privateKeyPath).writeAsString(privateKeyPem);
    
    print('✅ Claves generadas en: $directory');
    print('   📄 Pública: $publicKeyPath');
    print('   🔐 Privada: $privateKeyPath');
    
  } catch (e) {
    print('❌ Error generando claves: $e');
    rethrow;
  }
}

// Añadir función auxiliar para dividir base64 en líneas
static String _chunk(String str, int size) {
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i += size) {
    if (i > 0) buffer.writeln();
    final end = (i + size < str.length) ? i + size : str.length;
    buffer.write(str.substring(i, end));
  }
  return buffer.toString();
}

  // Codificar clave pública
  static Uint8List _encodePublicKey(RSAPublicKey key) {
    final seq = ASN1Sequence();
    seq.add(ASN1Integer(key.modulus));
    seq.add(ASN1Integer(key.exponent!));
    final encoded = seq.encodedBytes;
    return encoded ?? Uint8List(0);
  }

  // Codificar clave privada
  static Uint8List _encodePrivateKey(RSAPrivateKey key) {
    final seq = ASN1Sequence();
    seq.add(ASN1Integer(BigInt.zero)); // version
    
    seq.add(ASN1Integer(key.modulus!));
    seq.add(ASN1Integer(key.publicExponent!));
    seq.add(ASN1Integer(key.privateExponent!));
    seq.add(ASN1Integer(key.p!));
    seq.add(ASN1Integer(key.q!));
    
    // Calcular exponent1, exponent2, coefficient
    final exponent1 = key.p! - BigInt.one;
    final exponent2 = key.q! - BigInt.one;
    final coefficient = key.q!.modInverse(key.p!);
    
    seq.add(ASN1Integer(exponent1));
    seq.add(ASN1Integer(exponent2));
    seq.add(ASN1Integer(coefficient));
    
    final encoded = seq.encodedBytes;
    return encoded ?? Uint8List(0);
  }

  // Obtener ruta del directorio .ssh
  static Future<String> getSshPath() async {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) {
      throw Exception('No se pudo determinar el directorio home');
    }
    return '$home/.ssh';
  }

  // Verificar si existe la clave privada por defecto (solo para las generadas)
  static Future<String?> getDefaultPrivateKeyPath() async {
    try {
      final docs = await getApplicationDocumentsDirectory(); // AHORA FUNCIONA
      final defaultKey = '${docs.path}/private_key.pem';
      final file = File(defaultKey);
      if (await file.exists()) {
        return defaultKey;
      }
    } catch (e) {
      print('Error buscando clave por defecto: $e');
    }
    return null;
  }
}