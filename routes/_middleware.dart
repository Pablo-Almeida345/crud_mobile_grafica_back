
import 'dart:async';
import 'dart:io';
<<<<<<< HEAD

import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

// Instância global única do Supabase para evitar recriar a conexão a cada request
SupabaseClient? _supabaseClient;
=======

import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart' as env;
import 'package:postgres/postgres.dart';

// Instância global da conexão PostgreSQL
Connection? _connection;
>>>>>>> f6a0d4e75e2f369ce3c630d8ba5fb13b41ce971f

// Controla tentativas simultâneas de conexão
Future<Connection?>? _conexaoPendente;

// Carrega as variáveis de ambiente
final _dotenv = env.DotEnv(
  includePlatformEnvironment: true,
  quiet: true,
)..load();

// Recupera a URL de conexão do Supabase
String _obterUrlBanco() {
  final url = Platform.environment['SUPABASE_DB_URL'] ??
      _dotenv['SUPABASE_DB_URL'] ??
      '';

  return url.trim();
}

// Abre a conexão com o PostgreSQL
Future<Connection?> _abrirConexao() async {
  try {
    // Recupera a URL configurada no .env
    final connectionString = _obterUrlBanco();

    // Verifica se a variável existe
    if (connectionString.isEmpty) {
      print(
        'ERRO: SUPABASE_DB_URL não encontrada '
        'nas variáveis de ambiente.',
      );

      return null;
    }

    // Valida o formato da URL
    final uri = Uri.tryParse(connectionString);

    if (uri == null ||
        !['postgres', 'postgresql'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      print(
        'ERRO: URL de conexão com o Supabase inválida.',
      );

      return null;
    }

    print('Conectando ao PostgreSQL do Supabase...');

    // Exige conexão criptografada com SSL
    final urlSegura = uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'sslmode': 'require',
        'connect_timeout': '15',
        'query_timeout': '30',
      },
    );

    // Abre a conexão usando a URL completa
    final novaConexao = await Connection.openFromUrl(
      urlSegura.toString(),
    );

    // Verifica se a conexão foi estabelecida
    if (!novaConexao.isOpen) {
      print(
        'ERRO: Não foi possível abrir a conexão '
        'com o banco de dados.',
      );

      return null;
    }

    // Armazena a conexão para reutilização
    _connection = novaConexao;

    print('Conectado com sucesso ao Supabase!');

    return novaConexao;
  } catch (e) {
    // Limpa a referência caso a conexão falhe
    _connection = null;

    print('ERRO DE CONEXÃO COM O SUPABASE: $e');

    return null;
  }
}

// Recupera uma conexão ativa
Future<Connection?> _obterConexao() async {
  // Reutiliza a conexão se ela estiver aberta
  if (_connection != null && _connection!.isOpen) {
    return _connection;
  }

  // Se já existe uma tentativa de conexão,
  // aguarda o resultado dessa tentativa
  if (_conexaoPendente != null) {
    return _conexaoPendente!;
  }

  // Inicia uma nova conexão
  final tentativa = _abrirConexao();

  _conexaoPendente = tentativa;

  try {
    return await tentativa;
  } finally {
    // Libera o controle para futuras reconexões
    _conexaoPendente = null;
  }
}

// Middleware global do Dart Frog
Handler middleware(Handler handler) {
<<<<<<< HEAD
  return _comCors((context) async {
    // Inicializa o cliente do Supabase apenas uma vez (Lazy Loading seguro)
    if (_supabaseClient == null) {
      final supabaseUrl = Platform.environment['SUPABASE_URL'] ??
          'https://fshgacospypbgxzzpnxt.supabase.co';

      final supabaseKey = Platform.environment['SUPABASE_ANON_KEY'] ??
          'sb_publishable_DkO4BfBFcSI3bBeUhojB1Q_pjFPdlMj';

      _supabaseClient = SupabaseClient(
        supabaseUrl,
        supabaseKey,
      );
    }

    final newContext = context.provide<SupabaseClient>(
      () => _supabaseClient!,
    );

    return await handler(newContext);
  });
}

Handler _comCors(Handler handler) {
  return (context) async {
    final metodo = context.request.method;

    // Se não for um método mapeado, passa adiante
    if (metodo != HttpMethod.get &&
        metodo != HttpMethod.post &&
        metodo != HttpMethod.put &&
        metodo != HttpMethod.delete &&
        metodo != HttpMethod.options) {
      return await handler(context);
    }

    final origem = context.request.headers['origin'];

    // CORREÇÃO: Se a origem vier nula (ex: aplicativos nativos Android/iOS), 
    // liberamos explicitamente com '*' ou com a própria origem informada.
    final corsOrigin = (origem != null && origem.isNotEmpty) ? origem : '*';

    final cors = <String, String>{
      'Access-Control-Allow-Origin': corsOrigin,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Accept, Content-Type, Authorization, apikey',
      'Vary': 'Origin',
    };

    // Responde imediatamente às requisições de teste pré-flight do navegador (OPTIONS)
    if (metodo == HttpMethod.options) {
      return Response(
        statusCode: HttpStatus.noContent,
        headers: cors,
      );
    }

    try {
      final resposta = await handler(context);

      final varyAnterior =
          resposta.headers['vary'] ?? resposta.headers['Vary'] ?? '';

      final vary = varyAnterior
          .split(',')
          .map((valor) => valor.trim())
          .where((valor) => valor.isNotEmpty)
          .toList();

      if (!vary.any(
        (valor) => valor == '*' || valor.toLowerCase() == 'origin',
      )) {
        vary.add('Origin');
      }

      final headers = <String, String>{
        ...resposta.headers,
        ...cors,
      };

      headers.removeWhere(
        (nome, _) => nome.toLowerCase() == 'vary',
      );

      headers['Vary'] = vary.contains('') ? '' : vary.join(', ');

      return resposta.copyWith(headers: headers);
    } catch (_, stackTrace) {
      stderr.writeln('Erro interno ao processar a requisição.');
      stderr.writeln(stackTrace);

      return Response.json(
        statusCode: HttpStatus.internalServerError,
        headers: cors,
        body: {
          'error': 'Erro interno no servidor.',
=======
  return (context) async {
    try {
      // Recupera ou estabelece a conexão
      final connection = await _obterConexao();

      // Registra a conexão no RequestContext
      // Mantém compatibilidade com:
      // context.read<Connection?>()
      final handlerComConexao = handler.use(
        provider<Connection?>(
          (_) => connection,
        ),
      );

      // Continua a requisição normalmente
      return await handlerComConexao(context);
    } catch (e) {
      print('ERRO NO MIDDLEWARE: $e');

      return Response.json(
        statusCode: 500,
        body: {
          'sucesso': false,
          'mensagem': 'Erro interno no servidor.',
>>>>>>> f6a0d4e75e2f369ce3c630d8ba5fb13b41ce971f
        },
      );
    }
  };
}
