# MyoTrack

Personal trainer e nutricionista digital: gera treino e dieta a partir do seu perfil,
acompanha a execução e comenta a semana.

Port do sistema .NET/React (repositório `MyoTrack`) para **Flutter** no app e **Java 21 +
Spring Boot** no servidor. O banco é o mesmo — as migrations do Flyway adotam o schema criado
pelo EF Core no ponto `V1`, sem recriar nada.

## O que é cada parte

| Pasta | O que é |
|---|---|
| `app/` | O aplicativo, em Flutter. Android e iOS. |
| `backend/myotrack-api/` | A API HTTP. É a única que aplica migrations. |
| `backend/myotrack-worker/` | Processa a fila de jobs: análise de foto, de vídeo, coach, relatório semanal. |
| `backend/myotrack-domain/` | Regras que não dependem de banco nem de framework. É onde ficam os cálculos. |
| `backend/myotrack-infrastructure/` | Banco, armazenamento de mídia, acesso a LLM. |

**A chave do LLM só existe no Worker.** A API é o processo exposto à internet e nunca a vê.
Se você configurar a chave no lugar errado, a geração continua funcionando — pelo motor de
regras, sem IA — e nada avisa.

## Subir o ambiente

Precisa de: Docker, JDK 21 e o SDK do Flutter.

```bash
docker compose up -d          # Postgres na 5433 e MinIO na 9000
cd backend && ./gradlew :myotrack-api:bootRun
```

Só isso. A API cria o schema na primeira subida e responde em `http://localhost:8080`; o
bucket de mídia é criado na primeira escrita. Os padrões do compose são os mesmos de
`myotrack-shared.yml`, então nada precisa ser configurado para desenvolver.

Confira com:

```bash
curl http://localhost:8080/actuator/health     # {"status":"UP",...}
```

O Worker sobe à parte, quando você for mexer em algo que dependa dele:

```bash
cd backend && ./gradlew :myotrack-worker:bootRun
```

O app aponta para `http://10.0.2.2:8080` no emulador Android (é como o emulador enxerga o
`localhost` da máquina). Veja `app/lib/core/env.dart`.

```bash
cd app && flutter run
```

### A API e o Worker não estão no compose

De propósito. Eles rodam por `bootRun`, com recompilação a cada mudança — é assim que se
desenvolve aqui. Containerizá-los passa a valer no dia em que houver deploy, e um Dockerfile
que ninguém executa apodrece sem avisar.

### O serviço de visão fica em outro repositório

A análise de execução por vídeo depende de um serviço Python (FastAPI + MediaPipe Pose) que
vive no repositório `MyoTrack`, em `vision/`. O Worker o procura em `http://localhost:8000`
(`MYOTRACK_VISION_BASE_URL`).

Sem ele de pé, os jobs de vídeo falham; o resto do sistema funciona normalmente.

## Configuração

Tudo tem padrão de desenvolvimento e nada é obrigatório para rodar local. As variáveis que
importam:

| Variável | Onde | Sem ela |
|---|---|---|
| `MYOTRACK_GEMINI_API_KEY` ou `MYOTRACK_OPENAI_API_KEY` | Worker | Treino e dieta saem só do motor de regras; sem narrativa nem análise de foto. |
| `MYOTRACK_VISION_BASE_URL` | Worker | Análise de vídeo falha. |
| `MYOTRACK_JWT_SIGNING_KEY` | API | Usa a chave de desenvolvimento — **troque em produção**. |
| `MYOTRACK_PUBLIC_BASE_URL` | API | Base dos links enviados por e-mail. |
| `MYOTRACK_EMAIL_USER` / `_PASSWORD` | API | O e-mail não é enviado, só registrado no log. |
| `MYOTRACK_STRIPE_SECRET_KEY` | API | Pagamento desligado; todos no plano gratuito. |
| `MYOTRACK_FCM_PROJECT_ID` **e** `MYOTRACK_FCM_CREDENTIALS_JSON` | Worker | As notificações são escritas no log do Worker e não vão para os aparelhos. Precisa das duas: metade configurada mantém o modo log. |

A lista completa está em `application.yml` de cada módulo — cada entrada diz o que acontece
quando fica vazia.

## Verificar

```bash
cd backend && ./gradlew build          # compila e roda os testes do servidor
cd app && flutter analyze --fatal-infos && flutter test
```

O CI (`.github/workflows/ci.yml`) roda isso mais os builds de Android e iOS a cada push. **Ele
pega coisas que não aparecem no Windows** — o bit de execução do `gradlew` e a versão mínima
do iOS já quebraram lá depois de passarem aqui.

## Notificações

O Worker avisa o aparelho quando um job termina. O que dispara aviso é curto e por inclusão —
**avisa-se quem não está olhando**: relatório semanal pronto (nasce de um agendador, sem ninguém
pedir), análise de vídeo (leva minutos) e as gerações de treino e dieta. Foto de refeição e
resposta do coach não avisam: são rápidas e a pessoa está na tela esperando. A regra vive em
`JobCompletionNotifier`.

