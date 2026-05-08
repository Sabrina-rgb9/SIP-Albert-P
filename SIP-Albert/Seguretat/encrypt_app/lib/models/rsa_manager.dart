import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asn1.dart';
// CORRECCIÓN: Importar el esquema de padding PKCS1
import 'package:pointycastle/asymmetric/pkcs1.dart';

class RSAManager {
  static const int AES_KEY_SIZE = 32; // 256 bits
  static const int IV_SIZE = 16; // 128 bits
  static const String HEADER = 'RSA_ENC_V1';

  static Uint8List _decodePem(String pemString, List<String> allowedHeaders) {
    final normalized = pemString.replaceAll('\r', '');
    for (final header in allowedHeaders) {
      final regex = RegExp(
        '-----BEGIN $header-----(.*?)-----END $header-----',
        dotAll: true,
      );
      final match = regex.firstMatch(normalized);
      if (match != null) {
        final base64Content = match.group(1)!.replaceAll(RegExp(r'\s+'), '');
        return base64.decode(base64Content);
      }
    }
    throw Exception('Formato PEM no válido: no se encontró encabezado válido');
  }

  static RSAPublicKey _parseRsaPublicKey(Uint8List keyBytes) {
    final parser = ASN1Parser(keyBytes);
    final topLevel = parser.nextObject();

    if (topLevel is ASN1Sequence) {
      final elements = topLevel.elements;
      if (elements != null && elements.length == 2) {
        if (elements[0] is ASN1Integer && elements[1] is ASN1Integer) {
          final modulus = (elements[0] as ASN1Integer).integer!;
          final exponent = (elements[1] as ASN1Integer).integer!;
          return RSAPublicKey(modulus, exponent);
        }

        if (elements[1] is ASN1BitString) {
          final bitString = elements[1] as ASN1BitString;
          final publicKeyBytes = Uint8List.fromList(bitString.stringValues ?? []);
          final publicKeyParser = ASN1Parser(publicKeyBytes);
          final publicKeySequence = publicKeyParser.nextObject();

          if (publicKeySequence is ASN1Sequence &&
              publicKeySequence.elements != null &&
              publicKeySequence.elements!.length == 2 &&
              publicKeySequence.elements![0] is ASN1Integer &&
              publicKeySequence.elements![1] is ASN1Integer) {
            final modulus = (publicKeySequence.elements![0] as ASN1Integer).integer!;
            final exponent = (publicKeySequence.elements![1] as ASN1Integer).integer!;
            return RSAPublicKey(modulus, exponent);
          }
        }
      }
    }

    throw Exception('No se pudo parsear la clave pública');
  }

  static RSAPrivateKey _parseRsaPrivateKey(Uint8List keyBytes) {
    final parser = ASN1Parser(keyBytes);
    final topLevel = parser.nextObject();

    if (topLevel is ASN1Sequence) {
      final elements = topLevel.elements;

      if (elements != null && elements.length >= 9 && elements[1] is ASN1Integer) {
        final modulus = (elements[1] as ASN1Integer).integer!;
        final privateExponent = (elements[3] as ASN1Integer).integer!;
        final prime1 = (elements[4] as ASN1Integer).integer!;
        final prime2 = (elements[5] as ASN1Integer).integer!;

        return RSAPrivateKey(
          modulus,
          privateExponent,
          prime1,
          prime2,
        );
      }

      if (elements != null && elements.length == 3 && elements[2] is ASN1OctetString) {
        final octet = elements[2] as ASN1OctetString;
        final nestedBytes = octet.valueBytes!;
        return _parseRsaPrivateKey(nestedBytes);
      }
    }

    throw Exception('No se pudo parsear la clave privada');
  }

  // Encriptar archivo usando RSA ( Encriptación Asimétrica ) + AES ( Encriptación Simétrica )
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
      // Uso de PKCS1Encoding para evitar errores de longitud y mejorar la seguridad
      final rsaEncrypter = PKCS1Encoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
      final encryptedAesKey = rsaEncrypter.process(aesKey);
      
      // 4. Encriptar el archivo con AES
      final fileBytes = await inputFile.readAsBytes();
      final encryptedData = _aesEncrypt(fileBytes, aesKey, iv);
      
      // 5. Crear archivo de salida
      final outputFile = File(outputPath);
      final sink = outputFile.openWrite();
      
      // Formato: [HEADER(8)][Longitud clave AES(4)][Clave AES encriptada][IV(16)][Datos encriptados]
      // lo que hce que el header sea de 10 bytes para incluir la versión 'RSA_ENC_V1'
      // RSA_ENC_V1 es un header personalizado para identificar el formato del archivo encriptado y permitir futuras versiones
      sink.add(utf8.encode(HEADER));
      

      // Es importante escribir la longitud de la clave AES encriptada antes de los datos para poder leerla correctamente al desencriptar, ya que la longitud puede variar dependiendo del tamaño de la clave RSA y el esquema de padding utilizado. Esto asegura que el proceso de desencriptación pueda extraer la clave AES correctamente sin ambigüedades.
      final keyLengthBytes = Uint8List(4);
      ByteData.view(keyLengthBytes.buffer).setUint32(0, encryptedAesKey.length);
      sink.add(keyLengthBytes);
      
      // Escribir clave AES encriptada, IV y datos encriptados
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
      // lo que hace que el header sea de 10 bytes para incluir la versión 'RSA_ENC_V1'
      final header = utf8.decode(fileBytes.sublist(offset, offset + 10));
      if (header != HEADER) {
        throw Exception('Formato de archivo no válido');
      }
      offset += 10; 
      
