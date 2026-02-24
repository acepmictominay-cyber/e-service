import 'package:flutter_test/flutter_test.dart';
import 'package:azza_service/services/ocr_service.dart';

void main() {
  test('OCR sample text parsing recovers name, kel_desa and birth date', () {
    final res = OCRService.testParseWithSampleText();
    expect(res['success'], true);
    final data = res['data']['data'] as Map<String, dynamic>;

    // Check recovered fields
    expect(data['nama'], 'ACEP');
    expect(data['kel_desa'], 'DUSUN KARANGJAYA');
    expect(data['tanggal_lahir'], '01-07-2004');
  });
}
