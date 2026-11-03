# Recuperação de senha

O aplicativo continua em Flutter, com repositórios e perfis no SQLite local. Como a versão anterior não tinha servidor e comparava senhas em texto no aparelho, `server/` introduz uma API Dart que passa a ser a autoridade de cadastro, login e recuperação. O código de email **não é validado pelo aparelho**. Alterar o SQLite local não altera a senha na API.

## Configurar a API e o email

1. Instale Dart 3.13 ou superior e execute `dart pub get` dentro de `server/`.
2. Defina as variáveis de `server/.env.example` no ambiente do processo. O arquivo `.env` não é carregado automaticamente. Nunca inclua credenciais SMTP no Flutter, no Git ou em `--dart-define`.
3. `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`: dados do provedor SMTP e remetente autorizado. Use uma senha de aplicativo quando exigida pelo provedor. Configure/verifique o domínio e SPF/DKIM conforme o provedor.
4. Porta 587 usa STARTTLS (`SMTP_SSL=false`); porta 465 usa TLS desde a conexão (`SMTP_SSL=true`). O cliente não permite transporte SMTP sem criptografia nem certificados inválidos.
5. Gere `RESET_SECRET` com pelo menos 32 bytes aleatórios (por exemplo, `openssl rand -hex 32`). Mantenha o mesmo segredo entre reinícios. Rotacioná-lo invalida códigos, autorizações e limites existentes. Ele não é a senha SMTP.
6. `DATABASE_PATH` deve apontar para um arquivo em volume persistente, gravável apenas pelo serviço. O esquema é criado automaticamente. Preserve também os arquivos WAL durante backups ativos ou use um backup consistente do SQLite.
7. Inicie com `dart run bin/server.dart`. A API escuta em `127.0.0.1:8080` por padrão. Exponha-a por HTTPS com um proxy reverso; use firewall para impedir acesso direto à porta interna. Configure limites de conexão, corpo e timeout também no proxy.

Exemplo PowerShell (valores fictícios, execute em `server/`):

```powershell
$env:RESET_SECRET = '<segredo-aleatorio>'
$env:SMTP_HOST = 'smtp.seudominio.com'
$env:SMTP_PORT = '587'
$env:SMTP_USER = 'usuario-do-provedor'
$env:SMTP_PASSWORD = '<senha-de-aplicativo>'
$env:SMTP_FROM = 'no-reply@seudominio.com'
dart run bin/server.dart
```

O envio real depende de configurar essas credenciais e validar a entrega no provedor. Os testes usam um remetente substituto; não enviam mensagens reais. Falhas de entrega geram um aviso sem dados pessoais/segredos e invalidam o código correspondente. A resposta HTTP é a mesma para emails conhecidos e desconhecidos. O envio é assíncrono em memória: se o processo parar antes da entrega, será necessário reenviar após o intervalo; não há fila durável nesta versão.

Os limites de IP usam o endereço da conexão, nunca um `X-Forwarded-For` fornecido pelo cliente. Atrás de um proxy, esse limite será compartilhado por todos os clientes do proxy; configure a limitação por IP real no próprio proxy. O limite por email permanece individual e persistente. Execute uma instância Dart por arquivo SQLite; para escalar horizontalmente, adapte o armazenamento/limites para um banco central.

## Configurar o Flutter

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=https://api.seudominio.com
```

Sem `API_BASE_URL`, o app mostra uma mensagem de configuração ao tentar autenticar/recuperar. HTTP é recusado, salvo em desenvolvimento com `--dart-define=ALLOW_LOCAL_HTTP=true`. Em Android Emulator, o host costuma ser `http://10.0.2.2:8080`; o sistema também precisa permitir HTTP no manifesto de **debug**. Não habilite HTTP em release. Android já recebeu a permissão INTERNET e macOS, a permissão de cliente de rede.

O alvo principal é mobile. A API não habilita CORS; para Flutter Web, sirva o app e `/auth/` na mesma origem pelo proxy, ou implemente uma lista explícita de origens permitidas. O cadastro/perfil local original usa sqflite e não foi portado para Web. O login mantém a resposta de usuário esperada pelo app; não introduz sessões ou endpoints de negócio autenticados, que ainda não existem no projeto.

## Contas existentes: migrar ANTES de atualizar o aplicativo

As contas antigas existem somente em cada aparelho, sem uma base central. A API não consegue encontrá-las automaticamente e não aceita upload público de bases locais como prova de identidade.

