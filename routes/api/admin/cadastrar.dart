import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

// Função para retornar mensagens de erro padronizadas
Response respostaErro(int statusCode, String mensagem) {
  return Response.json(
    statusCode: statusCode,
    body: {
      'sucesso': false,
      'mensagem': mensagem,
    },
  );
}

// Função para validar CPF
bool validarCpf(String cpf) {
  if (!RegExp(r'^\d{11}$').hasMatch(cpf)) {
    return false;
  }

  // Impede CPF com todos os números iguais
  if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
    return false;
  }

  // Validação dos dígitos verificadores
  for (int tamanho = 9; tamanho <= 10; tamanho++) {
    int soma = 0;

    for (int i = 0; i < tamanho; i++) {
      soma += int.parse(cpf[i]) * (tamanho + 1 - i);
    }

    int digito = (soma * 10) % 11;

    if (digito == 10) {
      digito = 0;
    }

    if (digito != int.parse(cpf[tamanho])) {
      return false;
    }
  }

  return true;
}

// Rota de cadastro de administrador
Future<Response> onRequest(RequestContext context) async {
  // Aceita somente requisições POST
  if (context.request.method.name.toUpperCase() != 'POST') {
    return respostaErro(405, 'Método não permitido.');
  }

  // Recupera o cliente do Supabase injetado pelo middleware
  final supabase = context.read<SupabaseClient?>();
  if (supabase == null) {
    return respostaErro(500, 'Cliente do Supabase indisponível.');
  }

  // Recebe os dados enviados pelo frontend
  dynamic dados;

  try {
    dados = await context.request.json();
  } on FormatException {
    return respostaErro(400, 'JSON inválido.');
  } catch (e) {
    return respostaErro(400, 'Não foi possível ler os dados enviados.');
  }

  // Verifica se os dados estão no formato correto
  if (dados is! Map<String, dynamic>) {
    return respostaErro(400, 'Formato de dados inválido.');
  }

  // Recupera e limpa os campos do formulário
  final nome = dados['nome']?.toString().trim() ?? '';
  final email = dados['email']?.toString().trim().toLowerCase() ?? '';
  final cpf = dados['cpf']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
  final senha = dados['senha']?.toString() ?? '';
  final confirmarSenha = dados['confirmarSenha']?.toString() ?? '';

  // Validações básicas de preenchimento
  if (nome.isEmpty ||
      email.isEmpty ||
      cpf.isEmpty ||
      senha.isEmpty ||
      confirmarSenha.isEmpty) {
    return respostaErro(400, 'Todos os campos são obrigatórios!');
  }

  // Validação do nome
  if (nome.length < 3) {
    return respostaErro(400, 'O nome deve conter pelo menos 3 caracteres.');
  }

  // Validação do e-mail
  final regexEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (!regexEmail.hasMatch(email)) {
    return respostaErro(400, 'E-mail inválido!');
  }

  // Validação do CPF
  if (!validarCpf(cpf)) {
    return respostaErro(400, 'CPF inválido!');
  }

  // Validação do tamanho da senha
  if (senha.length < 8) {
    return respostaErro(400, 'A senha deve conter pelo menos 8 caracteres.');
  }

  // Restrição do BCrypt (máximo de 72 bytes)
  if (utf8.encode(senha).length > 72) {
    return respostaErro(400, 'A senha excede o limite de 72 bytes.');
  }

  // Confirma se as senhas coincidem
  if (senha != confirmarSenha) {
    return respostaErro(400, 'As senhas não coincidem!');
  }

  try {
    // 1. Verifica se o e-mail já está cadastrado
    final resultadoEmail = await supabase
        .from('administradores')
        .select('id')
        .eq('email', email)
        .maybeSingle();

    if (resultadoEmail != null) {
      return respostaErro(409, 'Este e-mail já está cadastrado!');
    }

    // 2. Verifica se o CPF já está cadastrado
    final resultadoCpf = await supabase
        .from('administradores')
        .select('id')
        .eq('cpf', cpf)
        .maybeSingle();

    if (resultadoCpf != null) {
      return respostaErro(409, 'Este CPF já está cadastrado!');
    }

    // Gera um ID único e criptografa a senha com BCrypt
    final novoId = uuid.v4();
    final senhaCriptografada = BCrypt.hashpw(senha, BCrypt.gensalt());

    // 3. Insere o novo administrador no Supabase
    await supabase.from('administradores').insert({
      'id': novoId,
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'senha': senhaCriptografada,
    });

    // Retorna sucesso ao cadastrar
    return Response.json(
      statusCode: 201,
      body: {
        'sucesso': true,
        'mensagem': 'Administrador cadastrado com sucesso!',
        'admin': {
          'id': novoId,
          'nome': nome,
          'email': email,
          'cpf': cpf,
        },
      },
    );
  } catch (e) {
    print('Erro no cadastro de administrador: $e');

    // Tratamento de segurança caso ocorra erro de duplicidade no banco
    final errorString = e.toString().toLowerCase();
    if (errorString.contains('duplicate key') || errorString.contains('unique constraint')) {
      return respostaErro(409, 'Este e-mail ou CPF já está cadastrado no sistema.');
    }

    return respostaErro(500, 'Erro interno ao cadastrar administrador.');
  }
}