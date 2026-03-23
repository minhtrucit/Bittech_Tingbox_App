import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_services.dart';

class OcrCorrectionService {
  final ApiService apiService;

  OcrCorrectionService()
    : apiService = ApiService.getInstance(baseUrl: dotenv.get('OCR_API_URL'));

  Future<Response> submitCorrection({
    required String documentId,
    required Map<String, dynamic> correctedData,
  }) async {
    return await apiService.post(
      '/api/corrections/submit',
      data: {'document_id': documentId, 'corrected_data': correctedData},
      options: Options(headers: {'x-api-key': dotenv.get('OCR_API_KEY')}),
    );
  }
}
