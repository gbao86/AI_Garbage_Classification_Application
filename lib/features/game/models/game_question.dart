enum WasteCategory { recyclable, organic, hazardous, trash }

class GameQuestion {
  final String imagePath;
  final String name;
  final WasteCategory correctCategory;
  final String funFact;

  GameQuestion({
    required this.imagePath,
    required this.name,
    required this.correctCategory,
    required this.funFact,
  });
}
