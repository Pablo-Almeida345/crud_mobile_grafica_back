import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

// Função para padronizar erros
Response respostaErro(int statusCode, String mensagem) {
  return Response.json(
    statusCode: statusCode,
    body: {
      'sucesso': false,
      'mensagem': mensagem,
    },
  );
}

// Rota principal dos produtos (GET e POST)
Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method.name.toUpperCase();

  switch (method) {
    case 'GET':
      return _getProdutos(context);
    case 'POST':
      return _cadastrarProduto(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        headers: {'allow': 'GET, POST'},
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
    final response = await supabase.from('produto').select();

    return Response.json(
      statusCode: HttpStatus.ok,
      body: response,
    );
  } catch (e) {
    print('Erro ao buscar produtos: $e');
    return respostaErro(
      HttpStatus.internalServerError,
      'Erro interno ao buscar produtos: $e',
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
    return respostaErro(HttpStatus.badRequest, 'JSON inválido!');
  } catch (_) {
    return respostaErro(HttpStatus.badRequest, 'Não foi possível ler os dados enviados.');
  }

  if (dados is! Map<String, dynamic>) {
    return respostaErro(HttpStatus.badRequest, 'Formato de dados inválido!');
  }

  // Validação do nome
  final nome = dados['nome']?.toString().trim() ?? '';
  if (nome.isEmpty) {
    return respostaErro(HttpStatus.badRequest, 'O nome do produto é obrigatório!');
  }

  // Descrição
  final descricao = dados['descricao']?.toString().trim() ?? '';

  // Validação do preço
  final precoInformado = dados['preco'];
  final double? preco = precoInformado is num
      ? precoInformado.toDouble()
      : precoInformado is String
          ? double.tryParse(precoInformado.trim())
          : null;

  if (preco == null || !preco.isFinite || preco <= 0) {
    return respostaErro(HttpStatus.badRequest, 'O preço deve ser um número maior que zero!');
  }

  // Imagem (coluna "imagem")
  final imagem = dados['imagem']?.toString().trim();

  // Categoria
  final categoria = dados['categoria']?.toString().trim();

  // Ativo (padrão true se não enviado)
  final ativo = dados['ativo'] is bool ? dados['ativo'] : true;

  try {
    final supabase = context.read<SupabaseClient>();
    final produtoId = uuid.v4();

    // Insere na tabela "produto" com todas as colunas exatas
    await supabase.from('produto').insert({
      'id': produtoId,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'imagem': imagem,
      'categoria': categoria,
      'ativo': ativo,
    });

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'sucesso': true,
        'mensagem': 'Produto cadastrado com sucesso!',
        'produto': {
          'id': produtoId,
          'nome': nome,
          'descricao': descricao,
          'preco': preco,
          'imagem': imagem,
          'categoria': categoria,
          'ativo': ativo,
        },
      },
    );
  } catch (e) {
    print('Erro ao cadastrar produto: $e');
    return respostaErro(
      HttpStatus.internalServerError,
      'Erro interno ao cadastrar produto: $e',
    );
  }
}