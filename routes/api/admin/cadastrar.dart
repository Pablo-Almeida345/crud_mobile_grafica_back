import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart'; // Importa o gerador de UUID

const uuid = Uuid(); // Instância do gerador de UUID

// Banco temporário iniciado com UUID no administrador padrão
List<Map<String, dynamic>> administradoresBD = [
  {
    'id': uuid.v4(), // Gera um UUID único universal padrão
    'nome': 'Administrador Padrão',
    'email': 'admin@grafica.com',
    'cpf': '000.000.000-00',
    'senha': '123'
  }
];

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'erro': 'Método não permitido'});
  }

  final body = await context.request.json() as Map<String, dynamic>;
  
  final nome = body['nome'];
  final email = body['email'];
  final cpf = body['cpf'];
  final senha = body['senha'];
  final confirmarSenha = body['confirmarSenha'];

  // Validação de campos obrigatórios
  if (nome == null || email == null || cpf == null || senha == null || confirmarSenha == null ||
      nome.toString().isEmpty || email.toString().isEmpty || cpf.toString().isEmpty || senha.toString().isEmpty || confirmarSenha.toString().isEmpty) {
    return Response.json(
      statusCode: 400, 
      body: {'sucesso': false, 'mensagem': 'Todos os campos são obrigatórios!'}
    );
  }

  // Validação de confirmação de senha
  if (senha != confirmarSenha) {
    return Response.json(
      statusCode: 400, 
      body: {'sucesso': false, 'mensagem': 'A senha e a confirmação de senha não coincidem!'}
    );
  }

  // Verifica se o e-mail já existe
  final emailExistente = administradoresBD.any((admin) => admin['email'] == email);
  if (emailExistente) {
    return Response.json(
      statusCode: 400, 
      body: {'sucesso': false, 'mensagem': 'Este e-mail já está cadastrado!'}
    );
  }

  // Cria o novo administrador gerando um ID único universal (UUID)
  final novoAdmin = {
    'id': uuid.v4(), 
    'nome': nome,
    'email': email,
    'cpf': cpf,
    'senha': senha,
  };

  administradoresBD.add(novoAdmin);

  return Response.json(
    statusCode: 201,
    body: {
      'sucesso': true, 
      'mensagem': 'Cadastro realizado com sucesso!', 
      'admin': {
        'id': novoAdmin['id'],
        'nome': novoAdmin['nome'],
        'email': novoAdmin['email'],
        'cpf': novoAdmin['cpf']
      }
    },
  );
}