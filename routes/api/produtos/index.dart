import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

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
  // Converte o método da requisição para string maiúscula (ex: 'GET', 'POST')
  final method = context.request.method.name.toUpperCase();

  switch (method) {
    // GET - Listar todos os produtos
    case 'GET':
      return _getProdutos(context);

    // POST - Cadastrar um novo produto
    case 'POST':
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

Future<Response> _getProdutos(RequestContext context) async {
  try {
    final supabase = context.read<SupabaseClient>();
    if (supabase == null) {
      return respostaErro(
        HttpStatus.internalServerError,
        'Cliente do Supabase não disponível.',
      );
    }

    final response = await supabase
        .from('produto')
        .select()
        .order('id', ascending: false);

    final data = response;
    if (data is! List) {
      return Response.json(body: []);
    }

    return Response.json(
      statusCode: HttpStatus.ok,
      body: data,
    );
  } catch (e) {
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

Future<Response> _cadastrarProduto(RequestContext context) async {
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

  if (dados is! Map<String, dynamic>) {
    return respostaErro(
      HttpStatus.badRequest,
      'Formato de dados inválido!',
    );
  }

  // ==========================================
  // VALIDAÇÕES DOS CAMPOS
  // ==========================================

  final nomeInformado = dados['nome'];
  if (nomeInformado is! String || nomeInformado.trim().isEmpty) {
    return respostaErro(
      HttpStatus.badRequest,
      'O nome do produto é obrigatório!',
    );
  }
  final nome = nomeInformado.trim();

  final descricaoInformada = dados['descricao'];
  if (descricaoInformada is! String || descricaoInformada.trim().isEmpty) {
    return respostaErro(
      HttpStatus.badRequest,
      'A descrição do produto é obrigatória!',
    );
  }
  final descricao = descricaoInformada.trim();

  final precoInformado = dados['preco'];
  final double? preco = precoInformado is num
      ? precoInformado.toDouble()
      : precoInformado is String
          ? double.tryParse(precoInformado.trim())
          : null;

  if (preco == null || !preco.isFinite || preco <= 0) {
    return respostaErro(
      HttpStatus.badRequest,
      'O preço deve ser um número maior que zero!',
    );
  }

  final imagemInformada = dados['imagemUrl'] ?? dados['imagem_url'];
  if (imagemInformada != null && imagemInformada is! String) {
    return respostaErro(
      HttpStatus.badRequest,
      'A URL da imagem deve ser um texto!',
    );
  }

  final String? imagemUrl =
      imagemInformada is String && imagemInformada.trim().isNotEmpty
          ? imagemInformada.trim()
          : null;

  // ==========================================
  // INSERÇÃO NO SUPABASE
  // ==========================================

  try {
    final supabase = context.read<SupabaseClient>();
    if (supabase == null) {
      return respostaErro(
        HttpStatus.internalServerError,
        'Cliente do Supabase não disponível.',
      );
    }

    final response = await supabase
        .from('produto')
        .insert({
          'nome': nome,
          'descricao': descricao,
          'preco': preco,
          'imagem_url': imagemUrl,
        })
        .select()
        .single();

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'sucesso': true,
        'mensagem': 'Produto cadastrado com sucesso!',
        'produto': response,
      },
    );
  } catch (e) {
    print('Erro ao cadastrar produto: $e');
    return respostaErro(
      HttpStatus.internalServerError,
      'Erro interno ao cadastrar produto.',
    );
  }
}