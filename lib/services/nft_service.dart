import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import '../config/app_config.dart';
import 'auth_service.dart';

class NftService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService = AuthService();
  final Logger logger = Logger();

  Future<Map<String, dynamic>> mintNft(File file, String category) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    logger.i('Preparing to mint NFT from file: ${file.path}, category: $category');
    
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/nft/mint'),
      );

      // Add auth header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add category field
      request.fields['category'] = category;
      
      // Add file
      final fileExtension = file.path.split('.').last.toLowerCase();
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      logger.i('File details: extension=$fileExtension, mimeType=$mimeType');
      
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mimeType != null ? http_parser.MediaType.parse(mimeType) : null,
      ));

      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      logger.i('Mint NFT response: ${response.statusCode} - $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else {
        final errorMessage = _parseError(responseBody, response.statusCode);
        throw Exception('Failed to mint NFT: $errorMessage');
      }
    } catch (e) {
      logger.e('Error minting NFT: $e');
      throw Exception('Failed to mint NFT: $e');
    }
  }

  String _parseError(String responseBody, int statusCode) {
    try {
      final body = jsonDecode(responseBody);
      return body['message'] ?? 'Unknown error (status: $statusCode)';
    } catch (_) {
      return 'Unknown error (status: $statusCode)';
    }
  }
} 