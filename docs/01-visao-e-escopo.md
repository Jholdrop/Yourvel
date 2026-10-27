# 1. Visão e escopo

## 1.1 Contexto

A agência Mundo Afora deseja oferecer um diário visual no qual seus clientes possam guardar lembranças de lugares visitados. As fotos são conteúdo pessoal: cada usuário deve acessar apenas seus próprios registros.

## 1.2 Objetivo do produto

Permitir que uma pessoa autenticada registre uma memória com foto e localização e encontre esse conteúdo posteriormente em um diário simples, visual e privado.

**Resultado esperado:** cadastro → autenticação → criação de registro → upload da foto → persistência no Firestore → exibição no diário do proprietário.

## 1.3 Partes interessadas

| Parte | Interesse |
| --- | --- |
| Viajante | Guardar e consultar memórias com facilidade e privacidade |
| Agência Mundo Afora | Oferecer uma experiência útil e confiável |
| Desenvolvedor/aluno | Planejar, implementar, testar e documentar a solução |
| Docente/avaliador | Verificar atendimento ao briefing e qualidade técnica |

## 1.4 Plataforma e premissas

- Android será a plataforma inicial de implementação e validação.
- Layout adaptável a celulares e tablets; iOS poderá ser validado se houver ambiente disponível.
- Idioma inicial: português do Brasil.
- A pessoa precisa de conexão para autenticar, buscar lugares e salvar ou excluir registros.
- Firebase será o backend; não haverá servidor próprio no escopo inicial.
- Custos, cotas e requisitos de faturamento dos serviços serão verificados antes de provisionar recursos.
- A data de entrega ainda não foi informada; o planejamento usa marcos, sem estimativas de prazo fictícias.

## 1.5 Delimitação

| Categoria | Entregas |
| --- | --- |
| Obrigatório para este projeto | Auth, Firestore, Storage, galeria, GeoPoint, diário privado, API externa, progresso de upload, segurança e README |
| Complemento planejado | Recuperação de senha, detalhes, exclusão e testes de isolamento entre usuários |
| Bônus | Captura da posição atual e refinamentos de animação |
| Fora do escopo inicial | Rede social, compartilhamento público, mapas interativos, edição de registros, múltiplas fotos, roteiros, reservas e sincronização de gravações offline |

A API é opcional no briefing específico, mas aparece como exigência no escopo geral. Por isso, o consumo de uma API de lugares será obrigatório nesta proposta. As coordenadas também serão obrigatórias no registro, obtidas pela seleção de um resultado da busca ou, no bônus, pela localização atual.

## 1.6 Decisões pendentes

| Decisão | Diretriz inicial | Momento de resolução |
| --- | --- | --- |
| Nome definitivo | Yourvel | Antes de finalizar a identidade visual |
| Provedor de lugares | Avaliar serviço baseado em OpenStreetMap ou Google Places | Antes da integração; verificar documentação, termos, cotas e custo |
| Gerenciamento de estado | ChangeNotifier e injeção de dependências como proposta simples | Antes de iniciar a estrutura Flutter |
| Projeto e região Firebase | Ambientes de desenvolvimento e entrega identificados | Antes de criar dados reais |
| Política de retenção | Manter até exclusão pelo usuário; documentar limitações do protótipo | Antes de disponibilizar o aplicativo |

## 1.7 Definição de sucesso

A entrega é bem-sucedida quando um usuário consegue completar o fluxo principal, os dados aparecem em tempo real, outro usuário não consegue ler ou alterar esse conteúdo e um avaliador consegue executar o projeto seguindo o README.
