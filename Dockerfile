# Estágio de Build
FROM dart:stable AS build

WORKDIR /app

# Ativa o CLI do Dart Frog e baixa as dependências
RUN dart pub global activate dart_frog_cli
COPY pubspec.* ./
RUN dart pub get

# Copia o restante do código fonte
COPY . .

# Gera o build de produção do Dart Frog (cria o diretório build/ com as rotas compiladas)
RUN dart pub global run dart_frog_cli:dart_frog build

# Estágio de Execução Final
FROM dart:stable-slim

WORKDIR /app

# Copia a pasta de build gerada pelo Dart Frog e o pubspec para garantir o contexto de execução
COPY --from=build /app/build /app/build
COPY --from=build /app/pubspec.yaml /app/pubspec.yaml

EXPOSE 8080

# Inicia o servidor apontando diretamente para o entrypoint compilado pelo Dart Frog
CMD ["dart", "build/bin/server.dart"]