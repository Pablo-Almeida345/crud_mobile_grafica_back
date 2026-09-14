import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'index.dart'; // Importa a lista 'produtosBD'

Future<Response> onRequest(RequestContext context, String id) async {
  final method = context.request.method;
  
  // Como o ID agora é um UUID (String), procuramos diretamente pelo texto correspondente
  final produtoIndex = produtosBD.indexWhere((p) => p['id'] == id);

  if (produtoIndex == -1) {
    return Response.json(statusCode: 404, body: {'erro': 'Produto não encontrado'});
  }

  // 1. ATUALIZAÇÃO / UPDATE DE PRODUTO (PUT)
  if (method == HttpMethod.put) {
    final body = await context.request.json() as Map<String, dynamic>;

    produtosBD[produtoIndex] = {
      'id': id, // Mantém o UUID original
      'nome': body['nome'] ?? produtosBD[produtoIndex]['nome'],
      'preco': body['preco'] ?? produtosBD[produtoIndex]['preco'],
      'estoque': body['estoque'] ?? produtosBD[produtoIndex]['estoque'],
    };

    return Response.json(
      statusCode: 200,
      body: {'mensagem': 'Produto atualizado com sucesso!', 'produto': produtosBD[produtoIndex]},
    );
  }

  // 2. DELEÇÃO DE PRODUTO (DELETE)
  if (method == HttpMethod.delete) {
    produtosBD.removeAt(produtoIndex);

    return Response.json(
      statusCode: 200,
      body: {'mensagem': 'Produto deletado com sucesso!'},
    );
  }

  return Response.json(statusCode: 405, body: {'erro': 'Método não permitido'});
}