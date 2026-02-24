import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  // ============================
  // IMAGE PREPROCESSING
  // ============================
  static Future<File> _preprocessImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return imageFile;

    final cropX = (image.width * 0.05).toInt();
    final cropY = (image.height * 0.15).toInt();
    final cropWidth = (image.width * 0.9).toInt();
    final cropHeight = (image.height * 0.7).toInt();
    image = img.copyCrop(image,
        x: cropX, y: cropY, width: cropWidth, height: cropHeight);

    image = img.grayscale(image);
    image = img.adjustColor(image, contrast: 2.0, brightness: -0.05);
    image = img.convolution(image, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);

    final processedBytes = img.encodeJpg(image, quality: 100);
    final tempDir = await Directory.systemTemp.createTemp();
    final processedFile = File('${tempDir.path}/processed_ktp.jpg');
    await processedFile.writeAsBytes(processedBytes);

    return processedFile;
  }

  // ============================
  // PICK IMAGE
  // ============================
  static Future<File?> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 100,
    );

    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  // ============================
  // EXTRACT TEXT
  // ============================
  static Future<String> extractText(File imageFile) async {
    String extractedText = '';

    try {
      final processedImage = await _preprocessImage(imageFile);
      final InputImage inputImage = InputImage.fromFile(processedImage);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      extractedText = recognizedText.text;

      try {
        await processedImage.delete();
      } catch (e) {}

      if (extractedText.trim().isEmpty) {
        final InputImage originalInput = InputImage.fromFile(imageFile);
        final RecognizedText originalText =
            await _textRecognizer.processImage(originalInput);
        extractedText = originalText.text;
      }
    } catch (e) {
      final InputImage originalInput = InputImage.fromFile(imageFile);
      final RecognizedText originalText =
          await _textRecognizer.processImage(originalInput);
      extractedText = originalText.text;
    }

    return extractedText;
  }

  // ============================
  // CEK SKIP
  // ============================
  static bool _shouldSkip(String text) {
    final upper = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final original = text.toUpperCase();
    
    if (original.contains('PROVINSI') || original.contains('KABUPATEN') || 
        original.contains('KOTA') || original.contains('REPUBLIK')) {
      return true;
    }
    
    final exactLabels = [
      'NIK', 'NAMA', 'ALAMAT', 'ALAMAE', 'ALAMATE', 'AGAMA', 'PEKERJAAN',
      'TEMPAT', 'LAHIR', 'RT', 'RW', 'RTRW', 'RTAW', 'RIRW',
      'KEL', 'DESA', 'KELDESA', 'KECAMATAN', 'KECANATAN',
    ];
    
    for (final label in exactLabels) {
      if (upper == label) return true;
    }
    
    final lettersOnly = text.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (lettersOnly.length < 4 && !RegExp(r'\d{8,}').hasMatch(text)) {
      return true;
    }
    
    final dateMatch = RegExp(r'(\d{2})-(\d{2})-(\d{4})').firstMatch(text);
    if (dateMatch != null) {
      final year = int.tryParse(dateMatch.group(3)!) ?? 0;
      if (year > 2020) return true;
    }
    
    if (RegExp(r'^\d{1,3}/\d{1,3}$').hasMatch(text.trim())) return true;
    if (original.contains('KEWARGANEGARAAN')) return true;
    
    return false;
  }

  // ============================
  // EXTRACT TANGGAL LAHIR
  // ============================
  static String? _extractBirthDate(String text) {
    String fixed = text
        .replaceAll(RegExp(r'[Gg]'), '0')
        .replaceAll(RegExp(r'[Oo]'), '0')
        .replaceAll(RegExp(r'[Ii]'), '1')
        .replaceAll(RegExp(r'[Ll]'), '1')
        .replaceAll(RegExp(r'[Ss]'), '5')
        .replaceAll(RegExp(r'[Bb]'), '8')
        .replaceAll(RegExp(r'[Dd]'), '0');
    
    final match1 = RegExp(r'(\d{1,2})\s*[-/\.]\s*(\d{1,2})\s*[-/\.\s]+(\d{4})')
        .firstMatch(fixed);
    if (match1 != null) {
      final day = int.tryParse(match1.group(1)!) ?? 0;
      final month = int.tryParse(match1.group(2)!) ?? 0;
      final year = int.tryParse(match1.group(3)!) ?? 0;
      
      if (_isValidBirthDate(day, month, year)) {
        return '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year';
      }
    }
    
    final digits = fixed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 8) {
      for (int i = 0; i <= digits.length - 8; i++) {
        final candidate = digits.substring(i, i + 8);
        final day = int.tryParse(candidate.substring(0, 2)) ?? 0;
        final month = int.tryParse(candidate.substring(2, 4)) ?? 0;
        final year = int.tryParse(candidate.substring(4, 8)) ?? 0;
        
        if (_isValidBirthDate(day, month, year)) {
          return '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year';
        }
      }
    }
    
    return null;
  }

  static String? _extractDateFromNIK(String text) {
    String fixed = text
        .replaceAll(RegExp(r'[Oo]'), '0')
        .replaceAll(RegExp(r'[Ii]'), '1')
        .replaceAll(RegExp(r'[Ll]'), '1')
        .replaceAll(RegExp(r'[Dd]'), '0')
        .replaceAll(RegExp(r'[Ss]'), '5')
        .replaceAll(RegExp(r'[Bb]'), '8')
        .replaceAll(' ', '');
    
    final digitsOnly = fixed.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.length >= 12) {
      final provinceCode = int.tryParse(digitsOnly.substring(0, 2)) ?? 0;
      if (provinceCode >= 11 && provinceCode <= 94) {
        int day = int.tryParse(digitsOnly.substring(6, 8)) ?? 0;
        final month = int.tryParse(digitsOnly.substring(8, 10)) ?? 0;
        final yearShort = int.tryParse(digitsOnly.substring(10, 12)) ?? 0;
        
        if (day > 40) day -= 40;
        int year = yearShort <= 24 ? 2000 + yearShort : 1900 + yearShort;
        
        if (_isValidBirthDate(day, month, year)) {
          return '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year';
        }
      }
    }
    return null;
  }

  static bool _isValidBirthDate(int day, int month, int year) {
    if (year < 1940 || year > 2015) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    return true;
  }

  // ============================
  // CEK APAKAH INI ALAMAT
  // ============================
  static bool _isAddress(String text) {
    final upper = text.toUpperCase();
    final addressKeywords = [
      'DUSUN', 'JALAN', 'JL', 'BLOK', 'GANG', 'GG', 
      'KOMPLEK', 'PERUM', 'PERUMAHAN', 'KAMPUNG', 'KP',
      'GRIYA', 'TAMAN', 'CLUSTER', 'SENTOSA', 'ASRI', 'INDAH',
    ];
    
    for (final kw in addressKeywords) {
      if (upper.contains(kw)) return true;
    }
    return false;
  }

  // ============================
  // CEK APAKAH INI LABEL/FIELD LAIN
  // ============================
  static bool _isLabelOrOtherField(String text) {
    final upper = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final original = text.toUpperCase();
    
    // Label KTP
    final labels = [
      'KECAMATAN', 'KECANATAN', 'KECAATAN', 'KECAMNATAN',
      'PROVINSI', 'PRONNSI', 'KABUPATEN',
      'GOL', 'DARAH', 'DARAT', 'GOLDARAH',
      'KEWARGANEGARAAN', 'WARGANEGARA',
      'BERLAKU', 'BRLAKU', 'HINGGA',
      'STATUS', 'PERKAWINAN', 'PERKAWINAR', 'PERKAWIRNAR',
      'KELAMIN', 'KELAMIE', 'KELAMN',
      'TEMPAT', 'LAHIR', 'TGL',
      'PEKERJAAN', 'AGAMA',
      'JENIS', 'JERIS',
    ];
    
    for (final lbl in labels) {
      if (original.contains(lbl)) return true;
    }
    
    // Nilai field lain
    final otherFields = [
      'LAKILAKI', 'LAKIAKI', 'LAKHLAK', 'LAKIHAKI', 'LAKHAKI', 'LAKLAKI',
      'EAKLAKI', 'AKILAKI', 'DAKLLAK', 'TAKEEAKE', 'AKEAKE', 'LAKAK',
      'PEREMPUAN', 'WANITA', 'PREMPUAN',
      'ISLAM', 'ISLAMF', 'ISLA', 'ISLAN', 'ISTAME', 'KRISTEN', 'KATOLIK', 'HINDU', 'BUDDHA',
      'BELUMKAWIN', 'BELUMKAWN', 'BEUMKAWIN', 'KAWIN', 'CERAI',
      'PELAJAR', 'MAHASISWA', 'PELAARMAHASISWA', 'PELAJARMAHASISWA', 'PELAJARAMAHASISWA',
      'KARYAWAN', 'WIRASWASTA', 'PNS', 'TNI', 'POLRI', 'PETANI', 'BURUH',
      'WNI', 'WNA', 'WNE',
      'SEUMUR', 'HIDUP', 'SEUMURHIDUP',
      'KARTU', 'KARTUY', 'KART', 'PENDUDUK', 'TANDA', 
      'OUOUK', 'ARTU', 'END', 'OAPEND', 'ERUD', 'OUDUK', 'RUDUK', 'UDUK',
    ];
    
    for (final field in otherFields) {
      if (upper == field || upper.contains(field)) return true;
    }
    
    return false;
  }

  // ============================
  // CEK APAKAH INI NAMA KOTA
  // ============================
  static bool _isCityName(String text) {
    final upper = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final cities = [
      'KARAWANG', 'KARAWNANG', 'BOGOR', 'JAKARTA', 'BANDUNG', 
      'SURABAYA', 'SEMARANG', 'MALANG', 'YOGYAKARTA', 'MEDAN',
      'BEKASI', 'TANGERANG', 'DEPOK', 'CIREBON',
    ];
    
    for (final city in cities) {
      if (upper == city || upper.startsWith(city)) return true;
    }
    return false;
  }

  // ============================
  // SCORE NAMA - SIMPLIFIED & FIXED
  // ============================
  static int _scoreNameCandidate(String text) {
    final upper = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    
    // === HARD REJECT ===
    
    // 1. Reject jika ini ALAMAT
    if (_isAddress(text)) {
      print('    [REJECT NAME] Is address');
      return -1000;
    }
    
    // 2. Reject jika label atau field lain
    if (_isLabelOrOtherField(text)) {
      print('    [REJECT NAME] Is label/other field');
      return -1000;
    }
    
    // 3. Reject jika nama kota
    if (_isCityName(text)) {
      print('    [REJECT NAME] Is city name');
      return -1000;
    }
    
    // 4. Reject jika banyak angka
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4) {
      print('    [REJECT NAME] Too many digits');
      return -1000;
    }
    
    // 5. Reject jika ada tanggal
    if (_extractBirthDate(text) != null) {
      print('    [REJECT NAME] Contains date');
      return -1000;
    }
    
    // 6. Reject jika diawali ":"
    if (text.trim().startsWith(':')) {
      print('    [REJECT NAME] Starts with colon');
      return -1000;
    }
    
    // 7. Reject jika ada "/"
    if (text.contains('/')) {
      print('    [REJECT NAME] Contains slash');
      return -1000;
    }
    
    // === CLEANING ===
    String cleaned = text.replaceAll(RegExp(r'[^A-Za-z\s]'), '').trim();
    if (cleaned.isEmpty) return -1000;
    
    // === SCORING ===
    int score = 0;
    
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
    
    // Nama tunggal (1 kata) - sangat umum di Indonesia
    if (words.length == 1) {
      if (cleaned.length >= 3 && cleaned.length <= 10) {
        score = 150; // Score tertinggi untuk nama tunggal pendek
        print('    [SCORE NAME] Single word 3-10 chars: +150');
      } else if (cleaned.length >= 3 && cleaned.length <= 15) {
        score = 100;
        print('    [SCORE NAME] Single word 3-15 chars: +100');
      }
    } 
    // 2-3 kata
    else if (words.length == 2 || words.length == 3) {
      score = 130;
      print('    [SCORE NAME] 2-3 words: +130');
    }
    // 4 kata
    else if (words.length == 4) {
      score = 100;
      print('    [SCORE NAME] 4 words: +100');
    }
    // Lebih dari 4 kata - jarang untuk nama
    else {
      score = 50;
    }
    
    // Bonus ALL CAPS
    if (text == text.toUpperCase()) {
      score += 10;
    }
    
    return score;
  }

  // ============================
  // SCORE ALAMAT - SIMPLIFIED & FIXED
  // ============================
  static int _scoreAddressCandidate(String text) {
    final upper = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    
    // === HARD REJECT ===
    
    // 1. Reject label
    if (_isLabelOrOtherField(text)) {
      print('    [REJECT ADDR] Is label/other field');
      return -1000;
    }
    
    // 2. Reject jika terlalu pendek
    final letters = text.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 5) {
      print('    [REJECT ADDR] Too short');
      return -1000;
    }
    
    // 3. Reject jika diawali ":"
    if (text.trim().startsWith(':')) {
      print('    [REJECT ADDR] Starts with colon');
      return -1000;
    }
    
    // === SCORING ===
    int score = 0;
    
    // BONUS BESAR jika mengandung keyword alamat
    if (_isAddress(text)) {
      score = 200;
      print('    [SCORE ADDR] Contains address keyword: +200');
    } else {
      // Tanpa keyword alamat, score rendah
      score = 10;
    }
    
    return score;
  }

  // ============================
  // PARSE DATA KTP
  // ============================
  static Map<String, String> parseCustomerData(String text) {
    print('========== RAW OCR TEXT ==========');
    print(text);
    print('===================================');

    final List<String> lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String bestName = '';
    String bestAddress = '';
    String bestDate = '';
    
    int bestNameScore = -1000;
    int bestAddressScore = -1000;
    
    List<String> candidates = [];
    String? nikLine;

    for (final line in lines) {
      if (_shouldSkip(line)) {
        print('SKIP: "$line"');
        continue;
      }
      
      print('PROCESS: "$line"');
      
      final digitsOnly = line.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length >= 14 && digitsOnly.length <= 18) {
        nikLine = line;
        print('  -> Possible NIK');
      }
      
      if (bestDate.isEmpty) {
        final date = _extractBirthDate(line);
        if (date != null) {
          bestDate = date;
          print('  -> Found Date: $date');
        }
      }
      
      candidates.add(line);
    }
    
    if (bestDate.isEmpty && nikLine != null) {
      final dateFromNIK = _extractDateFromNIK(nikLine);
      if (dateFromNIK != null) {
        bestDate = dateFromNIK;
        print('  -> Date from NIK: $dateFromNIK');
      }
    }

    // Score nama
    print('\n--- NAME SCORING ---');
    for (final candidate in candidates) {
      print('Checking: "$candidate"');
      final score = _scoreNameCandidate(candidate);
      print('  => Score: $score');
      if (score > bestNameScore) {
        bestNameScore = score;
        bestName = candidate.replaceAll(RegExp(r'[^A-Za-z\s]'), '').trim().toUpperCase();
      }
    }
    
    // Score alamat
    print('\n--- ADDRESS SCORING ---');
    for (final candidate in candidates) {
      final cleanedCandidate = candidate.replaceAll(RegExp(r'[^A-Za-z\s]'), '').trim().toUpperCase();
      if (cleanedCandidate == bestName) {
        print('Checking: "$candidate" => SKIP (same as name)');
        continue;
      }
      
      print('Checking: "$candidate"');
      final score = _scoreAddressCandidate(candidate);
      print('  => Score: $score');
      if (score > bestAddressScore) {
        bestAddressScore = score;
        bestAddress = candidate.replaceAll(RegExp(r'^[^A-Za-z0-9]+'), '').trim().toUpperCase();
      }
    }

    print('\n========== HASIL ==========');
    print('Nama: $bestName (score: $bestNameScore)');
    print('Alamat: $bestAddress (score: $bestAddressScore)');
    print('Tanggal Lahir: $bestDate');
    print('============================');

    return {
      'nama': bestName,
      'alamat': bestAddress,
      'tanggal_lahir': bestDate,
    };
  }

  // ============================
  // PARSE WITH CONFIDENCE
  // ============================
  static Map<String, dynamic> parseCustomerDataWithConfidence(String text) {
    final result = parseCustomerData(text);

    double nameConfidence = result['nama']!.isNotEmpty ? 
                           (result['nama']!.split(' ').length >= 2 ? 0.9 : 0.7) : 0.0;
    double addressConfidence = result['alamat']!.isNotEmpty ? 0.7 : 0.0;
    double dateConfidence = RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(result['tanggal_lahir']!) ? 0.9 : 0.0;

    double overallConfidence = (nameConfidence + addressConfidence + dateConfidence) / 3;

    return {
      'data': result,
      'confidence': {
        'nama': nameConfidence,
        'alamat': addressConfidence,
        'tanggal_lahir': dateConfidence,
        'overall': overallConfidence,
      }
    };
  }

  // ============================
  // VALIDATE KTP DATA
  // ============================
  static Map<String, String> validateKTPData(Map<String, String> data) {
    Map<String, String> errors = {};

    if ((data['nama'] ?? '').isEmpty) {
      errors['nama'] = 'Nama tidak boleh kosong';
    }
    if ((data['alamat'] ?? '').isEmpty) {
      errors['alamat'] = 'Alamat tidak boleh kosong';
    }
    
    String tanggalLahir = data['tanggal_lahir'] ?? '';
    if (tanggalLahir.isNotEmpty) {
      if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(tanggalLahir)) {
        errors['tanggal_lahir'] = 'Format tanggal lahir tidak valid';
      }
    }

    return errors;
  }

  // ============================
  // DEBUG METHOD
  // ============================
  static Future<Map<String, dynamic>> extractWithDebug(File imageFile) async {
    final rawText = await extractText(imageFile);

    try {
      final parsed = parseCustomerDataWithConfidence(rawText);
      return {
        'success': true,
        'rawText': rawText,
        'data': parsed['data'],
        'confidence': parsed['confidence'],
      };
    } catch (e) {
      return {
        'success': false,
        'rawText': rawText,
        'error': e.toString(),
      };
    }
  }

  // ============================
  // DISPOSE
  // ============================
  static void dispose() {
    _textRecognizer.close();
  }
}