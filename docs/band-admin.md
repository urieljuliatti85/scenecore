# Membership, Band Admin & Administration

## Objetivo

Implementar no SceneCore um sistema de memberships para bandas independentes, composto por três planos:

- Fan
- Supporter
- Core Member

O sistema também deve possuir dois níveis administrativos distintos:

1. **Band Admin** — administração de uma banda específica.
2. **SceneCore Administrator** — administração global da plataforma.

A implementação deve preservar uma separação clara entre:

- o que o fã pode acessar;
- o que a banda pode oferecer;
- o que o administrador da plataforma pode administrar.

Não criar três painéis administrativos separados para os três planos.

Deve existir **um único Band Admin**, com funcionalidades relacionadas aos recursos disponíveis para aquela banda.

---

# 1. Regras fundamentais

Antes de escrever código:

1. Inspecione a estrutura atual da aplicação.
2. Identifique como usuários, bandas, autenticação, pagamentos e conteúdo estão atualmente implementados.
3. Verifique os modelos existentes antes de criar novos.
4. Reutilize estruturas existentes quando fizer sentido.
5. Não crie abstrações prematuras.
6. Não introduza funcionalidades que não estejam especificadas neste documento.
7. Não implemente lógica duplicada para cada plano.
8. Use regras de acesso baseadas em membership/benefits.
9. Mantenha a lógica de negócio fora dos controllers.
10. Prefira modelos, policies e services simples.
11. Não altere funcionalidades existentes sem necessidade.
12. Antes de implementar uma mudança estrutural, explique o impacto e verifique se ela é compatível com a arquitetura existente.

---

# 2. Hierarquia do produto

A arquitetura conceitual deve ser:

```text
SceneCore
│
├── Fans
│   ├── Fan
│   ├── Supporter
│   └── Core Member
│
├── Bands
│   └── Band Admin
│
└── SceneCore Administration
    └── SceneCore Administrator
```

Os memberships pertencem ao relacionamento entre usuário e banda.

Um usuário pode ter memberships diferentes em bandas diferentes.

Exemplo:

```text
User
 ├── Band A → Fan
 ├── Band B → Supporter
 └── Band C → Core Member
```

Não assumir que o plano é uma propriedade global do usuário.

---

# 3. Membership Plans

Os três planos iniciais são:

## Fan

Preço:

```text
R$ 10
```

Também deve existir representação em dólar quando a interface ou configuração exigir conversão.

Benefícios:

- Feed exclusivo da banda
- Notícias antes do público geral
- Fotos e pequenos vídeos de bastidores
- Algumas demos e versões alternativas
- Enquetes sobre repertório, capas ou merchandising
- Badge Fan no perfil
- Acesso à comunidade de assinantes

Promessa:

> Fique mais perto da banda.

---

## Supporter

Preço:

```text
R$ 25
```

Benefícios:

- Todos os benefícios do Fan
- Lançamentos antecipados
- Demos completas e gravações de ensaio
- Diário de composição e produção
- Vídeos e transmissões exclusivas
- Nome nos créditos digitais como apoiador
- Desconto em merchandising e ingressos
- Acesso antecipado às vendas

Promessa:

> Apoie a música e acompanhe sua criação.

---

## Core Member

Preço:

```text
R$ 50
```

Benefícios:

- Todos os benefícios do Supporter
- Lives privadas periódicas
- Sessões de perguntas e respostas
- Conteúdos raros: arquivos, gravações antigas e versões inéditas
- Prioridade em ingressos e produtos limitados
- Descontos maiores
- Nome em uma página permanente de apoiadores
- Créditos em encartes ou lançamentos selecionados
- Sorteios de itens autografados
- Mensagem direto para a banda
- Possibilidade de votar em decisões previamente escolhidas pela banda
- Acesso a encontros virtuais ou presenciais especiais

Promessa:

> Faça parte do núcleo da banda.

---

# 4. Progressão dos planos

A progressão conceitual é:

