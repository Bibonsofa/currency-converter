import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/currency.dart';

class ApiService {
  static const String baseUrl = 'https://www.cbr.ru/scripts/XML_daily.asp';

  Future<List<Currency>> fetchCurrencies() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        return _parseXmlResponse(response.body);
      } else {
        throw Exception('Ошибка загрузки данных: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка подключения: $e');
    }
  }

  List<Currency> _parseXmlResponse(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final valutes = document.findAllElements('Valute');
    
    List<Currency> currencies = [];
    
    currencies.add(Currency(
      id: 'RUB',
      numCode: '643',
      charCode: 'RUB',
      nominal: 1,
      name: 'Российский рубль',
      value: 1.0,
    ));
    
    for (var valute in valutes) {
      final data = <String, String>{};
      for (var element in valute.children.whereType<XmlElement>()) {
        data[element.name.local] = element.innerText;
      }
      currencies.add(Currency.fromXml(data));
    }
    
    currencies.sort((a, b) => a.name.compareTo(b.name));
    return currencies;
  }
}
