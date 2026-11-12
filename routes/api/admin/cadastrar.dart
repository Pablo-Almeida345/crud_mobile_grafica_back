import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase/supabase.dart';

const uuid = Uuid();

Future<Response> onRequest(RequestContext context) async {
  // Valida se o método HTTP é POST
  if (context.request.method != 'POST') {
    return Response.json(
      statusCode: 405, 
      body: {'sucesso': false, 'mensagem': 'Método não permitido'},
    );
  }

  // Pega o cliente do Supabase injetado pelo middleware
  final supabase = context.read<SupabaseClient?>();
  if (supabase == null) {
    return Response.json(
      statusCode: 500,
      body: {'sucesso': false, 'mensagem': 'Cliente do Supabase indisponível.'},
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    
    final nome = body['nome']?.toString().trim();
    // Normaliza o e-mail: remove espaços e converte para minúsculas para evitar falhas de comparação
    final email = body['email']?.toString().trim().toLowerCase();
    final cpf = body['cpf']?.toString().trim();
    final senha = body['senha']?.toString();
    final confirmarSenha = body['confirmarSenha']?.toString();

    // Validação de campos vazios ou nulos
    if (nome == null || email == null || cpf == null || senha == null || confirmarSenha == null ||
        nome.isEmpty || email.isEmpty || cpf.isEmpty || senha.isEmpty || confirmarSenha.isEmpty) {
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

    // Verifica se o e-mail já existe de forma segura
    final List<dynamic> resultadoEmail = await supabase
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
      'senha': senha, // Dica: No futuro, lembre-se de usar hash na senha (ex: bcrypt)
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
    // Trata especificamente erros do PostgreSQL (como violação de chave única)
    final errorString = e.toString();
    if (errorString.contains('duplicate key') || errorString.contains('unique constraint')) {
      return Response.json(
        statusCode: 400,
        body: {'sucesso': false, 'mensagem': 'Este e-mail ou CPF já está cadastrado no sistema.'},
      );
    }

    return Response.json(
      statusCode: 500,
      body: {'sucesso': false, 'mensagem': 'Erro interno no servidor: $e'},
    );
  }
}