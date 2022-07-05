class PerimeterStyle {
  final String fillColor, borderColor;
  final int borderThickness;
  final double fillColorOpacity;

  PerimeterStyle.fromMap(Map<String, dynamic> map)
      : fillColor = map['fillColor'] as String,
        borderColor = map['borderColor'] as String,
        borderThickness = map['borderWeight'] as int,
        fillColorOpacity = map['fillColorOpacity'] as double;

  Map<String, dynamic> toMap() {
    return {
      'fillColor': fillColor,
      'borderColor': borderColor,
      'borderWeight': borderThickness,
      'fillColorOpacity': fillColorOpacity,
    };
  }
}
