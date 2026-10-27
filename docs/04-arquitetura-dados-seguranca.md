# 4. Arquitetura, dados e segurança

Este documento preserva a proposta original. A arquitetura efetivamente implementada, incluindo funções autenticadas para escrita e URLs sem token público, está em [Implementação e validação](06-implementacao.md) e no README.

## 4.1 Organização proposta

```text
lib/
  app/                     # Inicialização, tema e navegação
  core/                    # Erros, validações e utilitários comuns
  features/
    auth/
      data/                # Integração com Firebase Auth
      domain/              # Contratos e entidades
      presentation/        # Telas e estado
    travel_entries/
      data/                # Firestore, Storage e API de lugares
      domain/              # Registro, lugar e contratos
      presentation/        # Diário, formulário e detalhes
```

Widgets apresentam estado e enviam ações ao controlador. O controlador coordena regras e repositórios. Repositórios encapsulam SDKs e HTTP. A conversão entre entidade e documento Firestore fica na camada de dados. Dependências são injetadas para permitir testes com implementações falsas.

Proposta de integrações: Firebase Core/Auth/Firestore/Storage, cliente HTTP, seletor de imagens e biblioteca de localização apenas para o bônus. Seleção e versões serão registradas no projeto Flutter.

## 4.2 Modelo do Firestore

Coleção: `users/{uid}/travel_entries/{entryId}`. Não é necessário criar documento de perfil do usuário para usar a subcoleção; o Auth é a fonte da identidade.

| Campo | Tipo | Restrições |
| --- | --- | --- |
| ownerId | string | Igual ao uid do caminho e ao usuário autenticado; imutável |
| placeName | string | 2–100 caracteres, normalizado no cliente |
| memory | string | 1–1.000 caracteres, normalizado no cliente |
| imageUrl | string | URL retornada após upload; não usada como prova de propriedade |
| imagePath | string | Caminho canônico `users/{uid}/travel_entries/{entryId}/photo` |
| coordinates | GeoPoint | Latitude e longitude válidas |
| locationSource | string | `places` ou `device` |
| placeProvider | string | Identificador do provedor ou `device` |
| createdAt | Timestamp | Timestamp do servidor, imutável |
| updatedAt | Timestamp | Timestamp do servidor |
| schemaVersion | integer | Inicialmente 1 |

Exemplo conceitual, sem representar JSON executável:

```text
users/uid-exemplo/travel_entries/registro-exemplo
  ownerId: "uid-exemplo"
  placeName: "Parque Ibirapuera"
  memory: "Uma caminhada no fim da tarde."
  imageUrl: "<URL retornada pelo Storage>"
  imagePath: "users/uid-exemplo/travel_entries/registro-exemplo/photo"
  coordinates: GeoPoint(-23.5874, -46.6576)
  locationSource: "places"
  placeProvider: "<provedor escolhido>"
  createdAt: <timestamp do servidor>
  updatedAt: <timestamp do servidor>
  schemaVersion: 1
```

Consulta inicial: subcoleção do próprio usuário ordenada por `createdAt` decrescente. As regras autorizam consultas; não filtram documentos de outros usuários. Índices adicionais só serão definidos se as consultas implementadas exigirem. Paginação é evolução prevista para volumes maiores, fora do primeiro incremento.

## 4.3 Storage e upload

Objeto: `users/{uid}/travel_entries/{entryId}/photo`. O content type informa JPEG ou PNG; usar caminho fixo facilita validação e repetição idempotente.

1. Validar sessão, formulário, coordenadas e imagem.
2. Gerar uma vez o ID do registro e o caminho do objeto.
3. Enviar arquivo com metadados adequados e acompanhar progresso.
4. Obter URL de download.
5. Gravar documento com timestamps de servidor.
6. Confirmar conclusão e deixar o stream atualizar o diário.

