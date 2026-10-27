# Yourvel — Diário de viagens

Aplicativo Flutter do cenário **WanderLog**, para a agência fictícia **Mundo Afora**. Cada usuário tem um diário com fotos pessoais, memórias e coordenadas geográficas.

O projeto contém aplicação Android/web, autenticação Firebase, Firestore em tempo real, Storage, funções de backend, regras de segurança e testes. A configuração de produção deve apontar para o seu projeto Firebase. É possível executar localmente com os emuladores, sem provisionar serviços pagos.

## Funcionalidades

- Cadastro com confirmação de senha, login, recuperação de senha e logout.
- Sessão persistida e navegação privada por usuário.
- Diário atualizado em tempo real, estado vazio e detalhes de cada memória.
- Busca de cidades por API externa Open-Meteo/GeoNames, sem chave para uso não comercial.
- Localização atual mediante permissão, como alternativa à busca.
- Seleção da galeria, prévia, JPEG/PNG de até 5 MiB e progresso de upload.
- Nome personalizado, memória e coordenadas persistidas como `GeoPoint`.
- Repetição do mesmo envio sem duplicar registros.
- Exclusão com confirmação e descarte de envio incompleto.
- Fotos lidas pelo SDK autenticado, sem expor links públicos na interface.

## Requisitos de ambiente

- Flutter estável com Dart ≥ 3.8; ambiente utilizado: Flutter 3.44.8 / Dart 3.12.2.
- Chrome para web; Android SDK e Java 21 para Android e emuladores Firebase.
- Node.js 22 para o backend (o emulador também pode executar com a versão local, exibindo aviso se diferente).
- npm para instalar as ferramentas de teste e Firebase CLI local.

As versões resolvidas do Flutter ficam em `pubspec.lock`; as do backend nos arquivos `package-lock.json`. Não é necessário instalar ferramentas globalmente: os comandos `npm run` usam a CLI local.

## Executar localmente, sem projeto Firebase real

Na raiz do repositório, instale as dependências:

```powershell
flutter pub get
npm install
npm install --prefix functions
```

Em um terminal, mantenha os emuladores abertos:

```powershell
npm run emulators
```

Em outro terminal, execute no navegador:

```powershell
flutter run -d chrome --web-port=7357 --dart-define=USE_EMULATORS=true
```

Crie uma conta pela tela de cadastro e registre sua primeira memória. O painel dos emuladores fica em `http://127.0.0.1:4000`. Emails de recuperação são simulados: o link aparece no terminal do emulador de Auth.

Para emulador Android, inicie um dispositivo e execute:

```powershell
flutter run --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=10.0.2.2
```

Os emuladores Firebase usam o projeto **demo-yourvel**, isolado de produção. Por padrão, seus dados são temporários. Para preservá-los entre sessões:

```powershell
npx firebase emulators:start --project demo-yourvel --export-on-exit=.emulator-data
# Nas execuções seguintes:
npx firebase emulators:start --project demo-yourvel --import=.emulator-data --export-on-exit=.emulator-data
```

O VS Code também tem configurações de execução em `.vscode/launch.json`. Execute primeiro os emuladores. No dispositivo físico, usar Firebase em produção é a opção mais simples; o acesso aos emuladores pela rede exige configurar hosts, firewall e conectividade do computador.

## Configurar Firebase real

1. Crie ou selecione seu projeto no console Firebase.
2. Em Authentication, habilite **Email/Senha**. Configure os domínios autorizados usados na web, incluindo `localhost` no desenvolvimento.
3. Crie o banco Cloud Firestore e o bucket Storage. Verifique os requisitos atuais de faturamento; Cloud Functions e Storage podem exigir o plano Blaze.
4. Registre os aplicativos web e Android (pacote `br.com.mundoafora.yourvel`) que deseja utilizar. Use a configuração pública correspondente à plataforma executada, inclusive o `appId` do aplicativo Android ao rodar no celular. O app inicializa Firebase explicitamente por `FirebaseOptions`; não há credenciais administrativas no cliente.
5. Copie o arquivo de exemplo e preencha os valores com a configuração do console:

```powershell
Copy-Item config/firebase.example.json config/firebase.json
```

```json
{
  "FIREBASE_API_KEY": "chave-publica-do-cliente",
  "FIREBASE_APP_ID": "1:123456789:web:identificador",
  "FIREBASE_MESSAGING_SENDER_ID": "123456789",
  "FIREBASE_PROJECT_ID": "seu-projeto",
  "FIREBASE_STORAGE_BUCKET": "bucket-exato-do-console.firebasestorage.app",
  "FIREBASE_AUTH_DOMAIN": "seu-projeto.firebaseapp.com"
}
```

O bucket pode terminar em `.appspot.com` ou `.firebasestorage.app`; copie o nome real. O backend usa o bucket padrão do mesmo projeto, que deve corresponder à configuração do cliente.

6. Publique backend e regras usando sua conta autorizada:

```powershell
npx firebase login
npx firebase deploy --project SEU_PROJECT_ID --only "firestore,storage,functions"
```

As funções são `finalizeEntry` e `deleteEntry`, em `us-central1`. O Admin SDK usa a identidade do ambiente Firebase; nenhuma chave de conta de serviço precisa estar no app ou repositório.

7. Para ler os bytes das fotos na web, configure CORS no bucket com os domínios efetivamente utilizados. Há exemplo restrito a desenvolvimento em `config/storage.cors.json`. Com Google Cloud CLI autenticada:

```powershell
gcloud storage buckets update gs://SEU_BUCKET --cors-file=config/storage.cors.json
```

Adicione a origem HTTPS do seu site ao JSON antes de usar em produção. CORS não substitui autorização.