```text
Fan
  ↓
acompanha

Supporter
  ↓
sustenta e participa

Core Member
  ↓
pertence ao núcleo
```

Essa progressão deve aparecer na experiência do usuário.

Entretanto, não duplicar funcionalidades entre planos.

Um Core Member deve herdar os benefícios dos níveis anteriores através da hierarquia de benefícios.

Evitar implementações como:

```ruby
if fan?
elsif supporter?
elsif core_member?
```

espalhadas pela aplicação.

Preferir uma regra centralizada de benefícios/permissões.

---

# 5. Benefits

Criar uma estrutura que permita representar benefícios de membership.

Exemplo conceitual:

```text
Fan
├── exclusive_feed
├── early_news
├── behind_the_scenes
├── alternative_versions
└── subscriber_community

Supporter
├── early_releases
├── complete_demos
├── production_journal
├── exclusive_live
├── digital_credits
├── merch_discount
└── early_sales

Core Member
├── private_lives
├── q_and_a
├── rare_archives
├── priority_tickets
├── higher_discount
├── permanent_credits
├── signed_item_giveaways
├── direct_messages
├── community_votes
└── special_meetings
```

Os benefícios de níveis inferiores devem ser herdados.

Exemplo:

```text
Core Member
    ↓
Supporter benefits
    ↓
Fan benefits
```

Não duplicar registros desnecessariamente.

---

# 6. Band Admin

Não criar um painel administrativo diferente para cada membership.

Criar:

```text
Band Admin
```

A banda administra sua própria comunidade, conteúdo, memberships e benefícios.

A banda nunca deve conseguir administrar dados de outra banda.

---

# 7. Band Admin Navigation

A navegação conceitual deve ser:

```text
Dashboard

Band
├── Profile
├── Members
└── Settings

Content
├── Posts
├── Photos
├── Videos
├── Audio
├── Archives
└── Drafts

Releases
├── Releases
├── Early Access
└── Credits

Community
├── Feed
├── Discussions
├── Polls
└── Moderation

Members
├── All Members
├── Fans
├── Supporters
└── Core Members

Engagement
├── Messages
├── Q&A
├── Sessions
└── Votes

Commerce
├── Merch
├── Tickets
├── Discounts
└── Early Access

Membership
├── Plans
├── Benefits
├── Subscriptions
└── Credits

Analytics
├── Members
├── Revenue
├── Engagement
└── Content

Settings
```

Não implementar todas as telas automaticamente se elas ainda não forem necessárias para o MVP.

Primeiro verificar o ROADMAP e o estado atual do projeto.

---

# 8. Band Admin — Dashboard

O Dashboard deve permitir que a banda compreenda rapidamente sua comunidade.

Informações possíveis:

- quantidade de Fans;
- quantidade de Supporters;
- quantidade de Core Members;
- receita recorrente;
- novos membros;
- atividade recente;
- visualizações;
- comentários;
- participação em enquetes.

Exemplo conceitual:

```text
1,248 Fans
184 Supporters
37 Core Members

R$ 12.480 / mês

+42 membros este mês
```

Não inventar métricas adicionais sem necessidade.

---

# 9. Content Management

A banda deve conseguir criar conteúdo.

Tipos iniciais:

- texto;
- foto;
- vídeo;
- áudio;
- enquete.

Cada conteúdo deve possuir uma política de visibilidade.

Exemplo:

```text
Visibility:

Public
Fan
Supporter
Core Member
```

O acesso deve ser determinado pelo membership do usuário naquela banda.

---

# 10. Exclusive Feed

O Band Admin deve permitir que a banda publique conteúdo exclusivo.

Exemplo:

```text
New Post

Title:
Behind the new record

Content:
...

Visibility:
Fan
```

Ou:

```text
Visibility:
Supporter
```

Ou:

```text
Visibility:
Core Member
```

A banda deve conseguir controlar a audiência do conteúdo.

---

# 11. Polls

A banda deve poder criar enquetes.

Exemplo:

