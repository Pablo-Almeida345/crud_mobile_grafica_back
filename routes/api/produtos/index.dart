import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart'; // Importa o gerador de UUID

const uuid = Uuid(); // Instância do gerador de UUID
List<Map<String, dynamic>> produtosBD = [];

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;

  if (method == HttpMethod.post) {
    final body = await context.request.json() as Map<String, dynamic>;
    
    // Gera um ID único em formato UUID v4 (ex: "f81d4fae-7dec-11d0-a765-00a0c91e6bf6")
    final String id = uuid.v4();
    
    final novoProduto = {
      'id': id,
      'nome': body['nome'],
      'preco': body['preco'],
      'estoque': body['estoque'],
    };

    produtosBD.add(novoProduto);

    return Response.json(
      statusCode: 201,
      body: {'mensagem': 'Produto cadastrado com sucesso!', 'produto': novoProduto},
    );
  }

  if (method == HttpMethod.get) {
    return Response.json(statusCode: 200, body: produtosBD);
  }

  return Response.json(statusCode: 405, body: {'erro': 'Método não permitido'});
}