import 'package:http/http.dart' as http;

void main() async {
  final ids = ['ar.saadghamidi', 'ar.abdurrahmaansudais', 'ar.sudais', 'ar.hanirifai', 'ar.abdulsamad'];
  for (final id in ids) {
    final url = "https://cdn.islamic.network/quran/audio/128/$id/1.mp3";
    final resp = await http.head(Uri.parse(url));
    print("$id: ${resp.statusCode}");
  }
}
