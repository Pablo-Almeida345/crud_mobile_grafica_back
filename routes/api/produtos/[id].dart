import 'dart:io';
import 'package:crud_mobile_grafica_back/models/produtos.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final idProduto = int.tryParse(id);
  if (idProduto == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'erro': 'ID do produto inválido'},
    );
  }

  final method = context.request.method.value.toUpperCase();
  switch (method) {
    case 'PUT':
      return _atualizarProduto(context, idProduto);
    case 'DELETE':
      return _deletarProduto(context, idProduto);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

// 🟡 PUT: Atualizar produto existente
Future<Response> _atualizarProduto(RequestContext context, int id) async {
  try {
    final supabase = context.read<SupabaseClient?>();
    if (supabase == null) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'erro': 'Cliente do Supabase não disponível.'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final produto = Produto.fromJson(body);

    await supabase
        .from('produto')
        .update({
          'nome': produto.nome,
          'descricao': produto.descricao,
          'preco': produto.preco,
          'imagem_url': produto.imagemUrl,
        })
        .eq('id', id);

    return Response.json(body: {'mensagem': 'Produto atualizado com sucesso!'});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'erro': 'Erro ao atualizar produto: ${e.toString()}'},
    );
  }
}

// 🔴 DELETE: Excluir produto por ID
Future<Response> _deletarProduto(RequestContext context, int id) async {
  try {
    final supabase = context.read<SupabaseClient?>();
    if (supabase == null) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'erro': 'Cliente do Supabase não disponível.'},
      );
    }

    await supabase
        .from('produto')
        .delete()
        .eq('id', id);

    return Response.json(body: {'mensagem': 'Produto excluído com sucesso!'});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'erro': 'Erro ao excluir produto: ${e.toString()}'},
    );
  }
}