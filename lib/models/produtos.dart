class Produto {
  final int? id;
  final String nome;
  final String descricao;
  final double preco;
  final String imagemUrl;

  Produto({
    this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.imagemUrl,
  });

  // Converte JSON para o objeto Produto
  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      preco: (json['preco'] is num)
          ? (json['preco'] as num).toDouble()
          : double.parse(json['preco'].toString()),
      imagemUrl: json['imagem_url'] as String? ?? json['imagemUrl'] as String? ?? '',
    );
  }

  // Converte o objeto Produto para JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'imagem_url': imagemUrl,
    };
  }
}