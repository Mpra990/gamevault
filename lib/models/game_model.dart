class Game {
  final int id;
  final String name;
  final String backgroundImage;
  final double rating;
  String description;

  Game({
    required this.id,
    required this.name,
    required this.backgroundImage,
    required this.rating,
    this.description = "",
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      name: json['name'],
      backgroundImage:
          json['background_image'] ?? 'https://via.placeholder.com/150',
      rating: (json['metacritic'] ?? 0).toDouble(),
    );
  }
}
