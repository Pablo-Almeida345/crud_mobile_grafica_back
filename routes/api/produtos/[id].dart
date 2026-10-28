import 'dart:io';
import 'package:crud_mobile_grafica_back/models/produtos.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final idProduto = int.tryParse(id);
  if (idProduto == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'erro': 'ID do produto inválido'},
    );
  }

  switch (context.request.method) {
    case HttpMethod.put:
      return _atualizarProduto(context, idProduto);
    case HttpMethod.delete:
      return _deletarProduto(context, idProduto);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

// 🟡 PUT: Atualizar produto existente
Future<Response> _atualizarProduto(RequestContext context, int id) async {
  try {
    final connection = context.read<Connection?>();
    if (connection == null) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'erro': 'Conexão com o banco de dados não disponível.'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final produto = Produto.fromJson(body);

    await connection.execute(
      Sql.named(
        'UPDATE produto '
        'SET nome = @nome, descricao = @descricao, preco = @preco, imagem_url = @imagemUrl '
        'WHERE id = @id',
      ),
      parameters: {
        'id': id,
        'nome': produto.nome,
        'descricao': produto.descricao,
        'preco': produto.preco,
        'imagemUrl': produto.imagemUrl,
      },
    );

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
    final connection = context.read<Connection?>();
    if (connection == null) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'erro': 'Conexão com o banco de dados não disponível.'},
      );
    }

    await connection.execute(
      Sql.named('DELETE FROM produto WHERE id = @id'),
      parameters: {'id': id},
    );

    return Response.json(body: {'mensagem': 'Produto excluído com sucesso!'});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'erro': 'Erro ao excluir produto: ${e.toString()}'},
    );
  }
}