```text
Question:

Which song should we play live?

Options:

Song A
Song B
Song C

Audience:

Core Members
```

A banda deve poder definir:

- audiência;
- opções;
- duração;
- quando os resultados aparecem.

As votações do Core Member são **decisões previamente escolhidas pela banda**.

Não implementar um sistema no qual Core Members possam votar arbitrariamente em qualquer aspecto da banda.

A banda decide quais decisões podem ser submetidas à votação.

---

# 12. Releases

Supporters e Core Members podem receber lançamentos antecipadamente.

O sistema deve suportar janelas de acesso.

Exemplo:

```text
Core Member
10/10

Supporter
15/10

Public
20/10
```

A implementação deve evitar duplicação do arquivo ou conteúdo.

Preferir um único release com regras de disponibilidade.

---

# 13. Composition Journal

Supporters e Core Members podem receber acesso ao processo criativo.

A banda deve poder criar:

```text
Composition Journal Entry

Title:
How this song was created

Content:
...

Attachments:
demo.wav
guitar.mp3
lyrics.pdf

Visibility:
Supporter
```

Não criar um CMS complexo sem necessidade.

---

# 14. Exclusive Lives

Supporters podem ter acesso a lives exclusivas.

Core Members também podem participar de lives privadas.

A banda deve poder:

- criar uma transmissão;
- definir data;
- definir horário;
- definir audiência;
- publicar descrição;
- controlar replay quando aplicável.

Exemplo:

```text
Listening Session

Date:
20/10/2026

Audience:
Supporter + Core Member
```

---

# 15. Core Sessions

Core Members possuem acesso a encontros especiais.

Tipos possíveis:

```text
Video
Audio
Q&A
Listening Party
Meet & Greet
```

A banda pode definir:

- data;
- horário;
- tipo;
- participantes;
- limite de vagas;
- descrição.

Exemplo:

```text
Private Listening Session

20 seats

18 confirmed
2 available
```

Não implementar um sistema completo de eventos/tickets se isso não fizer parte do escopo atual.

---

# 16. Direct Messages

Core Members podem enviar mensagens diretamente para a banda.

O Band Admin deve possuir uma caixa de entrada.

Exemplo:

```text
Messages

Carlos
"Quando vocês pretendem lançar..."

Ana
"Tenho uma sugestão..."

Pedro
"Gostaria de perguntar..."
```

A banda deve poder:

- visualizar;
- responder;
- arquivar;
- bloquear;
- moderar.

Importante:

O benefício significa que o Core Member pode enviar mensagem diretamente à banda.

Não significa que a banda é obrigada a responder imediatamente ou individualmente.

Considerar limites e mecanismos anti-abuso antes da implementação.

Não criar um sistema de chat complexo sem necessidade.

---

# 17. Credits

Supporters podem aparecer em créditos digitais.

Core Members podem aparecer também em:

- página permanente de apoiadores;
- encartes;
- lançamentos selecionados.

O sistema deve permitir que a banda controle onde os nomes aparecem.

Não assumir que todo lançamento deve necessariamente exibir todos os membros.

---

# 18. Merchandising

Supporters possuem desconto.

Core Members possuem desconto maior.

O Band Admin deve permitir configurar regras de desconto.

Exemplo:

```text
Fan
0%

Supporter
10%

Core Member
20%
```

Os valores devem ser configuráveis.

Não hardcodar percentuais se a arquitetura atual permitir configuração.

---

# 19. Early Access

A banda deve poder configurar acesso antecipado.

Exemplo:

```text
Limited Vinyl

Core Member
24 hours early

Supporter
12 hours early

Fan
Public release
```

O acesso antecipado deve ser tratado como regra de membership, não como cópias diferentes do produto.

---

# 20. Tickets

Quando existir integração com ingressos, Supporters podem receber acesso antecipado e Core Members podem receber prioridade.

Não implementar um sistema completo de ticketing apenas para satisfazer essa regra se ele ainda não existir.

