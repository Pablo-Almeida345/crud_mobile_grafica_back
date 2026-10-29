
import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:bcrypt/bcrypt.dart';

const uuid = Uuid();

// Função para retornar mensagens de erro
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
  if (context.request.method != HttpMethod.post) {
    return respostaErro(
      405,
      'Método não permitido.',
    );
  }

  // Recebe os dados enviados pelo frontend
  dynamic dados;

  try {
    dados = await context.request.json();
  } on FormatException {
    return respostaErro(
      400,
      'JSON inválido.',
    );
  } catch (e) {
    return respostaErro(
      400,
      'Não foi possível ler os dados enviados.',
    );
  }

  // Verifica se os dados estão no formato correto
  if (dados is! Map<String, dynamic>) {
    return respostaErro(
      400,
      'Formato de dados inválido.',
    );
  }

  // Recupera os campos do formulário
  final nome =
      dados['nome']?.toString().trim() ?? '';

  final email =
      dados['email']?.toString().trim().toLowerCase() ?? '';

  final cpf =
      dados['cpf']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';

  final senha =
      dados['senha']?.toString() ?? '';

  final confirmarSenha =
      dados['confirmarSenha']?.toString() ?? '';

  // Verifica se todos os campos foram preenchidos
  if (nome.isEmpty ||
      email.isEmpty ||
      cpf.isEmpty ||
      senha.isEmpty ||
      confirmarSenha.isEmpty) {

    return respostaErro(
      400,
      'Todos os campos são obrigatórios!',
    );
  }

  // Validação do nome
  if (nome.length < 3) {
    return respostaErro(
      400,
      'O nome deve conter pelo menos 3 caracteres.',
    );
  }

  // Validação do e-mail
  final regexEmail = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  if (!regexEmail.hasMatch(email)) {
    return respostaErro(
      400,
      'E-mail inválido!',
    );
  }

  // Validação do CPF
  if (!validarCpf(cpf)) {
    return respostaErro(
      400,
      'CPF inválido!',
    );
  }

  // Validação do tamanho da senha
  if (senha.length < 8) {
    return respostaErro(
      400,
      'A senha deve conter pelo menos 8 caracteres.',
    );
  }

  // BCrypt suporta no máximo 72 bytes
  if (utf8.encode(senha).length > 72) {
    return respostaErro(
      400,
      'A senha excede o limite de 72 bytes.',
    );
  }

  // Confirma se as senhas coincidem
  if (senha != confirmarSenha) {
    return respostaErro(
      400,
      'As senhas não coincidem!',
    );
  }

  try {
    // Recupera a conexão fornecida pelo middleware
    final connection = context.read<Connection?>();

    // Verifica se a conexão está disponível
    if (connection == null) {
      return respostaErro(
        500,
        'Conexão com o banco de dados indisponível.',
      );
    }

    // Verifica se o e-mail já está cadastrado
    final resultadoEmail = await connection.execute(
      Sql.named('''
        SELECT id
        FROM administradores
        WHERE email = @email
        LIMIT 1
      '''),
      parameters: {
        'email': email,
      },
    );

    if (resultadoEmail.isNotEmpty) {
      return respostaErro(
        409,
        'Este e-mail já está cadastrado!',
      );
    }

    // Verifica se o CPF já está cadastrado
    final resultadoCpf = await connection.execute(
      Sql.named('''
        SELECT id
        FROM administradores
        WHERE cpf = @cpf
        LIMIT 1
      '''),
      parameters: {
        'cpf': cpf,
      },
    );

    if (resultadoCpf.isNotEmpty) {
      return respostaErro(
        409,
        'Este CPF já está cadastrado!',
      );
    }

    // Gera um identificador único para o administrador
    final novoId = uuid.v4();

    // Criptografa a senha antes de salvar
    final senhaCriptografada = BCrypt.hashpw(
      senha,
      BCrypt.gensalt(),
    );

    // Insere o administrador no PostgreSQL
    final resultadoCadastro = await connection.execute(
      Sql.named('''
        INSERT INTO administradores (
          id,
          nome,
          email,
          cpf,
          senha
        )
        VALUES (
          @id,
          @nome,
          @email,
          @cpf,
          @senha
        )
        ON CONFLICT DO NOTHING
        RETURNING id
      '''),
      parameters: {
        'id': TypedValue(Type.uuid, novoId),
        'nome': nome,
        'email': email,
        'cpf': cpf,
        'senha': senhaCriptografada,
      },
    );

    // Impede cadastro duplicado em requisições simultâneas
    if (resultadoCadastro.isEmpty) {
      return respostaErro(
        409,
        'E-mail ou CPF já cadastrado!',
      );
    }

    // Retorna sucesso ao cadastrar o administrador
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
    // Registra o erro no terminal do backend
    print('Erro no cadastro de administrador: $e');

    // Retorna mensagem genérica para o frontend
    return respostaErro(
      500,
      'Erro interno ao cadastrar administrador.',
    );
  }
}
