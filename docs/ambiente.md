# Ambiente local e API

O MySQL é a fonte oficial dos dados. Cadastro, login, sessão e recuperação de senha passam pela API PHP (`api/`). O app guarda no SQLite do aparelho uma cópia do usuário logado (perfil, endereços e sessão) para abrir offline. O backend roda em Docker:

| Serviço | Endereço no computador | Função |
| --- | --- | --- |
| `api` | http://127.0.0.1:8080 | API PHP 8.3 (Apache) usada pelo app |
| `mysql` | 127.0.0.1:3307 | MySQL 8.0 com o esquema de `database/init/` |
| `phpmyadmin` | http://127.0.0.1:8081 | Administração do banco |
| `mailpit` | http://127.0.0.1:8025 | SMTP local: recebe e mostra os emails enviados pela API |

As portas ficam presas a `127.0.0.1` e podem ser alteradas no `.env`.

## Requisitos

- Docker com o plugin Compose (`docker compose version`). No Windows/macOS, Docker Desktop.
- Flutter (SDK do `pubspec.yaml`) para rodar o app.

## Primeira configuração

```sh
cp .env.example .env
```

Edite o `.env`:

1. Troque `DB_PASSWORD` e `MYSQL_ROOT_PASSWORD`.
2. Preencha `APP_SECRET` com 32 bytes aleatórios:
   - Linux/macOS/Git Bash: `openssl rand -hex 32`
   - PowerShell 7: `[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))`

   Mantenha o mesmo valor entre reinícios: trocar o segredo invalida códigos de recuperação e limites em andamento. Ele não é uma senha de banco nem de SMTP.
3. Não altere `DB_NAME`: o nome `FluuterLaborHub` vem do dump `database/init/01-laborhub.sql`.

O `.env` está no `.gitignore`. Nunca coloque senhas no Flutter, no Git ou em `--dart-define`.

## Comandos do dia a dia

```sh
docker compose up -d --build     # cria/atualiza e inicia tudo
docker compose ps                # estado dos serviços (mysql deve ficar "healthy")
docker compose logs -f api       # logs da API (erros PHP e falhas de SMTP)
docker compose stop              # para sem apagar nada
docker compose down              # remove os containers; os dados do MySQL ficam no volume
```

O código de `api/src` e `api/public` é montado no container: alterações em PHP valem na próxima requisição. Rode `docker compose up -d --build api` somente se mudar o `api/Dockerfile`.

### Teste rápido da API

```sh
curl -i -X POST http://127.0.0.1:8080/auth/password/request \
  -H 'Content-Type: application/json' -d '{"email":"teste@example.com"}'
```

