import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.name.toUpperCase() != 'POST') {
    return Response.json(statusCode: 405, body: {'erro': 'Método não permitido'});
  }

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

    // Abordagem blindada: Executa a query e converte explicitamente para evitar qualquer erro de tipagem na linha 47/48
    final response = await supabase
        .from('administradores')
        .select()
        .eq('email', email);

    // Converte o resultado de forma segura para uma lista de mapas
    final List<dynamic> lista = response as List<dynamic>;

    if (lista.isNotEmpty) {
      return Response.json(
        statusCode: 400, 
        body: {'sucesso': false, 'mensagem': 'Este e-mail já está cadastrado!'}
      );
    }

    // Insere o novo administrador alinhado com as colunas da tabela do Supabase
    await supabase.from('administradores').insert({
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