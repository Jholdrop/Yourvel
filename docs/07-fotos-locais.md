# Revisão de escopo: fotos no dispositivo

Em 27/10/2026, conforme orientação do professor informada pelo aluno, o armazenamento da foto passa de Firebase Storage para arquivo no dispositivo. Este documento e o README prevalecem sobre as propostas anteriores dos documentos 01–06.

## Requisitos atuais

- RF01: manter cadastro, login e recuperação de senha com Firebase Authentication.
- RF02: selecionar JPEG/PNG da galeria, validar formato e limite de 5 MiB e mostrar prévia.
- RF03: copiar os bytes para a pasta privada permanente do app, por usuário e ID de lembrança. Não guardar apenas o endereço temporário retornado pelo seletor da galeria.
- RF04: gravar no Firestore nome, memória, GeoPoint, origem da localização, data do servidor, `imageStorage: local` e `imagePath` relativo.
- RF05: listar documentos do usuário em tempo real e resolver o caminho do banco dentro da pasta privada para exibir a foto.
- RF06: informar quando a imagem não existir no aparelho, sem impedir a leitura da memória.
- RF07: excluir documento e cópia local mediante confirmação; permitir repetir após falha.
- RF08: manter busca de cidades e captura opcional da localização atual.
- RNF01: impedir leitura/gravação em caminhos de outro usuário ou fora da pasta privada.
- RNF02: validar o documento nas regras do Firestore; nenhum usuário pode acessar documentos de outra conta.
- RNF03: fornecer progresso e preservar o conteúdo do formulário para repetir o salvamento com o mesmo ID.

## Critérios de aceite

1. Criar uma lembrança com foto, fechar e abrir o app: texto e foto continuam disponíveis no mesmo dispositivo.
2. Confirmar que o documento contém caminho relativo e GeoPoint, sem foto em base64 ou URL do Storage.
3. Sair e entrar com a mesma conta mantém acesso à foto; entrar com outra conta não exibe o diário anterior.
4. Outro dispositivo pode ler o texto após login, mas informa ausência da foto local.
5. Excluir uma lembrança remove o documento e o arquivo no aparelho em que a operação foi feita.
6. Regras rejeitam acesso de terceiros, caminhos incorretos, campos extras e timestamp forjado.
7. Nenhuma operação do fluxo chama Firebase Storage ou Cloud Functions.

## Limitações e consistência

Desinstalar ou limpar dados pode apagar as fotos. Não existe backup/sincronização de imagens no Firestore. Fotos presentes em outro dispositivo não podem ser removidas remotamente por este modelo.

Uma gravação confirmada pelo servidor com resposta perdida pode ser reconhecida na próxima tentativa pelo mesmo ID. Se o app for encerrado antes de concluir, pode restar um arquivo órfão: não há transação entre o sistema de arquivos e o Firestore. O formulário permite descarte explícito enquanto estiver aberto.

O Firestore valida o formato do caminho, mas não pode verificar a existência de arquivo no dispositivo. O cliente também restringe a resolução de caminhos à pasta e ao usuário atuais.

## Validação

Os testes e evidências desta revisão são independentes dos testes históricos com Storage. Consultar o resultado de `flutter test`, `flutter analyze` e `npm run test:rules`; a execução manual Android verifica seleção da galeria, salvamento, reabertura e exclusão. O navegador não implementa este armazenamento local de fotos.

Resultados em 27/10/2026: análise estática sem problemas, 14 testes Flutter aprovados, 2 testes de regras aprovados no emulador, APK debug compilado e instalado no BlueStacks. Regras publicadas no projeto `yourvel-b5a34`. O formulário atualizado foi verificado visualmente. O teste manual completo de salvar, reabrir e excluir uma foto pela galeria ainda precisa ser concluído; a automação da seleção de arquivo no BlueStacks não finalizou essa etapa.
