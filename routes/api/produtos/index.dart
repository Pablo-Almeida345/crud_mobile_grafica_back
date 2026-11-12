import 'dart:io';
import 'package:crud_mobile_grafica_back/models/produtos.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method.value.toUpperCase();
  switch (method) {
    case 'GET':
      return _getProdutos(context);
    case 'POST':
      return _cadastrarProduto(context);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

// 🟢 GET: Buscar todos os produtos
Future<Response> _getProdutos(RequestContext context) async {
  try {
    final supabase = context.read<SupabaseClient?>();
    if (supabase == null) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'erro': 'Cliente do Supabase não disponível.'},
      );
    }

    final response = await supabase
        .from('produto')
        .select()
        .order('id', ascending: false);

    // BLINDAGEM DA LINHA 36: Garante que o response é tratado como lista com segurança
    final data = response;
    if (data is! List) {
      return Response.json(body: []);
    }

    final listaProdutos = data.map((item) {
      return Produto.fromJson(item as Map<String, dynamic>).toJson();
    }).toList();

    return Response.json(body: listaProdutos);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'erro': 'Erro ao buscar produtos: ${e.toString()}'},
    );
  }
}

// 🔵 POST: Cadastrar novo produto
Future<Response> _cadastrarProduto(RequestContext context) async {
  try {
    final supabase = context.read<SupabaseClient?>();
    if (supabase == null) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'erro': 'Cliente do Supabase não disponível.'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    
    // Insere no Supabase e obtém o registo inserido de volta
    final response = await supabase
        .from('produto')
        .insert({
          'nome': body['nome'],
          'descricao': body['descricao'],
          'preco': body['preco'],
          'imagem_url': body['imagemUrl'] ?? body['imagem_url'],
        })
        .select()
        .single();

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'mensagem': 'Produto cadastrado com sucesso!',
        'produto': response,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'erro': 'Erro ao cadastrar produto: ${e.toString()}'},
    );
  }
}