Resposta esperada: `202`. Para emails cadastrados, o código aparece no Mailpit (http://127.0.0.1:8025).

## Banco de dados

Na primeira inicialização (volume vazio), o MySQL executa em ordem:

- `database/init/01-laborhub.sql`: esquema do projeto (dump original, sem alterações).
- `database/init/02-api.sql`: tabela auxiliar `limites`, usada pela API para limitar tentativas.
- `database/init/03-sessoes.sql`: tabela `sessoes` (login).

Banco já criado antes da sessão existir? Aplique o arquivo uma vez:

```sh
docker compose exec -T mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < database/init/03-sessoes.sql
```

phpMyAdmin: http://127.0.0.1:8081, usuário `DB_USER`/`DB_PASSWORD` (ou `root`/`MYSQL_ROOT_PASSWORD`).

```sh
# Backup
docker compose exec mysql sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --databases FluuterLaborHub' > backup.sql

# Restaurar
docker compose exec -T mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < backup.sql

# Recriar do zero (APAGA todos os dados e executa database/init de novo)
docker compose down -v && docker compose up -d
```

Os scripts de `database/init` só rodam com o volume vazio. Para mudar o esquema, crie um novo arquivo numerado (`03-....sql`) para ambientes novos e aplique o mesmo SQL nos bancos existentes pelo phpMyAdmin ou com `docker compose exec -T mysql ... < 03-....sql`.

## Email (SMTP)

Por padrão a API envia para o Mailpit (`SMTP_HOST=mailpit`, porta `1025`, `SMTP_SECURITY=none`). Nenhum email sai para a internet; todos aparecem em http://127.0.0.1:8025.

Para enviar de verdade, aponte o `.env` para o servidor SMTP da sua organização ou do seu domínio e rode `docker compose up -d api`:

```ini
SMTP_HOST=smtp.seudominio.com
SMTP_PORT=587
SMTP_SECURITY=starttls   # 587 = starttls, 465 = ssl
SMTP_USER=usuario
SMTP_PASSWORD=senha-de-aplicativo
SMTP_FROM=no-reply@seudominio.com
```

- O cliente SMTP (`api/src/Smtp.php`) não tem dependências, valida o certificado do servidor e recusa autenticação sem TLS (`SMTP_SECURITY=none` só serve para o Mailpit).
- Configure SPF/DKIM do domínio de `SMTP_FROM`, ou os emails tendem a cair no spam.
- Falhas de entrega aparecem em `docker compose logs api` como `Falha na entrega de email de recuperação`, sem email, código ou senha, e invalidam o código enviado.

## Rodar o app Flutter

```sh
flutter pub get
```

| Onde o app roda | Comando |
| --- | --- |
| Emulador Android | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=ALLOW_LOCAL_HTTP=true` |
| Simulador iOS, Linux, Windows, macOS | `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080 --dart-define=ALLOW_LOCAL_HTTP=true` |
| Celular físico na mesma rede | No `.env`, `API_BIND=0.0.0.0`; `docker compose up -d`; use `http://IP-DO-COMPUTADOR:8080` e libere a porta no firewall |

`ALLOW_LOCAL_HTTP` e o HTTP no manifesto de debug do Android existem só para desenvolvimento. Em release, use `API_BASE_URL=https://...`.

Flutter Web: a API não habilita CORS. Sirva o app e `/auth/` na mesma origem por um proxy, ou adicione uma lista explícita de origens.

## Contrato da API

Todas as rotas usam `POST`, recebem JSON (máximo 16 KiB; corpo vazio ou `{}` nas rotas de sessão) e retornam JSON com `Cache-Control: no-store`. Erros retornam `{"message": "..."}`.

| Rota | Campos | Resultado |
| --- | --- | --- |
| `/auth/register` | `email`, `password`, `usuario`, `endereco` e `pessoaFisica` **ou** `pessoaJuridica` | 201 `{usuarios_id}`; 200 se repetido com a mesma senha; 409 se email/CPF/CNPJ já existe |
| `/auth/login` | `email`, `password` | 200 com usuário, `tipo`, `pessoaFisica`, `pessoaJuridica`, `enderecos`, `token` e `sessao_expira_em`; 401 |
| `/auth/session` | cabeçalho `Authorization: Bearer <token>` | 200 com os mesmos dados (sem novo token) e validade renovada; 401 se inválida |
| `/auth/logout` | cabeçalho `Authorization: Bearer <token>` | 200; o token deixa de valer |
| `/auth/password/request` | `email` | 202 genérico (mesma resposta para emails existentes ou não); 429 |
| `/auth/password/verify` | `email`, `code` | 200 `{resetToken}`; 400 se inválido/expirado |
| `/auth/password/reset` | `email`, `resetToken`, `password`, `confirmation` | 200 |
| `/auth/profile` | cabeçalho `Authorization: Bearer <token>`; `usuario` (`usuarios_imagem`, `usuarios_telefone`), `endereco` (com `endereco_id`) e `pessoaFisica` **ou** `pessoaJuridica` | 200 com os mesmos dados de `/auth/session`; 400; 401 |
| `/profissionais` | cabeçalho `Authorization: Bearer <token>` | 200 `{profissionais: [...]}` (um item por serviço, campos de `Profissional.fromMap`); 401 |
| `/solicitacoes` | cabeçalho `Authorization: Bearer <token>` | 200 `{solicitacoes: [...]}` do cliente logado (Finalizado, Pendente, Recusado; campos de `Solicitacao.fromMap`); 401 |
| `/solicitacoes/cancelar` | cabeçalho `Authorization: Bearer <token>`; `solicitacao_id` | 200; 409 se não for do usuário ou não estiver pendente; 401 |

Os objetos `usuario`, `endereco`, `pessoaFisica` e `pessoaJuridica` usam os nomes de coluna do banco (os mesmos de `toMap()` nos models). O servidor ignora ids, chaves estrangeiras e `usuarios_senha_hash` enviados pelo app, grava tudo em uma transação e cria o hash da senha.

## Sessão e uso offline

- O login cria uma sessão de 30 dias. A validade é renovada sempre que o app confere a sessão (`/auth/session`).
- O MySQL guarda apenas o HMAC do token (`sessoes.sessoes_token_hash`); o token fica no SQLite do aparelho (tabela `sessao`), na área privada do app.
- Ao abrir, a tela de login lê a sessão do SQLite e entra direto, sem rede. A home então consulta a API:
  - sessão válida: atualiza a cópia local do perfil;
  - 401 (expirada, encerrada em "Sair" ou senha redefinida): apaga os dados locais e volta ao login;
  - sem conexão: continua com os dados locais até a data de expiração.
- "Sair" (ícone na home) encerra a sessão na API e apaga os dados do aparelho; offline, apaga os dados locais e o token expira sozinho no servidor.
- Redefinir a senha encerra todas as sessões do usuário em todos os aparelhos.
- Cadastro e login exigem conexão: as contas só existem no MySQL.
- Rotas futuras que exigirem login usam `$auth->usuarioDaSessao(lerToken())` na API e `token: sessao.token` no `AuthApi.post` do app.

### Segurança

- Senhas com `password_hash` (bcrypt). Código de 6 dígitos com `random_int`, válido por 10 minutos e 5 tentativas; depois de validado vira uma autorização de 256 bits, válida por 5 minutos e de uso único.
- Código e autorização são guardados como HMAC-SHA256 (`APP_SECRET`) em `usuarios_reset_hash`, com validade em `usuarios_expira_em`.
- Limites persistentes (tabela `limites`): 60 requisições/15 min por IP; cadastro 10/h por IP; login 10/15 min por email; envio de código 1/min e 5/h por email e 10/h por IP.
- Consultas parametrizadas (PDO); erros não expõem SQL, credenciais, códigos ou a existência da conta.
- O limite por IP usa o endereço da conexão, nunca `X-Forwarded-For`. Atrás de um proxy (ou com o Docker Desktop), todos os clientes podem aparecer com o mesmo IP; em produção, aplique o limite por IP no proxy.

## Produção (resumo)

- Publique a API somente por HTTPS (proxy reverso na frente da porta da API).
- Não exponha phpMyAdmin, Mailpit nem a porta do MySQL; remova esses `ports` ou os serviços.
- Use senhas fortes e um `APP_SECRET` próprio, e configure um SMTP real.

## Verificação

```sh
flutter test
for f in api/src/*.php api/public/*.php; do php -l "$f"; done   # ou: docker compose exec api php -l src/Auth.php
docker compose config -q
```

## Problemas comuns

| Sintoma | Causa provável |
| --- | --- |
| `required variable APP_SECRET is missing` | `.env` ausente ou `APP_SECRET` vazio |
| `api` não inicia | A API espera o MySQL ficar `healthy`; veja `docker compose logs mysql` |
| Tabelas não aparecem | O volume já existia antes do dump; use `docker compose down -v` (apaga os dados) |
| Porta em uso | Altere `API_PORT`, `MYSQL_PORT`, `PHPMYADMIN_PORT` ou `MAILPIT_PORT` no `.env` |
| App: "Configure o endereço seguro da API" | Faltou `--dart-define=API_BASE_URL=...` (e `ALLOW_LOCAL_HTTP=true` para `http`) |
| Email não chega | Veja `docker compose logs api` e o Mailpit; no SMTP real, confira porta, `SMTP_SECURITY` e credenciais |
