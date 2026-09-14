import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'cadastrar.dart'; // Importa a lista 'administradoresBD' do arquivo de cadastro

Future<Response> onRequest(RequestContext context) async {
  // Garante que a rota aceite apenas requisições POST
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'erro': 'Método não permitido'});
  }

  // Pega os dados enviados no corpo da requisição
  final body = await context.request.json() as Map<String, dynamic>;
  final email = body['email'];
  final senha = body['senha'];

  // Valida se preencheu email e senha
  if (email == null || senha == null || email.toString().isEmpty || senha.toString().isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'sucesso': false, 'mensagem': 'E-mail e senha são obrigatórios para o login!'}
    );
  }

  // Procura na nossa lista temporária se existe um administrador com esse e-mail e senha
  final adminEncontrado = administradoresBD.firstWhere(
    (admin) => admin['email'] == email && admin['senha'] == senha,
    orElse: () => {}, // Retorna um mapa vazio caso não encontre
  );

  // Se estiver vazio, os dados estão incorretos
  if (adminEncontrado.isEmpty) {
    return Response.json(
      statusCode: 401, // 401 Unauthorized
      body: {'sucesso': false, 'mensagem': 'E-mail ou senha inválidos!'}
    );
  }

  // Se encontrou, login bem-sucedido
  return Response.json(
    statusCode: 200,
    body: {
      'sucesso': true,
      'mensagem': 'Login realizado com sucesso!',
      'usuario': {
        'nome': adminEncontrado['nome'],
        'email': adminEncontrado['email']
      }
    },
  );
}