8. Execute:

```powershell
flutter run -d chrome --web-port=7357 --dart-define-from-file=config/firebase.json
# Android:
flutter run --dart-define-from-file=config/firebase.json
```

Sem configuração válida, o aplicativo apresenta uma tela de orientação; não simula login ou persistência.

## Segurança e modelo de dados

Documentos: `users/{uid}/travel_entries/{entryId}`. Fotos: `users/{uid}/travel_entries/{entryId}/photo`.

1. O usuário autenticado envia a foto para seu caminho no Storage.
2. `finalizeEntry` verifica identidade, campos, coordenadas, existência, MIME e tamanho do arquivo.
3. A função remove o token de download público e armazena uma URL de mídia **sem token**, que exige autenticação. Não é um link público para compartilhar.
4. A função grava o documento com `ownerId`, textos, `imageUrl`, `imagePath`, `GeoPoint`, origem da localização e timestamps de servidor.
5. A interface recebe o documento pelo stream e carrega a foto com `getData()` autenticado.

As regras negam acesso anônimo, acesso de outros usuários, alteração de fotos e gravações diretas no Firestore. O backend deriva os caminhos do UID autenticado, sem aceitar `ownerId` fornecido pelo cliente. Cache persistente do Firestore está desativado e o cache de imagens é limpo ao sair.

Storage e Firestore não têm transação conjunta. O ID estável permite repetir a finalização se houver perda da resposta. O formulário preserva os campos e oferece descarte autenticado, que remove foto e documento. Fechar o processo à força após upload pode deixar um objeto órfão privado; limpeza periódica automática não faz parte desta versão.

## Testes e builds

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
npm test
npm run test:rules
# Teste completo pela interface (Chrome instalado e build web em modo emulador):
npm run test:browser
```

`test:rules` inicia e encerra emuladores automaticamente. Não execute outra instância nas mesmas portas. A suíte verifica acesso cruzado, autenticação, restrições de arquivo, validação das funções, criação de conta, upload, GeoPoint, repetição do salvamento, remoção de tokens e exclusão.

`test:browser` usa Chrome instalado via Playwright, inicia os emuladores e um servidor local e percorre cadastro → busca → foto → salvamento → detalhes → exclusão → logout. A resposta da busca é controlada nesse teste para evitar instabilidade externa; o adaptador real é verificado separadamente. Capturas ficam em `build/screenshots`.

```powershell
# Web de demonstração local; requer emuladores em execução:
flutter build web --dart-define=USE_EMULATORS=true
# Servir o build local mantendo os emuladores em outro terminal:
npm run serve:web
# Web e APK conectados ao projeto real:
flutter build web --dart-define-from-file=config/firebase.json
flutter build apk --debug --dart-define-from-file=config/firebase.json
```

Saídas: `build/web` e `build/app/outputs/flutter-apk/app-debug.apk`. Para publicar em loja, configure assinatura própria de produção; o template Android ainda usa assinatura de desenvolvimento.

## Organização

```text
lib/
  app.dart                    # Tema e navegação de sessão
  main.dart                   # Firebase e seleção de ambiente
  core/                       # Validações e mensagens
  features/auth/              # Autenticação e telas
  features/travel/
    domain/                   # Entidades
    data/                     # Firebase, API e localização
    presentation/             # Diário, formulário e detalhes
functions/                    # Finalização e exclusão autenticadas
test/                         # Flutter, validações Node e emuladores
docs/                         # Requisitos e decisões
```

## Documentação e limites

| Documento | Conteúdo |
| --- | --- |
| [Visão e escopo](docs/01-visao-e-escopo.md) | Problema, público e limites |
| [Requisitos](docs/02-requisitos.md) | Requisitos e regras de negócio |
| [Fluxos e aceite](docs/03-fluxos-e-aceite.md) | Jornadas e cenários |
| [Arquitetura planejada](docs/04-arquitetura-dados-seguranca.md) | Proposta original, com decisões atualizadas no documento abaixo |
| [Planejamento](docs/05-plano-e-validacao.md) | Marcos e avaliação |
| [Implementação e validação](docs/06-implementacao.md) | Decisões efetivas, evidências e pendências externas |

A busca retorna cidades e suas coordenadas centrais, não pontos turísticos. O nome do lugar pode ser personalizado e a posição atual oferece coordenadas do local da visita. Não há edição, múltiplas fotos, compartilhamento público, gravação offline ou suporte iOS nesta entrega.

O serviço gratuito do Open-Meteo destina-se a uso não comercial. Para operação comercial da agência, contratar plano compatível ou substituir o adaptador. Resultados geográficos usam dados GeoNames, com atribuição CC BY 4.0.

## Entregar no GitHub

O repositório Git local foi inicializado. Depois de revisar o código e criar um repositório vazio na sua conta:

```powershell
git add .
git commit -m "feat: implementar diario de viagens com Flutter e Firebase"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/Yourvel.git
git push -u origin main
```

O histórico deve refletir as alterações reais; não é necessário fabricar commits anteriores à implementação.

Referências oficiais: [FlutterFire](https://firebase.google.com/docs/flutter/setup), [upload no Storage](https://firebase.google.com/docs/storage/flutter/upload-files), [funções callable](https://firebase.google.com/docs/functions/callable), [Open-Meteo Geocoding](https://open-meteo.com/en/docs/geocoding-api).

Não versionar `config/firebase.json`, dados dos emuladores, tokens ou contas de serviço. A configuração pública do cliente não concede acesso por si só: as regras e a validação do backend são obrigatórias. A publicação em projeto Firebase real e no GitHub depende das contas e destinos do responsável pelo projeto.
