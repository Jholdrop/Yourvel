# 2. Levantamento de requisitos

## 2.1 Convenções

**P0:** indispensável para aceitar a entrega. **P1:** complemento planejado, executado após o fluxo principal. **P2:** bônus. Este documento é a linha de base dos requisitos; a implementação efetiva e as evidências estão em [Implementação e validação](06-implementacao.md).

## 2.2 Requisitos funcionais

| ID | Prioridade | Requisito verificável |
| --- | --- | --- |
| RF01 | P0 | Cadastrar usuário com email e senha por Firebase Authentication, validando campos e confirmação de senha |
| RF02 | P0 | Autenticar por email e senha, restaurar sessão válida e restringir o diário a usuários autenticados |
| RF03 | P0 | Encerrar a sessão e remover da interface os dados do usuário anterior |
| RF04 | P1 | Enviar solicitação de recuperação de senha, exibindo resposta que não revele se o email possui conta |
| RF05 | P0 | Listar apenas registros do usuário atual, em ordem decrescente de criação, por stream do Firestore |
| RF06 | P0 | Buscar lugares em API externa e permitir selecionar um resultado com nome, latitude e longitude |
| RF07 | P0 | Permitir ajustar o nome do local e escrever a memória após selecionar sua localização |
| RF08 | P0 | Selecionar uma imagem da galeria e apresentar prévia antes do envio |
| RF09 | P0 | Validar o formulário e enviar a imagem para caminho privado do proprietário no Storage |
| RF10 | P0 | Após upload e obtenção da URL, salvar nome, memória, URL, caminho da imagem, coordenadas GeoPoint e datas no Firestore |
| RF11 | P0 | Mostrar etapa e progresso de envio, impedir submissões simultâneas e informar sucesso ou erro |
| RF12 | P1 | Exibir detalhes com foto, nome, memória, coordenadas e data do registro |
| RF13 | P1 | Excluir um registro e sua foto após confirmação, tratando falhas parciais e permitindo nova tentativa |
| RF14 | P2 | Obter posição atual com permissão explícita, alternativa de busca e tratamento de permissão negada |
| RF15 | P0 | Exibir estados de carregamento, lista vazia, erro de rede, falha da API e indisponibilidade de imagem |

## 2.3 Regras de negócio

| ID | Regra |
| --- | --- |
| RN01 | Todo registro pertence a exatamente um usuário autenticado; propriedade não pode ser transferida |
| RN02 | Nome do local: obrigatório, entre 2 e 100 caracteres após remoção dos espaços nas extremidades |
| RN03 | Memória: obrigatória, entre 1 e 1.000 caracteres após remoção dos espaços nas extremidades |
| RN04 | Um registro possui exatamente uma foto; formatos aceitos: JPEG e PNG; limite de 5 MiB (5.242.880 bytes) no arquivo enviado |
| RN05 | Cada registro contém um GeoPoint; latitude entre −90 e 90 e longitude entre −180 e 180 |
| RN06 | A foto deve estar no Storage antes de o documento definitivo ser criado |
| RN07 | IDs do registro e do objeto devem ser estáveis durante uma tentativa e suas repetições para reduzir duplicações |
| RN08 | Datas de criação e atualização são definidas pelo servidor |
| RN09 | Cancelar seleção da galeria preserva o formulário e não inicia upload |
| RN10 | Falha ao salvar não pode ser apresentada como sucesso nem apagar silenciosamente os campos preenchidos |
| RN11 | Exclusões exigem confirmação explícita; a UI informa se a limpeza ficou incompleta |
| RN12 | Não existe leitura pública, inclusive para usuários autenticados que não sejam proprietários |

## 2.4 Requisitos não funcionais

| ID | Área | Critério de verificação |
| --- | --- | --- |
| RNF01 | Autorização | Regras negam acesso anônimo e acesso cruzado a documentos e arquivos, comprovado por testes nos emuladores |
| RNF02 | Arquitetura | Widgets não executam diretamente chamadas HTTP ou operações Firebase; serviços e repositórios encapsulam integrações |
| RNF03 | Código | Código formatado; análise estática sem erros e sem avisos pendentes antes da entrega |
| RNF04 | Estado | Estados de carregamento, sucesso e falha explícitos; listeners e tarefas são descartados ao sair da tela ou sessão |
| RNF05 | Responsividade | Fluxos principais utilizáveis em larguras lógicas de 360 e 800 px, sem overflow, com rolagem e teclado aberto |
| RNF06 | Acessibilidade | Controles identificáveis por leitor de tela, feedback além de cor e suporte a ampliação de texto de 200% nos fluxos principais |
| RNF07 | Rede | Timeout inicial de 15 s para busca; erros acionáveis e nova tentativa; nenhuma gravação offline silenciosamente considerada concluída |
| RNF08 | Eficiência | Busca explícita por botão, mínimo de 3 caracteres, limite de resultados e proteção contra solicitações simultâneas; adaptar limites ao provedor |
| RNF09 | Privacidade | Não registrar senhas, tokens, URLs de download ou coordenadas pessoais em logs de produção |
| RNF10 | Entrega | README permite reproduzir configuração e execução; versões e limitações conhecidas registradas |
| RNF11 | Qualidade | Testes de validação, persistência, recuperação de falhas e autorização passam antes da entrega |

O tempo total de upload depende da rede e do arquivo; a exigência é apresentar feedback desde o início da operação, sem prometer um tempo de conclusão fixo.