Criar a integração quando houver infraestrutura correspondente.

---

# 21. Core Member Giveaways

Core Members podem participar de sorteios de itens autografados.

A funcionalidade deve ser tratada como benefício exclusivo.

Antes de implementar sorteios reais, verificar:

- requisitos legais;
- regras da plataforma;
- necessidade de integração;
- regras de elegibilidade.

Não inventar regras jurídicas.

---

# 22. Band Members

A banda deve possuir uma visão de seus membros.

Categorias:

```text
All
Fan
Supporter
Core Member
```

Informações relevantes:

- usuário;
- membership;
- status;
- data de entrada;
- benefícios;
- atividade quando disponível.

A banda não deve ter acesso a dados pessoais desnecessários.

Aplicar princípio de menor privilégio.

---

# 23. SceneCore Administrator

O Administrator é diferente do Band Admin.

O Administrator opera a plataforma inteira.

Conceitualmente:

```text
SceneCore Administrator

├── Bands
├── Users
├── Memberships
├── Payments
├── Content
├── Reports
├── Moderation
├── Analytics
├── Platform Settings
└── Audit
```

O Administrator pode administrar recursos globais da plataforma.

---

# 24. Administrator — Bands

O Administrator deve poder:

- visualizar bandas;
- visualizar status;
- administrar contas quando autorizado;
- suspender contas quando necessário;
- consultar informações operacionais.

O Administrator não deve assumir o papel de membro da banda.

---

# 25. Administrator — Users

O Administrator pode:

- localizar usuários;
- visualizar status;
- consultar memberships;
- lidar com denúncias;
- aplicar ações administrativas quando necessário.

Não expor dados pessoais além do necessário.

---

# 26. Administrator — Payments

O Administrator deve possuir visão operacional de:

- memberships;
- pagamentos;
- assinaturas;
- cancelamentos;
- reembolsos;
- status de transações.

Não armazenar dados sensíveis de cartão diretamente.

Utilizar o gateway de pagamento definido pelo projeto.

Se houver integração existente, reutilizá-la.

---

# 27. Administrator — Moderation

O Administrator deve possuir ferramentas para:

- denúncias;
- conteúdo reportado;
- usuários reportados;
- bandas reportadas;
- ações de moderação;
- histórico de ações.

A moderação deve ser separada da moderação cotidiana feita pela banda.

---

# 28. Permissions

A autorização deve respeitar três níveis:

```text
User
 ↓
Membership
 ↓
Band Admin
 ↓
SceneCore Administrator
```

Exemplo:

```text
Fan
→ pode acessar conteúdo Fan

Supporter
→ pode acessar conteúdo Fan + Supporter

Core Member
→ pode acessar conteúdo Fan + Supporter + Core

Band Admin
→ administra sua própria banda

SceneCore Administrator
→ administra a plataforma
```

Nunca permitir que o membership do usuário conceda privilégios administrativos.

Membership e role são conceitos diferentes.

---

# 29. Membership ≠ Role

Não misturar:

```text
Fan
Supporter
Core Member
```

com:

```text
Band Admin
SceneCore Administrator
```

Membership representa:

> relacionamento do usuário com uma banda.

Role representa:

> autoridade administrativa no sistema.

Exemplo:

```text
User A
membership: Core Member
role: user

User B
membership: Supporter
role: band_admin

User C
membership: Fan
role: platform_admin
```

Os papéis devem ser avaliados separadamente.

---

# 30. Multi-band

O sistema deve considerar que uma pessoa pode acompanhar várias bandas.

Portanto:

```text
User
  │
  ├── Membership → Band A → Fan
  ├── Membership → Band B → Supporter
  └── Membership → Band C → Core
```

Não criar:

```text
user.membership_plan
```

como regra global, caso isso impeça memberships independentes por banda.

O membership deve pertencer ao contexto da banda.

---

# 31. Security

Toda ação administrativa deve validar:

```text
current_user
+
role
+
band ownership / association
```