O caminho inteiro já funciona — o job conclui, os tokens do usuário são consultados, a mensagem é
montada com a rota de destino — e **a última etapa escreve no log em vez de enviar**, enquanto não
houver `MYOTRACK_FCM_*`. É assim que se confere texto e rota sem aparelho e sem credencial, do
mesmo jeito que o link de redefinição de senha aparece no log da API quando não há SMTP.

O app registra o token a cada abertura, não uma vez no primeiro login: o FCM o rotaciona por conta
própria (reinstalação, restauração de backup, limpeza de dados) e não avisa ninguém. `POST
/api/devices` é idempotente por isso. E o token pertence ao **aparelho**, não à pessoa: quem sai da
conta e entra com outra no mesmo aparelho mantém o token, então o registro reatribui a linha em vez
de inserir outra — sem isso o aparelho passaria a receber as notificações das duas contas.

### Falta para as notificações saírem de fato

Duas coisas, e as duas são de fora do código:

1. **Um projeto no Firebase**, para gerar a conta de serviço (`MYOTRACK_FCM_*`) e o
   `google-services.json` do app. É grátis.
2. **Uma chave APNs**, para o iOS, carregada no console do Firebase. Exige conta paga da Apple —
   o mesmo bloqueio da verificação de domínio.

Enquanto não existirem, `firebase_messaging` **não entra no `pubspec.yaml`**: sem o
`google-services.json` o plugin do Google falha o build do Android, e é a política de dependências
declarada lá — cada pacote entra na funcionalidade que o usa, não antes. O que falta no app é uma
implementação de `PushTokenSource` (`app/lib/core/notifications/push_registration.dart`); o resto do
fluxo está de pé e testado contra uma fonte falsa.

## Custo de IA

Dois provedores: **Gemini e OpenAI**. A Anthropic saiu — o cliente e o SDK dela foram removidos.
A troca não encostou em nenhum handler: eles injetam `LlmJsonClient`, e a interface não mudou.

`MYOTRACK_LLM_PROVIDER` escolhe; vazio autodetecta pela chave preenchida, com **precedência do
Gemini** quando as duas existem. A regra é de custo, não de qualidade: com as duas configuradas, o
padrão silencioso deve ser o lado mais barato por token.

Nenhum dos dois usa SDK — os dois são REST direto, como o Gemini já era. O corpo de uma requisição
de structured output é pequeno e estável, e a saída da Anthropic (o único que usava SDK) deixou a
lição de que um SDK a mais é uma dependência a mais para versionar quando o fornecedor muda.

### O que o modo estrito da OpenAI exige

`OpenAiJsonClient.strictSchema` é o espelho do `GeminiJsonClient.sanitizeSchema`: lá se **remove**
o que o Gemini recusa (`additionalProperties`, `$schema`), aqui se **acrescenta** o que a OpenAI
exige — `additionalProperties: false` e `required` listando **todas** as propriedades de todo
objeto.

Consequência que morde na primeira vez: **o modo estrito não tem campo opcional.** Um campo que
pode faltar precisa ser anulável no próprio tipo (`"type": ["string","null"]`); deixá-lo fora do
`required` não é opção que a API aceite, e a adaptação vai obrigá-lo de qualquer forma. Os schemas
atuais já listam tudo em `required`, então a mudança é invisível hoje — há teste fixando isso.

### Onde o dinheiro sai

Levantado do código, não de estimativa:

- **Análise de vídeo não custa token nenhum.** `ExerciseVideoHandler` chama o serviço de visão
  self-hosted, não o LLM. É o limite mais barato de ampliar no plano Pro.
- **A análise ilustrada é a chamada mais cara do app, por uma ordem de grandeza** — geração de
  imagem, cobrada por imagem e não por token de texto. O `MealImageAnnotator` produz a mesma
  anotação localmente, de graça, e é o que roda hoje (o modelo de imagem tem cota zero sem
  billing). Ligar billing ali é decisão de custo, não de configuração.
- **Um modelo para tudo é o desperdício estrutural.** `LlmClientConfiguration` registra um bean
  `@Primary` para o app inteiro: extrair itens de uma foto contra um schema fixo e gerar um plano
  de treino pagam a mesma tabela. Separar por operação é a mudança de maior efeito — e é troca de
  qualidade por preço, então não foi feita sem decisão de produto.
- **`AiUsageLog` já mede** — grava operação, modelo e tokens por chamada. É por onde começar antes
  de otimizar qualquer coisa. Com dois provedores a preços diferentes, vale acrescentar o provedor
  à tabela: contagem de token sozinha deixou de ser comparável entre linhas.
- **O relatório semanal é o único trabalho assíncrono de verdade** — nasce de um agendador, sem
  ninguém esperando. É o candidato certo para uma fila de batch (metade do preço nos dois
  provedores).

## Conquistas

Recompensa por evolução, em `app/lib/features/achievements/`. Doze conquistas em três
famílias — constância (aparecer), progressão (melhorar) e nutrição (sustentar) —, e cada uma
carrega o **progresso**, não só o selo: "3 de 4 treinos" diz o que fazer esta semana; um
cadeado não diz nada. A lista das que faltam vem ordenada pela proximidade, e a primeira
linha é, na prática, o conselho do momento.

