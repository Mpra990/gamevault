class AppUser {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  AppUser({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      criadoEm: DateTime.parse(json['criado_em']),
      atualizadoEm: DateTime.parse(json['atualizado_em']),
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'username': username,
    'avatar_url': avatarUrl,
  };
}

enum StatusJogoEnum {
  queroJogar('quero_jogar'),
  jogando('jogando'),
  zerado('zerado'),
  platinado('platinado'),
  abandonado('abandonado'),
  pausado('pausado');

  final String value;
  const StatusJogoEnum(this.value);
}

class StatusJogo {
  final String id;
  final String usuarioId;
  final int rawgGameId;
  final String? rawgSlug;
  final StatusJogoEnum status;
  final DateTime atualizadoEm;

  StatusJogo({
    required this.id,
    required this.usuarioId,
    required this.rawgGameId,
    this.rawgSlug,
    required this.status,
    required this.atualizadoEm,
  });

  factory StatusJogo.fromJson(Map<String, dynamic> json) {
    return StatusJogo(
      id: json['id'],
      usuarioId: json['usuario_id'],
      rawgGameId: json['rawg_game_id'],
      rawgSlug: json['rawg_slug'],
      status: StatusJogoEnum.values.firstWhere(
        (e) => e.value == json['status'],
      ),
      atualizadoEm: DateTime.parse(json['atualizado_em']),
    );
  }

  Map<String, dynamic> toJson() => {
    'usuario_id': usuarioId,
    'rawg_game_id': rawgGameId,
    'rawg_slug': rawgSlug,
    'status': status.value,
  };
}

class Wishlist {
  final String id;
  final String usuarioId;
  final int rawgGameId;
  final String? rawgSlug;
  final DateTime adicionadoEm;

  Wishlist({
    required this.id,
    required this.usuarioId,
    required this.rawgGameId,
    this.rawgSlug,
    required this.adicionadoEm,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['id'],
      usuarioId: json['usuario_id'],
      rawgGameId: json['rawg_game_id'],
      rawgSlug: json['rawg_slug'],
      adicionadoEm: DateTime.parse(json['adicionado_em']),
    );
  }

  Map<String, dynamic> toJson() => {
    'usuario_id': usuarioId,
    'rawg_game_id': rawgGameId,
    'rawg_slug': rawgSlug,
  };
}

class Avaliacao {
  final String id;
  final String usuarioId;
  final int rawgGameId;
  final String? rawgSlug;
  final int nota;
  final String? comentario;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  Avaliacao({
    required this.id,
    required this.usuarioId,
    required this.rawgGameId,
    this.rawgSlug,
    required this.nota,
    this.comentario,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      id: json['id'],
      usuarioId: json['usuario_id'],
      rawgGameId: json['rawg_game_id'],
      rawgSlug: json['rawg_slug'],
      nota: json['nota'],
      comentario: json['comentario'],
      criadoEm: DateTime.parse(json['criado_em']),
      atualizadoEm: DateTime.parse(json['atualizado_em']),
    );
  }

  Map<String, dynamic> toJson() => {
    'usuario_id': usuarioId,
    'rawg_game_id': rawgGameId,
    'rawg_slug': rawgSlug,
    'nota': nota,
    'comentario': comentario,
  };
}