Firestore e Storage não compartilham transação atômica. Se a etapa 5 falhar, primeiro verificar se a gravação foi confirmada, pois uma perda de resposta pode deixar o resultado incerto. Somente após confirmar a ausência do documento, tentar excluir o objeto enviado. Se a limpeza também falhar, registrar diagnóstico sem dados sensíveis e manter informação suficiente para reconciliação na próxima tentativa. Não prometer remoção automática de todos os órfãos sem implementar rotina específica.

Na exclusão, remover primeiro o objeto e depois o documento. Objeto já ausente conta como limpeza concluída. Se o documento não puder ser removido, ele pode ficar temporariamente com imagem indisponível; a UI deve informar falha parcial e permitir repetir a exclusão. A URL com token deve ser revogada pela remoção do objeto.

## 4.4 Política de autorização

As regras serão versionadas como `firestore.rules` e `storage.rules` e verificadas em emuladores antes de publicação.

| Recurso/operação | Política |
| --- | --- |
| Firestore leitura/exclusão | Exigir autenticação e uid igual ao proprietário do caminho |
| Firestore criação | Exigir proprietário correto, campos permitidos, tipos, limites, GeoPoint, caminho canônico e timestamps do servidor |
| Firestore atualização | Negar no escopo inicial, pois edição não faz parte da entrega |
| Storage leitura | Permitir somente ao proprietário autenticado por requisições autorizadas do SDK |
| Storage criação/substituição | Exigir proprietário, caminho esperado, tamanho máximo de 5 MiB e content type JPEG/PNG |
| Storage exclusão | Exigir proprietário; separar essa condição da validação de arquivo, pois exclusão não possui novo recurso |
| Demais caminhos | Negar por padrão |

Validar novamente no backend aquilo que não pode depender da interface. Metadados MIME não provam o conteúdo binário real do arquivo; inspeção profunda demandaria processamento adicional fora do escopo inicial. Regras também não comprovam que uma string de URL corresponde ao objeto informado; a associação usa o caminho canônico e a coordenação do repositório.

### Privacidade das URLs de download

URLs de download com token do Storage funcionam como links de acesso: quem obtiver uma pode conseguir abrir a imagem sem autenticação. Portanto, **regras restritas por usuário não bastam para garantir privacidade de uma URL compartilhada**.

Para atender ao enunciado, a URL será armazenada no documento privado. Para exibir imagens no app, usar leitura autenticada pelo SDK a partir de `imagePath`, com cache vinculado à sessão e limpo ao sair. Não expor URLs em telas, logs ou compartilhamento.

Antes do aceite de segurança, validar em emulador e ambiente de teste a revogação do token após obter a URL exigida pelo exercício, preservando a leitura autenticada pelo caminho. A URL persistida poderá ficar inválida por decisão de privacidade. Se esse fluxo não for viável no ambiente escolhido, resolver a alternativa com o docente antes da entrega; não declarar isolamento absoluto com URLs ativas. Esse ponto é um risco técnico aberto, não uma garantia já implementada.

## 4.5 API de lugares

- Adaptador retorna modelo interno com nome, latitude, longitude e provedor.
- Busca por botão evita pressupor que o serviço permita autocomplete a cada tecla.
- Antes de escolher o serviço, verificar autenticação, políticas de uso, atribuição, limites e disponibilidade para aplicativo móvel.
- Se houver chave pública de cliente, aplicar restrições de aplicativo e API suportadas pelo provedor. Segredos de servidor exigem proxy seguro; nunca embuti-los no app.
- Erros, resultados vazios e timeout não apagam o formulário.
- Localização atual permanece opcional e depende de permissão; não há rastreamento contínuo ou em segundo plano.

## 4.6 Sessão e dados locais

Ao sair, cancelar streams, descartar estado e limpar cache de fotos da sessão. Definir e testar a política de cache do Firestore antes da implementação para evitar exposição entre contas no mesmo aparelho. O escopo inicial não oferece gravações offline; operações pendentes não devem reaparecer como registros confirmados de outro usuário.
