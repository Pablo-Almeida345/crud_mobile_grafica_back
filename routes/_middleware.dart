
import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart' as env;
import 'package:postgres/postgres.dart';

// Instância global da conexão PostgreSQL
Connection? _connection;

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
        },
      );
    }
  };
}
