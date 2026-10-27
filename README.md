# Yourvel — diário de viagens

Aplicativo Flutter Android com login Firebase, diário em tempo real no Cloud Firestore, busca de cidades e fotos guardadas **no próprio dispositivo**.

## Protótipo

[Acessar a prototipagem do Yourvel no Google Stitch](https://stitch.google.com/projects/18044630015424928556).

## Alteração de escopo aprovada pelo professor

A foto não é enviada ao Firebase Storage. Ela é copiada da galeria para uma pasta privada permanente do aplicativo, obtida com `getApplicationSupportDirectory` do [path_provider](https://pub.dev/packages/path_provider). O Firestore recebe apenas o caminho relativo, os textos, as coordenadas e a data.

- Fotos disponíveis somente no dispositivo onde foram salvas.
- Limpar os dados ou desinstalar o aplicativo pode apagar as fotos. O Firestore não contém cópia delas.
- Em outro aparelho, o diário pode exibir os textos e a mensagem “Foto indisponível neste dispositivo”.
- Logout mantém as fotos locais para o próximo login da mesma conta; caminhos são separados por usuário.
- A implementação atual de fotos requer Android. O navegador não acessa o armazenamento privado do Android.
- Firebase Storage, Cloud Functions e plano Blaze não são necessários para o fluxo atual.

## Funcionalidades

Cadastro, login, recuperação de senha, listagem em tempo real, criação e exclusão de lembranças, seleção de foto JPEG/PNG até 5 MiB, busca de cidades Open-Meteo/GeoNames e coordenadas atuais opcionais.

## Executar no Android / BlueStacks

Requisitos: Flutter, Android SDK, Java 21 e um projeto Firebase com Authentication por email/senha e Cloud Firestore habilitados.

1. Registre o pacote Android `br.com.mundoafora.yourvel` no Firebase.
2. Coloque o arquivo de configuração em `android/app/google-services.json` (não versionado).
3. Execute `flutter pub get`.
4. Publique as regras com os comandos abaixo, autenticado na conta responsável pelo projeto.
5. Inicie o BlueStacks com ADB habilitado; confirme a conexão com `adb devices`.
6. Selecione **Yourvel BlueStacks (Firebase real)** no VS Code ou execute:

```powershell
flutter run -d 127.0.0.1:5555
```

O endereço ADB pode variar. Após alterar a configuração Firebase ou os plugins, faça uma execução completa; hot reload não basta.

### Publicar regras

```powershell
npm install
npx firebase login
npx firebase deploy --only firestore:rules --project SEU_PROJECT_ID
```

O projeto local está associado a `yourvel-b5a34` em `.firebaserc`. A configuração pública do cliente não substitui as regras. Não publique tokens nem contas de serviço.

## Modelagem e segurança

Coleção `users/{uid}/travel_entries/{id}`:

| Campo | Tipo / finalidade |
| --- | --- |
| `placeName` | Texto, 1–100 caracteres |
| `memory` | Texto, 1–1000 caracteres |
| `imagePath` | Caminho relativo `users/{uid}/travel_entries/{id}/photo` |
| `imageStorage` | Valor `local` |
| `coordinates` | Firestore GeoPoint |
| `locationSource` | `places` ou `device` |
| `placeProvider` | `open-meteo` ou `device` |
| `createdAt` | Timestamp gerado pelo servidor |

O app resolve `imagePath` dentro da pasta privada local. Regras validam campos, tipos, tamanho, caminho do dono e timestamp; usuários só podem ler, criar e excluir seus próprios documentos. Atualizações são bloqueadas. O Firestore não consegue verificar se o arquivo existe no aparelho.

Ao salvar: validar → copiar foto localmente → gravar documento. Tentativas reutilizam o mesmo ID e preservam os campos em caso de falha. Ao excluir: confirmar exclusão no Firestore → remover foto local. Uma falha entre serviços pode deixar uma foto local órfã; o descarte pode ser repetido. Não existe transação atômica entre arquivos locais e Firestore.

## Testes e build

```powershell
flutter analyze
flutter test
npm install
npm run test:rules
flutter build apk --debug
```

`npm run test:rules` usa Java 21 e emuladores locais; não altera o projeto real. Testa isolamento de usuários, criação, leitura, exclusão e rejeição de payloads inválidos. Testes Flutter cobrem interface, validações e persistência/proteção dos caminhos locais.

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Para loja, configurar assinatura de produção.

Para desenvolvimento sem Firebase real, use dois terminais:

```powershell
npm run emulators
```

```powershell
flutter run --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=10.0.2.2
```

O host acima corresponde ao emulador Android padrão. No BlueStacks, a conectividade com o host depende da configuração de rede.

## Organização

- `lib/features/auth`: autenticação e telas.
- `lib/features/travel/domain`: entidades.
- `lib/features/travel/data`: Firestore, fotos locais, API e localização.
- `lib/features/travel/presentation`: diário, formulário e detalhes.
- `firestore.rules`: autorização e validação.
- `test/local_photos_test.dart`: arquivos locais.
- `test/local_firestore_rules.test.cjs`: regras atuais.
- `docs/07-fotos-locais.md`: mudança de escopo e critérios de aceite.

Os documentos 01–06, a pasta `functions/`, `storage.rules` e os testes `backend_validation.test.cjs`, `firebase_rules.test.cjs` e `browser_smoke.cjs` registram a versão anterior com Storage. Não fazem parte do fluxo atual nem comprovam validação da versão com fotos locais. A configuração Firebase atual não publica Functions nem Storage.

Busca de cidades: [Open-Meteo](https://open-meteo.com/en/docs/geocoding-api), dados GeoNames CC BY 4.0; serviço gratuito para uso não comercial. A busca retorna o centro da cidade. Não há edição de lembranças, múltiplas fotos ou sincronização de imagens entre aparelhos.
