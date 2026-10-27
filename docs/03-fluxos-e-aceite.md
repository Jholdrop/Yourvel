# 3. Fluxos e critérios de aceite

## 3.1 Telas

| Tela | Elementos e comportamento |
| --- | --- |
| Abertura | Verificação da sessão e redirecionamento |
| Login | Email, senha, entrar, cadastrar e recuperar senha |
| Cadastro | Email, senha, confirmação e mensagens de validação |
| Recuperação | Email e confirmação genérica de solicitação |
| Meu diário | Cartões com foto, local e data; botão novo registro e sair |
| Novo registro | Busca de lugares, nome, memória, foto, prévia, coordenadas e salvar |
| Detalhes | Foto completa, memória, local, coordenadas, data e excluir |

Fluxo principal: **Abertura → Login/Cadastro → Meu diário → Novo registro → Meu diário → Detalhes**.

## 3.2 Histórias de usuário

| ID | História | Requisitos |
| --- | --- | --- |
| HU01 | Como viajante, quero criar uma conta e entrar para manter um diário privado | RF01–RF04 |
| HU02 | Como viajante, quero encontrar um local para registrar coordenadas sem digitá-las manualmente | RF06–RF07 |
| HU03 | Como viajante, quero anexar uma foto e uma memória para lembrar minha visita | RF08–RF11 |
| HU04 | Como viajante, quero consultar meu diário e os detalhes dos registros | RF05, RF12, RF15 |
| HU05 | Como viajante, quero remover uma lembrança que não desejo manter | RF13 |
| HU06 | Como viajante, quero usar minha localização atual para agilizar o registro | RF14 |

## 3.3 Cenários de aceite

| ID | Dado / Quando | Então |
| --- | --- | --- |
| CA01 | Sem conta, envio email válido e senhas válidas e iguais | A conta é criada e o diário privado é aberto |
| CA02 | Envio email inválido, confirmação diferente ou senha rejeitada pela política configurada | Vejo orientação compreensível e permaneço no formulário |
| CA03 | Tento entrar com credenciais inválidas | Recebo mensagem genérica; o diário não é aberto |
| CA04 | Há sessão válida e reabro o app | A sessão é restaurada antes da leitura do diário |
| CA05 | Estou no diário e encerro a sessão | Volto ao login e os registros anteriores deixam de estar acessíveis pela navegação |
| CA06 | Busco um local com ao menos 3 caracteres | Vejo resultados da API, atribuição exigida e opção de selecionar um local |
| CA07 | A API falha ou não retorna resultados | Vejo estado específico, posso tentar novamente e os campos já preenchidos são preservados |
| CA08 | Seleciono um resultado de lugar | Nome e coordenadas são preenchidos; o nome pode ser ajustado sem apagar a localização |
| CA09 | Seleciono uma foto válida da galeria | Vejo uma prévia; cancelar o seletor não causa erro |
| CA10 | Tento enviar imagem acima de 5 MiB ou formato não permitido | O envio é bloqueado com orientação; requisições diretas também são negadas pelas regras |
| CA11 | Preencho campos válidos e salvo | Vejo progresso, a foto é enviada e o documento contém URL, caminho e GeoPoint corretos |
| CA12 | Pressiono salvar várias vezes durante o envio | Apenas uma operação é executada e não surgem registros duplicados |
| CA13 | O upload falha ou a rede cai | Vejo erro e nova tentativa; formulário e prévia permanecem disponíveis |
| CA14 | O upload termina, mas o Firestore falha | Não vejo sucesso; o app tenta remover o objeto órfão e informa a possibilidade de tentar novamente |
| CA15 | Um registro é salvo em outra sessão do mesmo usuário | O diário recebe a atualização pelo stream sem exigir recarregamento manual |
| CA16 | Não possuo registros ou uma imagem falha ao carregar | Vejo convite para criar o primeiro registro ou substituto visual para a imagem, respectivamente |
| CA17 | Usuário B tenta ler, criar, alterar ou excluir conteúdo do usuário A | Firestore e Storage negam a operação; acesso anônimo também é negado |
| CA18 | Confirmo exclusão | Foto e documento são removidos; falha parcial é informada e permite nova tentativa |
| CA19 | Nego localização atual no fluxo bônus | O app continua utilizável pela busca de lugares |
| CA20 | Abro o formulário em 360 e 800 px e com texto ampliado | Campos e ações permanecem acessíveis, inclusive com teclado aberto |
| CA21 | Solicito recuperação para email cadastrado ou não cadastrado | A resposta visual não revela a existência da conta |

## 3.4 Estados e mensagens

- Busca: inicial, carregando, resultados, sem resultados e erro.
- Formulário: editando, validando, enviando imagem, salvando documento, concluído e falha.
- Durante envio, ações conflitantes ficam desabilitadas. Sair da tela exige aviso de operação em andamento ou bloqueio temporário; não pode haver abandono silencioso.
- Progresso percentual usa bytes enviados/total; na persistência do documento, usar indicador indeterminado com texto “Salvando registro”.
- Mensagens devem orientar a ação: “Não foi possível enviar a foto. Verifique sua conexão e tente novamente”.
- Não mostrar stack traces, códigos internos ou detalhes sensíveis ao usuário.