**Elas são derivadas, não guardadas.** O estado sai dos mesmos agregados que o dashboard já
consome (`/api/progress/*` e `/api/diary`), calculados no servidor. Não há tabela de
conquistas em lugar nenhum, e isso é deliberado: guardar o resultado criaria uma segunda
verdade livre para divergir da primeira — um selo afirmando um treino que foi apagado. O
preço, dito na própria tela, é que apagar sessões no servidor pode destrancar para trás.

O que o aparelho guarda é só **o que já foi comemorado** (`SeenAchievements`, v2 do banco
local). O servidor não tem como saber se a pessoa já foi avisada, e quem instala num celular
novo não deveria receber de novo a comemoração de um recorde de três meses atrás.

A comemoração é a própria tela: o hub mostra um cartão quando há novidade, abrir a lista
marca como visto, e o cartão some. Sem diálogo por cima de outra tarefa — quem abriu o app no
vestiário para ver quanto pode comer não pediu confete no caminho.

A regra é uma função pura (`evaluateAchievements`) justamente porque decide se alguém ganhou
algo: ela erra de dois jeitos, e premiar o que não aconteceu é o pior dos dois — um selo
falso põe em dúvida todos os verdadeiros.

### O prêmio: Pro por prazo

Duas marcas de constância rendem plano Pro de verdade — **quatro semanas seguidas dão 7 dias,
doze semanas dão 30**. Enquanto vale, os limites diários de IA sobem de 10/5/10 para 50/20/50.

Isso muda quem calcula. **A sequência de semanas saiu do app e foi para o domínio do backend**
(`TrainingStreak`, ao lado de `TrainingWeek`, que existe pelo mesmo motivo: uma definição só).
Enquanto ela só pintava um selo, contá-la em Dart era barato; desde que concede plano pago,
quem conta precisa ser quem paga — um cliente que afirma "tenho doze semanas" é um cliente que
qualquer pessoa reescreve com um proxy. O app exibe o número que `GET /api/rewards` devolveu, e
**não existe endpoint de reivindicação**: o servidor reconta a partir das sessões que guardou e
concede o que for devido.

As outras dez conquistas continuam derivadas no cliente. Um selo forjado não custa nada a
ninguém; um mês de Pro, sim.

A concessão vive em `ProGrants`, tabela separada de `UserSubscriptions`. Aquela é o cache do
que a loja diz e o webhook a reescreve: uma cortesia gravada lá seria apagada na primeira
notificação e apareceria como receita que nunca existiu. `EntitlementService` considera Pro
quem tem assinatura ativa **ou** concessão dentro do prazo, e devolve `isGranted` para a tela
saber a diferença.

Uma concessão por marca, para sempre — o índice único em `(UserId, Milestone)`. Doze semanas
seguidas continuam verdadeiras por meses; sem a trava, cada abertura do app renderia mais um
mês. Quem perde a sequência e a reconquista não ganha de novo, e isso evita o ciclo de quem
quisesse farmar o prêmio.

**Só constância de treino tem prêmio material.** Aderência à dieta ficou de fora de propósito:
a régua da nutrição é o consumo que o próprio usuário declara, e pendurar valor econômico nela
cria o incentivo que um produto de saúde não pode criar — registrar refeição que não houve, ou
restringir para bater a faixa. Nutrição continua rendendo reconhecimento.

### O que falta de dado

O diário devolve só as calorias dos sete últimos dias (`DiaryDay.week`), então as conquistas
de nutrição param aí: não há histórico de proteína nem de dias anteriores à semana corrente.
"Semana de proteína batida" — que é o macro que a pessoa mais erra por falta — depende de o
`GET /api/diary` trazer os macros da semana, e não só o total calórico.

## Falta para produção

- **O fechamento do dia não chega inteiro ao servidor.** A tela "Fechar o dia" faz três
  perguntas; só a pesagem tem destino (`POST /api/measurements`). Esforço e energia ficam na
  memória do app porque não existe endpoint de check-in — e é por isso que o resumo mostra o
  que o plano já diz sobre amanhã em vez de prometer um ajuste. Quando houver `POST
  /api/check-ins`, o lugar de mandar as respostas é o `DayCloseController`, pela `SyncQueue`,
  como todas as outras escritas.
- **Os deep links `https://` não abrem o app em aparelho real.** Falta hospedar o
  `assetlinks.json` (Android) e o `apple-app-site-association` (iOS) em `myotrack.app`. O
  esquema `myotrack://` já funciona; o link que o backend manda por e-mail, não.
- **Não há build de release nem assinatura.** Falta keystore no Android e certificado com
  perfil no iOS.
- **As notificações não saem do log.** Ver acima.
- **A migração `V5__pro_grants.sql` ainda não foi aplicada contra um Postgres.** O build e os
  testes passam, mas a DDL só roda de fato na primeira subida da API com o banco de pé:
  `docker compose up -d postgres && cd backend && ./gradlew :myotrack-api:bootRun`.
