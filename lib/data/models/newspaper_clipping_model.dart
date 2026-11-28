import 'package:flutter/material.dart';

class NewspaperClippingModel {
  final String id;
  final String title;
  final String titleMarathi;
  final String newspaper; // 'Sakal' | 'Lokmat' | 'Maharashtra Times' | 'Pudhari' | 'Loksatta' | 'The Indian Express'
  final String date;
  final String sentiment; // 'positive' | 'negative'
  final String imageUrl;
  final String? pageNumber;
  final String? edition;
  final String description;
  final String descriptionMarathi;
  final String? actionTaken;
  final String? journalistName;

  const NewspaperClippingModel({
    required this.id,
    required this.title,
    required this.titleMarathi,
    required this.newspaper,
    required this.date,
    required this.sentiment,
    required this.imageUrl,
    this.pageNumber = 'Page 3',
    this.edition = 'Pune City Edition',
    required this.description,
    required this.descriptionMarathi,
    this.actionTaken,
    this.journalistName,
  });

  bool get isPositive => sentiment.toLowerCase() == 'positive';

  Color get sentimentColor =>
      isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

  Color get sentimentBgColor =>
      isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);

  String get sentimentLabelMarathi =>
      isPositive ? 'सकारात्मक बातमी' : 'नकारात्मक बातमी';

  String get sentimentLabelEnglish =>
      isPositive ? 'Positive News' : 'Negative News';

  String get sentimentLabelHindi =>
      isPositive ? 'सकारात्मक समाचार' : 'नकारात्मक समाचार';

  String sentimentLabel(String lang) {
    if (lang == 'mr') return sentimentLabelMarathi;
    if (lang == 'hi') return sentimentLabelHindi;
    return sentimentLabelEnglish;
  }

  String titleFor(String lang) {
    if (lang == 'mr' && titleMarathi.trim().isNotEmpty) return titleMarathi;
    return title.trim().isNotEmpty ? title : titleMarathi;
  }

  String descriptionFor(String lang) {
    if (lang == 'mr' && descriptionMarathi.trim().isNotEmpty) {
      return descriptionMarathi;
    }
    return description.trim().isNotEmpty ? description : descriptionMarathi;
  }

  Color get newspaperBrandColor {
    switch (newspaper.toLowerCase()) {
      case 'sakal':
      case 'सकाळ':
        return const Color(0xFF0284C7); // Blue
      case 'lokmat':
      case 'लोकमत':
        return const Color(0xFFDC2626); // Red
      case 'maharashtra times':
      case 'महाराष्ट्र टाइम्स':
        return const Color(0xFFEA580C); // Orange
      case 'pudhari':
      case 'पुढारी':
        return const Color(0xFFB91C1C); // Deep Red
      case 'loksatta':
      case 'लोकसत्ता':
        return const Color(0xFF7C3AED); // Purple
      default:
        return const Color(0xFF334155); // Slate
    }
  }

  NewspaperClippingModel copyWith({
    String? id,
    String? title,
    String? titleMarathi,
    String? newspaper,
    String? date,
    String? sentiment,
    String? imageUrl,
    String? pageNumber,
    String? edition,
    String? description,
    String? descriptionMarathi,
    String? actionTaken,
    String? journalistName,
  }) {
    return NewspaperClippingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      titleMarathi: titleMarathi ?? this.titleMarathi,
      newspaper: newspaper ?? this.newspaper,
      date: date ?? this.date,
      sentiment: sentiment ?? this.sentiment,
      imageUrl: imageUrl ?? this.imageUrl,
      pageNumber: pageNumber ?? this.pageNumber,
      edition: edition ?? this.edition,
      description: description ?? this.description,
      descriptionMarathi: descriptionMarathi ?? this.descriptionMarathi,
      actionTaken: actionTaken ?? this.actionTaken,
      journalistName: journalistName ?? this.journalistName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'titleMarathi': titleMarathi,
      'newspaper': newspaper,
      'date': date,
      'sentiment': sentiment,
      'imageUrl': imageUrl,
      'pageNumber': pageNumber,
      'edition': edition,
      'description': description,
      'descriptionMarathi': descriptionMarathi,
      'actionTaken': actionTaken,
      'journalistName': journalistName,
    };
  }

  factory NewspaperClippingModel.fromJson(Map<String, dynamic> json) {
    return NewspaperClippingModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      titleMarathi: json['title_marathi'] ?? json['titleMarathi'] ?? json['title'] ?? '',
      newspaper: json['newspaper'] ?? json['source'] ?? 'Sakal',
      date: json['date'] ?? json['created_at']?.toString().split('T').first ?? '',
      sentiment: json['sentiment'] ?? 'positive',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      pageNumber: json['page_number'] ?? json['pageNumber'] ?? 'Page 3',
      edition: json['edition'] ?? 'Pune City Edition',
      description: json['description'] ?? '',
      descriptionMarathi: json['description_marathi'] ?? json['descriptionMarathi'] ?? json['description'] ?? '',
      actionTaken: json['action_taken'] ?? json['actionTaken'],
      journalistName: json['journalist_name'] ?? json['journalistName'],
    );
  }
}

