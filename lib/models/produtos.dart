class Produto {
  // Identificador único do produto (suporta tanto inteiro quanto String/UUID para flexibilidade com o Supabase)
  final dynamic id;

  // Nome do produto
  final String nome;

  // Descrição do produto
  final String descricao;

  // Preço do produto
  final double preco;

  // URL da imagem (opcional)
  final String? imagemUrl;

  // Construtor da classe Produto
  const Produto({
    this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    this.imagemUrl,
  });

  // ==========================================
  // CONVERTER JSON PARA OBJETO PRODUTO
  // ==========================================

  factory Produto.fromJson(Map<String, dynamic> json) {
    // Recupera e valida o ID de forma flexível (aceita int, String ou UUID)
    final dynamic idProduto = json['id'];

    // Recupera e valida o nome
    final nomeInformado = json['nome'];

    if (nomeInformado is! String || nomeInformado.trim().isEmpty) {
      throw const FormatException(
        'O nome do produto é obrigatório!',
      );
    }

    final nomeProduto = nomeInformado.trim();

    // Recupera e valida a descrição
    final descricaoInformada = json['descricao'];

    if (descricaoInformada is! String || descricaoInformada.trim().isEmpty) {
      throw const FormatException(
        'A descrição do produto é obrigatória!',
      );
    }

    final descricaoProduto = descricaoInformada.trim();

    // Recupera e converte o preço
    final precoInformado = json['preco'];

    final double? precoProduto = precoInformado is num
        ? precoInformado.toDouble()
        : precoInformado is String
            ? double.tryParse(precoInformado.trim())
            : null;

    // Verifica se o preço é válido
    if (precoProduto == null || !precoProduto.isFinite || precoProduto <= 0) {
      throw const FormatException(
        'O preço deve ser maior que zero!',
      );
    }

    // Recupera a URL da imagem (aceita imagemUrl e imagem_url)
    final imagemInformada = json['imagemUrl'] ?? json['imagem_url'];

    if (imagemInformada != null && imagemInformada is! String) {
      throw const FormatException(
        'A URL da imagem deve ser um texto!',
      );
    }

    final String? imagemProduto =
        imagemInformada is String && imagemInformada.trim().isNotEmpty
            ? imagemInformada.trim()
            : null;

    // Retorna o objeto Produto validado
    return Produto(
      id: idProduto,
      nome: nomeProduto,
      descricao: descricaoProduto,
      preco: precoProduto,
      imagemUrl: imagemProduto,
    );
  }

  // ==========================================
  // CONVERTER OBJETO PRODUTO PARA JSON
  // ==========================================

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'imagemUrl': imagemUrl,
      'imagem_url': imagemUrl, // Garante compatibilidade com ambas as chaves
    };
  }

  // ==========================================
  // CONVERTER OBJETO PARA O SUPABASE / POSTGRES
  // ==========================================

  Map<String, dynamic> toDatabaseMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'imagem_url': imagemUrl, // Coluna padrão no banco Supabase
    };
  }

  // ==========================================
  // CRIAR CÓPIA DO PRODUTO
  // ==========================================

  Produto copyWith({
    dynamic id,
    String? nome,
    String? descricao,
    double? preco,
    String? imagemUrl,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      imagemUrl: imagemUrl ?? this.imagemUrl,
    );
  }

  // ==========================================
  // REPRESENTAÇÃO DO PRODUTO EM TEXTO
  // ==========================================

  @override
  String toString() {
    return 'Produto('
        'id: $id, '
        'nome: $nome, '
        'descricao: $descricao, '
        'preco: $preco, '
        'imagemUrl: $imagemUrl'
        ')';
  }
}