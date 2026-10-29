
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

// ==========================================
// FUNÇÃO PARA PADRONIZAR ERROS
// ==========================================

Response respostaErro(int statusCode, String mensagem) {
  return Response.json(
    statusCode: statusCode,
    body: {
      'sucesso': false,
      'mensagem': mensagem,
    },
  );
}

// ==========================================
// ROTA PRINCIPAL DOS PRODUTOS
// ==========================================

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {

    // GET - Listar todos os produtos
    case HttpMethod.get:
      return _getProdutos(context);

    // POST - Cadastrar um novo produto
    case HttpMethod.post:
      return _cadastrarProduto(context);

    // Outros métodos não são permitidos
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        headers: {
          'allow': 'GET, POST',
        },
        body: {
          'sucesso': false,
          'mensagem': 'Método não permitido.',
        },
      );
  }
}

// ==========================================
// GET - BUSCAR TODOS OS PRODUTOS
// ==========================================

Future<Response> _getProdutos(
  RequestContext context,
) async {
  try {
    // Recupera a conexão do middleware
    final connection = context.read<Connection?>();

    // Verifica se existe conexão com o banco
    if (connection == null) {
      return respostaErro(
        HttpStatus.internalServerError,
        'Conexão com o banco de dados indisponível.',
      );
    }

    // Busca os produtos no PostgreSQL
    final resultado = await connection.execute(
      '''
      SELECT
        id,
        nome,
        descricao,
        preco,
        imagem_url
      FROM produto
      ORDER BY id DESC
      ''',
    );

    // Converte os registros para JSON
    final listaProdutos = resultado.map((row) {

      // Recupera os dados do banco
      final id = row[0] as int;

      final nome = row[1]?.toString() ?? '';

      final descricao = row[2]?.toString() ?? '';

      final preco = double.parse(
        row[3].toString(),
      );

      final imagemUrl = row[4]?.toString();

      // Retorna cada produto como objeto JSON
      return {
        'id': id,
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
        'imagemUrl': imagemUrl,
      };
    }).toList();

    // Retorna todos os produtos
    return Response.json(
      statusCode: HttpStatus.ok,
      body: listaProdutos,
    );

  } catch (e) {
    // Exibe o erro no terminal do servidor
    print('Erro ao buscar produtos: $e');

    return respostaErro(
      HttpStatus.internalServerError,
      'Erro interno ao buscar produtos.',
    );
  }
}

// ==========================================
// POST - CADASTRAR NOVO PRODUTO
// ==========================================

Future<Response> _cadastrarProduto(
  RequestContext context,
) async {

  // Recupera os dados enviados pelo frontend
  dynamic dados;

  try {
    dados = await context.request.json();
  } on FormatException {
    return respostaErro(
      HttpStatus.badRequest,
      'JSON inválido!',
    );
  } catch (e) {
    return respostaErro(
      HttpStatus.badRequest,
      'Não foi possível ler os dados enviados.',
    );
  }

  // Verifica se os dados estão no formato correto
  if (dados is! Map<String, dynamic>) {
    return respostaErro(
      HttpStatus.badRequest,
      'Formato de dados inválido!',
    );
  }

  // ==========================================
  // VALIDAÇÃO DO NOME
  // ==========================================

  final nomeInformado = dados['nome'];

  if (nomeInformado is! String ||
      nomeInformado.trim().isEmpty) {
    return respostaErro(
      HttpStatus.badRequest,
      'O nome do produto é obrigatório!',
    );
  }

  final nome = nomeInformado.trim();

  // ==========================================
  // VALIDAÇÃO DA DESCRIÇÃO
  // ==========================================

  final descricaoInformada = dados['descricao'];

  if (descricaoInformada is! String ||
      descricaoInformada.trim().isEmpty) {
    return respostaErro(
      HttpStatus.badRequest,
      'A descrição do produto é obrigatória!',
    );
  }

  final descricao = descricaoInformada.trim();

  // ==========================================
  // VALIDAÇÃO DO PREÇO
  // ==========================================

  final precoInformado = dados['preco'];

  // Converte o preço para double
  final double? preco = precoInformado is num
      ? precoInformado.toDouble()
      : precoInformado is String
          ? double.tryParse(precoInformado.trim())
          : null;

  // Verifica se o preço é válido
  if (preco == null ||
      !preco.isFinite ||
      preco <= 0) {
    return respostaErro(
      HttpStatus.badRequest,
      'O preço deve ser um número maior que zero!',
    );
  }

  // ==========================================
  // VALIDAÇÃO DA IMAGEM
  // ==========================================

  // Aceita imagemUrl ou imagem_url
  final imagemInformada =
      dados['imagemUrl'] ?? dados['imagem_url'];

  if (imagemInformada != null &&
      imagemInformada is! String) {
    return respostaErro(
      HttpStatus.badRequest,
      'A URL da imagem deve ser um texto!',
    );
  }

  // A imagem é opcional
  final String? imagemUrl =
      imagemInformada is String &&
              imagemInformada.trim().isNotEmpty
          ? imagemInformada.trim()
          : null;

  // ==========================================
  // INSERÇÃO NO BANCO DE DADOS
  // ==========================================

  try {
    // Recupera a conexão fornecida pelo middleware
    final connection = context.read<Connection?>();

    // Verifica se a conexão está disponível
    if (connection == null) {
      return respostaErro(
        HttpStatus.internalServerError,
        'Conexão com o banco de dados indisponível.',
      );
    }

    // Insere o produto na tabela produto
    final resultado = await connection.execute(
      Sql.named('''
        INSERT INTO produto (
          nome,
          descricao,
          preco,
          imagem_url
        )
        VALUES (
          @nome,
          @descricao,
          @preco,
          @imagemUrl
        )
        RETURNING id
      '''),
      parameters: {
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
        'imagemUrl': imagemUrl,
      },
    );

    // Recupera o ID gerado pelo PostgreSQL
    final idGerado = resultado.first[0] as int;

    // ==========================================
    // RETORNO DE SUCESSO
    // ==========================================

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'sucesso': true,
        'mensagem': 'Produto cadastrado com sucesso!',
        'id': idGerado,
        'produto': {
          'id': idGerado,
          'nome': nome,
          'descricao': descricao,
          'preco': preco,
          'imagemUrl': imagemUrl,
        },
      },
    );

  } catch (e) {
    // Registra o erro no terminal
    print('Erro ao cadastrar produto: $e');

    // Retorna uma mensagem segura ao frontend
    return respostaErro(
      HttpStatus.internalServerError,
      'Erro interno ao cadastrar produto.',
    );
  }
}
