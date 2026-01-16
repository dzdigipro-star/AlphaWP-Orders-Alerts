import 'dart:convert';

class Site {
  final String name;
  final String url;
  final String apiKey;
  final String currency;

  Site({
    required this.name,
    required this.url,
    required this.apiKey,
    this.currency = 'DZD',
  });

  String get apiUrl => url.endsWith('/') 
      ? '${url}wp-json/alphawp/v1'
      : '$url/wp-json/alphawp/v1';

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'apiKey': apiKey,
    'currency': currency,
  };

  factory Site.fromJson(Map<String, dynamic> json) => Site(
    name: json['name'],
    url: json['url'],
    apiKey: json['apiKey'],
    currency: json['currency'] ?? 'DZD',
  );

  String toJsonString() => jsonEncode(toJson());
  
  factory Site.fromJsonString(String json) => Site.fromJson(jsonDecode(json));
}
