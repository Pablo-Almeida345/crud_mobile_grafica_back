import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase/supabase.dart';

const uuid = Uuid();

Future<Response> onRequest(RequestContext context) async {
  // Correção Linha 9: context.request.method é uma String ('POST')
  if (context.request.method != 'POST') {
    return Response.json(statusCode: 405, body: {'erro': 'Método não permitido'});
  }

  // Pega o cliente do Supabase injetado pelo _middleware.dart global
  final supabase = context.read<SupabaseClient?>();
  if (supabase == null) {
    return Response.json(
      statusCode: 500,
      body: {'sucesso': false, 'mensagem': 'Cliente do Supabase indisponível.'},
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    
    final nome = body['nome'];
    final email = body['email'];
    final cpf = body['cpf'];
    final senha = body['senha'];
    final confirmarSenha = body['confirmarSenha'];

    if (nome == null || email == null || cpf == null || senha == null || confirmarSenha == null ||
        nome.toString().isEmpty || email.toString().isEmpty || cpf.toString().isEmpty || senha.toString().isEmpty || confirmarSenha.toString().isEmpty) {
      return Response.json(
        statusCode: 400, 
        body: {'sucesso': false, 'mensagem': 'Todos os campos são obrigatórios!'}
      );
    }

    if (senha != confirmarSenha) {
      return Response.json(
        statusCode: 400, 
        body: {'sucesso': false, 'mensagem': 'A senha e a confirmação de senha não coincidem!'}
      );
    }

    // Correção Linha 51: usar 'var' ou 'final' para deixar o Dart inferir o tipo correto do Supabase
    final resultadoEmail = await supabase
        .from('administradores')
        .select('id')
        .eq('email', email);

    if (resultadoEmail.isNotEmpty) {
      return Response.json(
        statusCode: 400, 
        body: {'sucesso': false, 'mensagem': 'Este e-mail já está cadastrado!'}
      );
    }

    final novoId = uuid.v4();

    // Insere o novo administrador no Supabase
    await supabase.from('administradores').insert({
      'id': novoId,
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'senha': senha,
    });

    return Response.json(
      statusCode: 201,
      body: {
        'sucesso': true, 
        'mensagem': 'Cadastro realizado com sucesso!', 
        'admin': {
          'id': novoId,
          'nome': nome,
          'email': email,
          'cpf': cpf,
        }
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'sucesso': false, 'mensagem': 'Erro interno no servidor: $e'},
    );
  }
}