# 5. Plano de execução e validação

## 5.1 Marcos e dependências

| Marco | Entrega | Condição de conclusão |
| --- | --- | --- |
| M1 — Especificação | Documentação, escopo e critérios de aceite | Requisitos identificados e decisões pendentes registradas |
| M2 — Fundação | Projeto Flutter, arquitetura, Firebase de desenvolvimento e emuladores | App inicializa e regras começam negando acesso indevido |
| M3 — Identidade | Cadastro, login, sessão, logout e recuperação | CA01–CA05 e CA21 validados |
| M4 — Registro | API de lugares, formulário, galeria e upload | CA06–CA14 validados; URL privada resolvida |
| M5 — Diário | Listagem em tempo real, detalhes e exclusão | CA15–CA18 validados |
| M6 — Qualidade | Segurança, responsividade, erros e documentação de execução | CA17 e CA20, análise estática e testes aprovados |
| M7 — Entrega | GitHub, README final e evidências | Execução reproduzida a partir de checkout limpo |
| Bônus | Localização atual e microanimações | Somente após escopo principal estável; CA19 validado |

M3 depende de M2; M4 depende de autenticação e definição do provedor; M5 depende do modelo e persistência. Regras de segurança acompanham cada funcionalidade, sem serem adiadas ao final.

## 5.2 Estratégia de testes

| Camada | Casos essenciais | Evidência esperada |
| --- | --- | --- |
| Unidade | Limites de campos, conversão GeoPoint, coordenação do upload e falhas parciais | Testes automatizados de regras de negócio e repositórios |
| Widget | Validação, estados de erro, progresso e bloqueio de envio duplicado | Testes das interações críticas |
| Regras Firebase | Acesso anônimo, proprietário, usuário distinto, campos inesperados, tipos incorretos, timestamps, limites e MIME | Suíte automatizada nos emuladores de Firestore e Storage |
| Integração | Cadastro → registro → diário → detalhes → exclusão | Execução em emulador Android ou dispositivo |
| Segurança da imagem | Leitura autenticada, conta distinta, URL com token e revogação | Resultado registrado em ambiente de teste; sem URLs reais na evidência pública |
| Manual | Rede interrompida em cada etapa, API indisponível, galeria cancelada, reinício, troca de conta e layouts | Checklist com resultado, data e dispositivo |

As validações devem incluir valores imediatamente abaixo, no limite e acima do permitido. Falhas simuladas de upload e persistência precisam confirmar que não há falso sucesso nem exclusão de foto pertencente a registro confirmado.

## 5.3 Rastreabilidade da avaliação

| Critério da atividade | Atendimento planejado | Evidência de entrega |
| --- | --- | --- |
| Login e registro | RF01–RF03 | Fluxo demonstrável e testes de sessão |
| Modelagem lógica | RN01–RN08, documento de arquitetura | Documentos com GeoPoint e timestamps corretos |
| Firebase Storage | RF08–RF11 | Upload por proprietário, progresso e caminho privado |
| Privacidade e integridade | RNF01, política de autorização | Regras versionadas, testes cruzados e validação de tokens |
| Integração em tempo real | RF05 | Atualização entre duas sessões do mesmo usuário |
| API externa | RF06 | Busca real com atribuição e tratamento de erro |
| Arquitetura limpa | RNF02–RNF04 | Separação de UI, estado, contratos e integrações |
| UX e robustez | RF15, RNF05–RNF08 | Estados vazios, erros, acessibilidade e layout adaptável |
| Planejamento e organização | Marcos M1–M7 | Issues, histórico real de commits e documentação atualizada |
| Resolução de problemas | Tratamento de falhas parciais e riscos | Registro breve de problemas, hipóteses, solução e validação |
| Mentalidade de qualidade | Critérios de aceite e bônus condicionado | Revisões, correções verificadas e refinamentos |
| Entrega GitHub | RNF10 | Repositório executável com README reproduzível |

Cloud Functions não é obrigação do cenário; só adicionar se uma necessidade técnica concreta justificar. Storage, Firestore e Auth compõem o backend inicial.

## 5.4 Gestão com Git e GitHub

- Criar issues pequenas ligadas aos IDs dos requisitos e seus critérios de aceite.
- Fazer commits coerentes conforme o trabalho ocorrer, por exemplo `docs: definir requisitos do diario` e `feat: adicionar autenticacao`.
- Não fabricar histórico de desenvolvimento ou evidências de autoria.
- Revisar alterações e remover credenciais antes de publicar.
- Usar checklist de aceite para registrar o que foi implementado, testado e o que permanece pendente.

## 5.5 Riscos e respostas

| Risco | Impacto | Resposta planejada |
| --- | --- | --- |
| Token de download permite acesso por link | Exposição de fotos fora das regras do SDK | Validar revogação e leitura autenticada; bloquear aceite se privacidade não estiver resolvida |
| Upload concluído e documento não salvo | Arquivo órfão | Verificar confirmação e executar limpeza compensatória com nova tentativa |
| Exclusão parcialmente concluída | Documento sem imagem | Estado de erro claro e exclusão repetível |
| API tem restrições de uso ou custo | Busca indisponível ou despesa inesperada | Verificar termos antes da escolha, limitar chamadas e tratar falhas |
| Firebase exige configuração de faturamento | Impedimento de provisionamento | Verificar requisitos atuais antes de criar recursos; desenvolver com emuladores |
| Imagens grandes ou conexão instável | Demora e falha no envio | Limite de tamanho, prévia, progresso e preservação do formulário |
| Cache permanece após logout | Exposição no aparelho compartilhado | Cache por sessão e teste de troca de conta |
| Prazo insuficiente | Funcionalidades incompletas | Entregar P0 primeiro, depois P1 e bônus por último |

## 5.6 Checklist de conclusão

- [ ] Requisitos P0 implementados e critérios correspondentes aprovados.
- [ ] Complementos P1 concluídos ou limitações explicitamente acordadas e documentadas.
- [ ] Regras do Firestore e Storage publicadas e testes de autorização aprovados.
- [ ] Política de URL de download resolvida e verificada.
- [ ] Nenhum erro crítico ou falso sucesso nos fluxos de upload e exclusão.
- [ ] Formatação, análise estática e testes pertinentes aprovados.
- [ ] Layout e ampliação de texto validados.
- [ ] README contém versões, instalação, configuração, execução, testes e limitações reais.
- [ ] Código-fonte e regras disponíveis no GitHub, sem segredos administrativos.
- [ ] Evidências reais de funcionamento registradas, sem fotos ou coordenadas pessoais expostas.

## 5.7 Situação desta etapa

O levantamento inicial evoluiu para uma implementação Flutter com backend Firebase e ambiente local emulado. Consulte [Implementação e validação](06-implementacao.md) para decisões efetivas, verificações realizadas e pendências de configuração/publicação. A documentação não representa aprovação do docente nem publicação em produção.
