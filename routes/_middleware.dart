import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart' as env;
import 'package:postgres/postgres.dart';

Connection? _connection;
final _dotenv = env.DotEnv(includePlatformEnvironment: true)..load();

Handler middleware(Handler handler) {
  return (context) async {
    try {
      if (_connection == null || !_connection!.isOpen) {
        final connectionString = _dotenv['SUPABASE_DB_URL'] ?? Platform.environment['SUPABASE_DB_URL'] ?? '';

        if (connectionString.isEmpty) {
          print('❌ ERRO: SUPABASE_DB_URL não encontrada no .env!');
        } else {
          print('🔌 A ligar ao Supabase através da Connection String...');

          final uri = Uri.parse(connectionString);
          
          // Tratamento seguro para extrair utilizador e senha caso contenham caracteres especiais
          final userInfo = uri.userInfo.split(':');
          final username = userInfo.isNotEmpty ? Uri.decodeComponent(userInfo[0]) : 'postgres';
          final password = userInfo.length > 1 ? Uri.decodeComponent(userInfo.sublist(1).join(':')) : '';

          _connection = await Connection.open(
            Endpoint(
              host: uri.host,
              port: uri.port == 0 ? 5432 : uri.port,
              database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'postgres',
              username: username,
              password: password,
            ),
            settings: const ConnectionSettings(
              sslMode: SslMode.require,
            ),
          );
          print('✅ Conectado com sucesso ao Supabase!');
        }
      }
    } catch (e) {
      print('❌ ERRO DE CONEXÃO: $e');
    }

    return handler.use(provider<Connection?>((_) => _connection))(context);
  };
}