Exemplo:

```text
Band Admin A
```

não pode editar:

```text
Band B
```

mesmo que conheça o ID da banda.

Nunca confiar apenas em parâmetros enviados pelo browser.

---

# 32. Controllers

Controllers devem permanecer finos.

Não colocar regras como:

```ruby
if current_user.core_member?
```

espalhadas pelos controllers.

Preferir:

- policies;
- models;
- scopes;
- services quando houver fluxo realmente complexo.

Exemplo conceitual:

```ruby
MembershipPolicy
ContentPolicy
BandPolicy
```

A implementação concreta deve seguir os padrões já existentes no projeto.

---

# 33. Models

Antes de criar novos models, analisar os existentes.

Estrutura conceitual possível:

```text
User
Band
Membership
MembershipPlan
Benefit
Content
Poll
Vote
Release
Credit
Subscription
```

Essa lista é conceitual.

**Não criar todos esses models automaticamente.**

Determinar quais são realmente necessários após analisar o código existente e o MVP.

---

# 34. Subscription

A assinatura financeira deve ser separada do conceito de membership quando necessário.

Conceitualmente:

```text
User
   ↓
Subscription
   ↓
Membership
   ↓
Band
```

A implementação concreta deve respeitar o gateway de pagamento utilizado pelo projeto.

Status possíveis devem ser definidos com base no gateway existente.

Não inventar estados financeiros.

---

# 35. Content Access

O acesso ao conteúdo deve ser derivado do membership.

Exemplo:

```text
content.required_plan = supporter
```

Então:

```text
Fan
→ deny

Supporter
→ allow

Core Member
→ allow
```

Para conteúdo Core:

```text
Fan
→ deny

Supporter
→ deny

Core Member
→ allow
```

Para conteúdo público:

```text
qualquer usuário
→ allow
```

---

# 36. Hierarquia de acesso

A regra conceitual é:

```text
Public
   ↓
Fan
   ↓
Supporter
   ↓
Core Member
```

Onde:

```text
Core Member >= Supporter >= Fan
```

Não implementar regras independentes para cada recurso se uma hierarquia resolver o problema.

---

# 37. UX

A interface deve comunicar claramente:

```text
Fan
Fique mais perto da banda.

Supporter
Apoie a música e acompanhe sua criação.

Core Member
Faça parte do núcleo da banda.
```

Quando um usuário encontrar conteúdo bloqueado, explicar qual membership é necessário.

Exemplo:

```text
This content is available to Supporters and Core Members.

Upgrade to Supporter
```

Não esconder silenciosamente a existência do conteúdo.

---

# 38. Upgrade

O usuário deve poder compreender a progressão:

```text
Fan
R$ 10
     ↓
Supporter
R$ 25
     ↓
Core Member
R$ 50
```

Ao fazer upgrade, o usuário deve receber automaticamente os benefícios correspondentes ao novo membership.

Evitar duplicação de memberships incompatíveis.

A regra exata de upgrade/downgrade deve respeitar o sistema de pagamentos existente.

---

# 39. Downgrade / Cancellation

A assinatura pode ser:

```text
Active
Canceled
Expired
Pending
```

Somente utilizar estados realmente suportados pelo sistema de pagamentos.

Quando uma assinatura deixa de dar direito ao membership, o acesso aos benefícios deve ser atualizado de acordo com o estado efetivo da assinatura.

Não conceder acesso permanente baseado apenas no histórico de pagamento.

---

# 40. Analytics

O Band Admin poderá futuramente acompanhar:

```text
Memberships
Revenue
Engagement
Content
```

Exemplos:

- crescimento de membros;
- distribuição por plano;
- receita;
- visualizações;
- participação;
- atividade.

Não criar um sistema de analytics complexo no início.

Implementar somente métricas necessárias ao MVP.

---

# 41. MVP

Priorizar a implementação nesta ordem:

## Phase 1 — Membership foundation

- Membership plans
- Membership per band
- Membership status
- Access hierarchy
- Benefits
- Authorization

