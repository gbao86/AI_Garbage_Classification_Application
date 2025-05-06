import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String apiKey = "AIzaSyCEawrryXy86_ZVZokFIXng3Lo5Oak21QA";

Future<String> analyzeImageWithGemini(String imagePath) async {
  try {
    String base64Image = base64Encode(await File(imagePath).readAsBytes());

    var response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=$apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"inlineData": {"mimeType": "image/png", "data": base64Image}},
              {"text": "Phân tích loại rác trong ảnh và cách xử lý."}
            ]
          }
        ]
      }),
    );

    return response.statusCode == 200
        ? jsonDecode(response.body)["candidates"][0]["content"]["parts"][0]["text"]
        : "Lỗi: ${response.statusCode} - ${response.body}";
  } catch (e) {
    return "Lỗi xử lý ảnh: $e";
  }
}