1. Faça backups confiáveis dos arquivos `laborHUb.db` antigos **antes** da atualização. O banco local versão 2 remove as senhas em texto, os resets e suas datas, mantendo perfis e endereços.
2. Em ambiente administrativo confiável, configure `RESET_SECRET` e execute em `server/`:

   ```sh
   dart run bin/import_legacy.dart /caminho/backup-legado.db /caminho/laborhub.sqlite
   ```

3. O importador mantém status ativo e data de criação, normaliza email e transforma a senha antiga em PBKDF2. Não sobrescreve uma conta já existente; resolva colisões de email administrativamente. Não importe bancos fornecidos por pessoas sem validar sua origem, pois o formato legado não autentica a propriedade da conta.
4. Confirme login e recuperação no servidor antes de distribuir o app atualizado. Remova os backups em texto seguindo a política de retenção e proteja qualquer backup necessário. Se não houver contas reais a preservar, comece com uma base nova e faça o cadastro pelo app.

Não existe fallback para autenticação local com senha antiga: uma senha redefinida deve passar a valer em todos os aparelhos. Os IDs de autenticação do servidor são independentes dos IDs dos perfis locais; não use um ID remoto como chave estrangeira no SQLite do aparelho.

O cadastro salva o perfil em transação local e chama a API antes de concluir. Em caso de erro local/rede, a transação é desfeita. Para permitir repetir após uma resposta perdida ou falha de commit local, a API aceita cadastrar novamente somente quando o email **e a senha existente** conferem. Senha diferente não sobrescreve contas.

## Contrato e proteção

Todas as rotas recebem JSON e retornam JSON com `Cache-Control: no-store`.

| POST | Campos | Resultado |
| --- | --- | --- |
| `/auth/register` | `email`, `password` | 201; 200 para repetição com a mesma senha |
| `/auth/login` | `email`, `password` | usuário; 401 se credenciais inválidas/inativo |
| `/auth/password/request` | `email` | 202 genérico; 429 quando limitado |
| `/auth/password/verify` | `email`, `code` | `resetToken` opaco; 400 se inválido/expirado |
| `/auth/password/reset` | `email`, `resetToken`, `password`, `confirmation` | 200 e volta ao login |

- Código de seis dígitos gerado por `Random.secure`, incluindo zeros iniciais, válido por 10 minutos e cinco tentativas. Ao validar, é substituído por uma autorização aleatória de 256 bits, válida por cinco minutos.
- Código e autorização são persistidos como HMAC-SHA256 com segredo do servidor. Senhas usam PBKDF2-HMAC-SHA256, 600.000 iterações e salt aleatório individual. [Cryptography](https://pub.dev/packages/cryptography) fornece a derivação; [Mailer](https://pub.dev/documentation/mailer/latest/) fornece o transporte SMTP.
- A nova senha deve ter entre 7 e 128 caracteres, compatível com a regra mínima existente do cadastro. Senha e confirmação precisam coincidir; espaços da senha são preservados.
- Reenvio invalida o desafio/autorização anterior: um envio por minuto, cinco por hora por email e dez por hora por IP. Cadastro: cinco por hora por IP. Login: dez por 15 minutos por email. Limite geral: 60 chamadas por 15 minutos por IP. Limites ficam no banco e sobrevivem a reinícios.
- A troca e o consumo da autorização ocorrem na mesma transação; duas requisições simultâneas não podem trocar a senha duas vezes. O login revalida a senha armazenada após a derivação para não aceitar credenciais substituídas durante a operação.
- Corpo máximo de 4 KiB; queries parametrizadas; erros não expõem SQL, credenciais, códigos ou existência da conta na solicitação. Não registre corpos dessas rotas no proxy.

## Verificação

```sh
# Na raiz
flutter test --no-pub
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
# Em server/
dart analyze --fatal-infos
dart test
```

Os testes cobrem as etapas da interface, validação, colagem dos seis dígitos, confirmação, retorno ao login, erros da API, alteração efetiva do login, código inválido, bloqueio por tentativas, expiração, reenvio, conta inexistente/inativa, autorização vinculada ao email, consumo concorrente, persistência de limites e falha do remetente. O repositório mantém avisos de estilo/validação anteriores, mas os erros de compilação do cadastro foram corrigidos. A rotina GitHub Actions executa os testes Flutter e a análise/testes Dart.