## Phase 2 — Band Admin

- Band dashboard
- Member list
- Membership management
- Basic content management

## Phase 3 — Exclusive Content

- Fan content
- Supporter content
- Core content
- Access control

## Phase 4 — Community

- Feed
- Comments
- Polls
- Moderation

## Phase 5 — Supporter Features

- Early releases
- Demos
- Composition journal
- Exclusive content
- Credits

## Phase 6 — Core Features

- Private sessions
- Q&A
- Direct messages
- Core votes
- Special meetings
- Permanent credits

## Phase 7 — Commerce

- Merch discounts
- Ticket benefits
- Early sales
- Priority access

## Phase 8 — Platform Administration

- Users
- Bands
- Memberships
- Payments
- Reports
- Moderation
- Platform analytics

---

# 42. Implementation Strategy

Para cada fase:

1. Analise o código existente.
2. Identifique models relacionados.
3. Identifique controllers.
4. Identifique policies.
5. Identifique rotas.
6. Identifique testes existentes.
7. Proponha alterações.
8. Aguarde confirmação quando houver alteração arquitetural relevante.
9. Implemente em pequenos passos.
10. Execute os testes.
11. Execute lint/formatters existentes.
12. Verifique regressões.
13. Atualize documentação.
14. Só então avance para a próxima fase.

Não implementar todas as fases em uma única alteração.

---

# 43. Test Strategy

Cada regra importante deve possuir testes.

Testar principalmente:

### Membership

```text
Fan
Supporter
Core Member
```

### Access

```text
Public content
Fan content
Supporter content
Core content
```

### Authorization

```text
Regular User
Band Admin
SceneCore Administrator
```

### Multi-band

Verificar que:

```text
User → Band A → Fan
```

não concede acesso a:

```text
Band B → Supporter content
```

### Security

Verificar que um Band Admin não consegue administrar outra banda.

### Payments

Testar transições de membership conforme a integração de pagamento existente.

Usar Minitest caso seja o framework já adotado pelo projeto.

---

# 44. Não fazer

Claude não deve:

- criar três dashboards administrativos;
- transformar Fan/Supporter/Core em roles administrativas;
- permitir que Core Members administrem a banda;
- permitir que fãs votem em decisões não configuradas pela banda;
- criar funcionalidades não especificadas;
- criar um chat complexo sem necessidade;
- criar um CMS complexo;
- criar um sistema de ticketing sem necessidade;
- criar analytics avançado antes da necessidade;
- duplicar conteúdo para cada plano;
- espalhar verificações de membership pelos controllers;
- armazenar dados de cartão;
- assumir que membership é global ao usuário;
- permitir acesso administrativo baseado no plano;
- criar abstrações antes de existir duplicação real.

---

# 45. Princípio arquitetural central

O SceneCore deve manter esta separação:

```text
                ┌─────────────────────┐
                │       USER          │
                └──────────┬──────────┘
                           │
                           ▼
                ┌─────────────────────┐
                │     MEMBERSHIP      │
                │                     │
                │ Fan                 │
                │ Supporter           │
                │ Core Member         │
                └──────────┬──────────┘
                           │
                           ▼
                ┌─────────────────────┐
                │      BENEFITS       │
                └──────────┬──────────┘
                           │
                           ▼
                ┌─────────────────────┐
                │      CONTENT        │
                │      COMMUNITY      │
                │      COMMERCE       │
                └─────────────────────┘


                ┌─────────────────────┐
                │      BAND ADMIN     │
                └──────────┬──────────┘
                           │
                           ▼
                administra UMA banda


                ┌─────────────────────┐
                │ SCENECORE ADMIN     │
                └──────────┬──────────┘
                           │
                           ▼
                administra A PLATAFORMA
```

A regra fundamental é:

> **Membership determina acesso e benefícios. Role determina autoridade administrativa.**

Essa separação deve ser preservada em models, policies, controllers, views, services, rotas e testes.