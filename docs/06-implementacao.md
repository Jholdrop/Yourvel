# 6. Implementação e validação

Este documento e o README descrevem as decisões efetivas da implementação. Os documentos 01 a 05 preservam o levantamento inicial; quando houver diferença, esta seção registra a mudança.

## Decisões implementadas

| Tema | Implementação |
| --- | --- |
| Plataformas | Android e web; Flutter Material 3, português do Brasil |
| Estado | Estado local explícito dos formulários e streams de sessão e diário; sem dependência adicional de estado |
| Autenticação | Email/senha no Firebase Auth, confirmação no cadastro e recuperação com mensagem genérica |
| Localização | Open-Meteo/GeoNames para cidades, cache de consultas na sessão do formulário e geolocalização do dispositivo mediante permissão |
| Backend | Auth, Firestore, Storage e duas Cloud Functions callable |
| Segurança de escrita | Escritas do documento passam pelo Admin SDK após validação; regras do Firestore negam escritas diretas |
| Segurança da foto | Upload privado por UID, objeto imutável para o cliente, remoção de token público antes da criação do documento e leitura autenticada por bytes |
| URL | URL canônica de mídia sem token, armazenada junto ao caminho; não oferece compartilhamento público |
| Retentativa | ID e foto estáveis, campos preservados após primeira tentativa e finalização idempotente |
| Exclusão | Função remove objeto e documento; chamadas repetidas são permitidas |
| Cache | Firestore sem persistência local; imagens em memória são limpas no logout |
| Desenvolvimento | Projeto demo-yourvel com Auth, Firestore, Storage e Functions emulados |

## Mudanças em relação ao planejamento

- Nominatim foi substituído pelo Open-Meteo para que a busca acadêmica não exija chave nem serviço próprio. O campo identifica que as coordenadas da busca representam o centro de uma cidade.
- Coordenadas do dispositivo foram implementadas como bônus. A combinação de origem/provedor pode ser `places/open-meteo` ou `device/device`.
- Cloud Functions passou a ser necessária para remover tokens de download com privilégios administrativos e validar a finalização do registro.
- O campo `imageUrl` não guarda token público. A URL exige autenticação; a interface usa `imagePath` e leitura pelo SDK.
- As regras de criação dos documentos foram movidas para validação no backend, porque o cliente não pode finalizar fotos sem passar pela remoção de tokens.
- O aplicativo permite descartar a tentativa, removendo conteúdo já enviado. Não há rotina periódica de limpeza de objetos após encerramento forçado do processo.

## Validação

Verificações realizadas em 27/10/2026:

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | Sem problemas encontrados |
| `flutter test` | 12 testes aprovados, incluindo API, validações, autenticação, retentativa, descarte e texto ampliado |
| Botão Voltar do Android na navegação de sessão | Teste de widget aprovado, preservando confirmação de descarte |
| `npm test` | 4 testes de validação do backend aprovados |
| `npm run test:rules` | 4 cenários aprovados nos emuladores reais de Auth, Firestore, Storage e Functions |
| `npm run test:browser` | Aprovado no Chrome: cadastro, busca, seleção e exibição da foto, upload, diário, detalhes, exclusão e logout |
| Revogação de URL pública | URL anterior ao salvamento perde acesso; leitura autenticada continua funcionando |
| API real Open-Meteo | Consulta de Recife retornou nome e coordenadas sem chave |
| `flutter build web --dart-define=USE_EMULATORS=true` | Compilação concluída |
| APK debug Android com backend emulado | Compilação concluída para ARM, ARM64 e x86_64; artefato em `build/app/outputs/flutter-apk/app-debug.apk` |
| Dependências Node do backend | `npm install --prefix functions` concluiu com auditoria sem vulnerabilidades reportadas |

O build Android utiliza assinatura de desenvolvimento e backend local, não representa publicação em loja. Nesta máquina, os arquivos gerados de `build/app` foram preservados em `D:\Yourvel-build-cache\app-20261027`, acessíveis por junction no caminho normal do projeto, para contornar falta de espaço no disco C:. Isso não altera o código-fonte nem exige esse caminho em outro computador.

O compilador Android reporta avisos em dependências de terceiros sobre migração futura do Kotlin e APIs obsoletas. Eles não impediram o build atual. As ferramentas Node de desenvolvimento ainda reportam avisos moderados em dependências transitivas; o backend publicado tem dependências separadas e auditoria sem ocorrências na instalação realizada.

Testes automatizados não substituem a homologação da galeria e do GPS em aparelho físico com o projeto Firebase de produção. O teste de navegador e as capturas são descritos no README.

As capturas de login, cadastro e diário ficam em `build/screenshots`. A imagem do teste é uma fixture gráfica gerada pelo navegador, sem conteúdo pessoal. A busca é simulada apenas na suíte de navegador para torná-la determinística; houve verificação separada do endpoint real.

Neste ambiente Windows/Java 21, o runtime de regras do Storage reportou uma exceção de encerramento depois de concluir os testes com código 0. O script de testes registra os processos Java que ele próprio iniciou e encerra eventuais filhos restantes para liberar as portas; não procura processos de outras aplicações por porta.

## Pendências externas à implementação

- Selecionar o projeto Firebase real, configurar faturamento quando necessário, ativar serviços e publicar regras/funções.
- Preencher os identificadores públicos do cliente em `config/firebase.json` e configurar CORS/domínios autorizados.
- Validar seleção da galeria e permissões em aparelho físico do responsável.
- Configurar assinatura Android própria se houver publicação em loja.
- Definir e publicar no repositório GitHub do responsável.

## Limitações conhecidas

- A busca identifica cidades, não estabelecimentos ou pontos turísticos específicos.
- A validação de foto confere tamanho, MIME e assinatura inicial no cliente e no backend; não há pipeline de antivírus ou recodificação de imagens.
- O diário inicial não tem paginação, edição ou escrita offline.
- O Firebase não oferece transação única entre arquivo e documento; falhas parciais exigem nova tentativa ou descarte.
- Emuladores e builds de desenvolvimento não representam publicação em nuvem ou na loja.