      // Leer longitud de clave AES encriptada ya que puede variar dependiendo del tamaño de la clave RSA y el esquema de padding utilizado
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
      // CORRECCIÓN: Uso de PKCS1Encoding a la par de la encriptación
      final rsaDecrypter = PKCS1Encoding(RSAEngine())
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

 // Cargar clave pública desde archivo PEM
static Future<RSAPublicKey> _loadPublicKey(String path) async {
  try {
    final pemString = await File(path).readAsString();
    print('📄 Contenido PEM público: ${pemString.substring(0, min(50, pemString.length))}...');

    final keyBytes = _decodePem(pemString, ['PUBLIC KEY', 'RSA PUBLIC KEY']);
    print('📊 Bytes público: ${keyBytes.length} bytes');

    final publicKey = _parseRsaPublicKey(keyBytes);
    print('✅ Clave pública parseada correctamente');
    return publicKey;
  } catch (e) {
    print('❌ Error parseando clave pública: $e');
    rethrow;
  }
}

// Cargar clave privada desde archivo PEM
static Future<RSAPrivateKey> _loadPrivateKey(String path) async {
  try {
    final pemString = await File(path).readAsString();
    print('📄 Contenido PEM privado: ${pemString.substring(0, min(50, pemString.length))}...');

    final keyBytes = _decodePem(pemString, ['RSA PRIVATE KEY', 'PRIVATE KEY']);
    print('📊 Bytes privado: ${keyBytes.length} bytes');

    final privateKey = _parseRsaPrivateKey(keyBytes);
    print('✅ Clave privada parseada correctamente');
    return privateKey;
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

  // Encriptar AES (modo CBC con PKCS7)
  static Uint8List _aesEncrypt(Uint8List data, Uint8List key, Uint8List iv) {
    final params = PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
      ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
      null,
    );
    final cipher = PaddedBlockCipher('AES/CBC/PKCS7')..init(true, params);
    return cipher.process(data);
  }

  // Desencriptar AES (modo CBC con PKCS7)
  static Uint8List _aesDecrypt(Uint8List encryptedData, Uint8List key, Uint8List iv) {
    final params = PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
      ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
      null,
    );
    final cipher = PaddedBlockCipher('AES/CBC/PKCS7')..init(false, params);
    return cipher.process(encryptedData);
  }

 // Generar par de claves RSA con generador seguro
static Future<void> generateKeyPairSecure(String directory) async {
  try {
    print('🔑 Generando par de claves RSA con generador seguro...');
    
    // Configurar generador de números aleatorios seguro con Fortuna
    final secureRandom = SecureRandom('Fortuna') 
      ..seed(KeyParameter(
        Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256)))
      ));
    
    // Clave de 2048 bits con exponente público 65537 
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64), // CORRECCIÓN: Aumentar el número de pruebas de primalidad a 64 para mayor seguridad
        secureRandom,
      ));
    
    // Generar par de claves
    final keyPair = keyGen.generateKeyPair();
    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;
    
    print('✅ Claves generadas con RSAKeyGenerator');
    
    // Guardar clave pública
    final publicKeyPath = '$directory/public_key.pem'; // CORRECCIÓN: Cambiar extensión a .pem para mayor claridad
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
    
    // Guardar clave privada
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

static String _chunk(String str, int size) {
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i += size) {
    if (i > 0) buffer.writeln();
    final end = (i + size < str.length) ? i + size : str.length;
    buffer.write(str.substring(i, end));
  }
  return buffer.toString();
}

// Codificar clave pública en formato X.509 / SubjectPublicKeyInfo
  static Uint8List _encodePublicKey(RSAPublicKey key) {
    final rsaSequence = ASN1Sequence();
    rsaSequence.add(ASN1Integer(key.modulus));
    rsaSequence.add(ASN1Integer(key.exponent!));

    final algorithmSequence = ASN1Sequence();
    algorithmSequence.add(ASN1ObjectIdentifier.fromName('rsaEncryption'));
    algorithmSequence.add(ASN1Null());

    final topLevel = ASN1Sequence();
    topLevel.add(algorithmSequence);
    
    // CORRECCIÓN: Usar .encode() para generar los bytes, NO la propiedad .encodedBytes!
    topLevel.add(ASN1BitString(stringValues: rsaSequence.encode()));

    // CORRECCIÓN: Retornar la ejecución de .encode()
    return topLevel.encode();
  }

  // Codificar clave privada
  static Uint8List _encodePrivateKey(RSAPrivateKey key) {
    final seq = ASN1Sequence();
    seq.add(ASN1Integer(BigInt.zero)); // version
    
    seq.add(ASN1Integer(key.modulus!));
    // CORRECCIÓN: Asegurarnos de que el exponente público no sea nulo (fallback estándar a 65537)
    seq.add(ASN1Integer(key.publicExponent ?? BigInt.parse('65537')));
    seq.add(ASN1Integer(key.privateExponent!));
    seq.add(ASN1Integer(key.p!));
    seq.add(ASN1Integer(key.q!));
    
    final exponent1 = key.privateExponent! % (key.p! - BigInt.one);
    final exponent2 = key.privateExponent! % (key.q! - BigInt.one);
    final coefficient = key.q!.modInverse(key.p!);
    
    seq.add(ASN1Integer(exponent1));
    seq.add(ASN1Integer(exponent2));
    seq.add(ASN1Integer(coefficient));
    
    // CORRECCIÓN: Usar .encode() directamente
    return seq.encode();
  }

  // Obtener ruta del directorio .ssh (Solo útil en Escritorio)
  static Future<String> getSshPath() async {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) {
      throw Exception('No se pudo determinar el directorio home');
    }
    return '$home/.ssh';
  }

  // Verificar si existe la clave privada por defecto
  static Future<String?> getDefaultPrivateKeyPath() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
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