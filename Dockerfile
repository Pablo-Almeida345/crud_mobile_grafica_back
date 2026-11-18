# Estágio de Build
FROM dart:stable AS build

WORKDIR /app

# Ativa o CLI do Dart Frog e baixa as dependências
RUN dart pub global activate dart_frog_cli
COPY pubspec.* ./
RUN dart pub get

# Copia o restante do código
COPY . .

# Gera o build de produção do Dart Frog (cria a pasta build/ com as rotas)
RUN dart pub global run dart_frog_cli:dart_frog build

# Compila o servidor
RUN dart compile exe build/bin/server.dart -o bin/server

# Estágio de Execução (Usando imagem com Debian/Ubuntu leve em vez de scratch para garantir suporte a caminhos e ambiente)
FROM debian:bookworm-slim

WORKDIR /app

# Copia o binário compilado
COPY --from=build /app/bin/server /app/bin/server

# Copia também a pasta public ou assets se houver, ou mantém o workspace limpo
EXPOSE 8080

# Executa o servidor
CMD ["./bin/server"]