# O que falta configurar

Levantamento de tudo que o MyoTrack precisa **de fora do código** para funcionar por inteiro:
contas, credenciais, arquivos de configuração e certificados. Gerado por varredura do
repositório em 29/07/2026, no commit `d58ec08`.

O sistema roda inteiro em desenvolvimento sem nada disto — cada integração tem um padrão e
degrada de forma documentada. O problema é que **quase toda degradação é silenciosa**: a
funcionalidade some ou muda de comportamento sem erro nenhum. Esta é a lista do que é preciso ter
em mãos para que ela deixe de degradar.

---

## Leia primeiro: o único item que é urgente mesmo sem publicar nada

**`MYOTRACK_JWT_SIGNING_KEY`.** Sem ela a API assina os tokens de sessão com
`dev-only-signing-key-change-me-in-production-0123456789`, que está em texto puro no
`application.yml` e portanto neste repositório. Não falha, não avisa, e o sistema funciona
perfeitamente — qualquer pessoa com acesso ao repositório consegue forjar a sessão de qualquer
usuário. É a única entrada desta lista cujo padrão de desenvolvimento é *perigoso* em vez de
apenas limitado.

Qualquer string longa e aleatória serve (HMAC-SHA256):

```bash
openssl rand -base64 48
```

---

## 1. Contas a abrir (é o que destrava o resto)

| Conta | Custo | O que destrava |
|---|---|---|
| **Apple Developer Program** | US$ 99/ano | Sign in with Apple, Universal Links, push no iOS, assinatura de release iOS, publicação na App Store |
| **Google Play Console** | US$ 25, uma vez | Deep links verificados no Android, distribuição, validação de assinatura via Play |
| **Firebase** | grátis | Notificações push (Android e iOS) |
| **Google Cloud** | grátis | Login com Google |

A conta da Apple é o gargalo: **quatro** funcionalidades diferentes dependem só dela. As outras
três são baratas ou grátis e podem ser feitas hoje.

---

## 2. Notificações push

Estado: o caminho inteiro funciona e está testado; a última etapa escreve no log em vez de enviar.
Falta credencial, e no app falta uma classe que dependa dela.

### O que pegar

1. **Projeto no Firebase** (grátis) em <https://console.firebase.google.com>. Adicione um app
   Android (`com.myotrack.app`) e um iOS (`com.myotrack.app`).
2. **Conta de serviço**: Configurações do projeto > Contas de serviço > Gerar nova chave privada.
   Baixa um JSON.
3. **Chave APNs** (só para iOS): portal da Apple > Keys > nova chave com APNs habilitado. Carregue
   no Firebase em Configurações > Cloud Messaging. **Exige a conta paga.**

### Onde colocar

| Onde | O quê |
|---|---|
| `MYOTRACK_FCM_PROJECT_ID` (Worker) | O id do projeto no Firebase |
| `MYOTRACK_FCM_CREDENTIALS_JSON` (Worker) | O **conteúdo** do JSON da conta de serviço, não o caminho |
| `app/android/app/google-services.json` | Baixado do console |
| `app/ios/Runner/GoogleService-Info.plist` | Baixado do console |

**As duas variáveis são necessárias.** Configurar só uma mantém o modo log — de propósito: o id
sem credencial não autentica, e a credencial sem o id não sabe para onde enviar. Sem essa checagem
o sintoma seria um 401 do Google no log do Worker, longe da causa.

### O que ainda falta de código (depende da credencial existir)

- **Backend:** uma classe implementando `PushSender` que fale com o FCM. O ponto de entrada já
  está marcado em `PushConfiguration.pushSender()`.
- **App:** uma implementação de `PushTokenSource`
  (`app/lib/core/notifications/push_registration.dart`) e a entrada de `firebase_messaging` no
  `pubspec.yaml`. Ela foi deixada de fora *deliberadamente*: sem o `google-services.json` o plugin
  do Google falha o build do Android, e a política de dependências declarada no `pubspec.yaml` diz
  que cada pacote entra na funcionalidade que o usa, não antes.

O resto — registro de token, reatribuição entre contas, política de quais jobs avisam, limpeza de
token morto, purge no LGPD — já está pronto e testado.

---

## 3. Login social

### Google

| Onde pegar | Google Cloud Console > APIs e Serviços > Credenciais |
|---|---|
| Precisa de | Um OAuth client **do tipo Web** e um **do tipo Android** |

| Variável | Onde | Sem ela |
|---|---|---|
| `MYOTRACK_GOOGLE_CLIENT_ID` | API | O botão "Continuar com Google" não aparece |
| `MYOTRACK_GOOGLE_CLIENT_SECRET` | API | Idem — o fluxo web exige as duas |
| `MYOTRACK_GOOGLE_ANDROID_CLIENT_IDS` | API | O login nativo do Android é recusado na validação |
| `MYOTRACK_GOOGLE_SERVER_CLIENT_ID` | App, via `--dart-define` | **É o erro mais comum.** Ver abaixo |

**A pegadinha:** o `MYOTRACK_GOOGLE_SERVER_CLIENT_ID` do app tem de ser o client id **do tipo
Web**, não o do tipo Android. Sem ele o Google devolve apenas um *access token*, e o backend recusa
o login porque `/api/auth/google/id-token` valida um **ID token** — que só é emitido quando o app
declara para qual servidor se destina. Falha de um jeito que não parece configuração.

O redirect autorizado no Google Cloud deve ser `MYOTRACK_PUBLIC_BASE_URL` +
`/api/auth/google/callback`.

O client Android precisa da impressão digital SHA-1 do certificado de assinatura — a de debug para
testar, a do Play App Signing para produção.

### Apple

| Variável | Onde | Sem ela |
|---|---|---|
| `MYOTRACK_APPLE_AUDIENCES` | API | O botão da Apple não aparece |

O valor é o bundle id: `com.myotrack.app`. Não há client secret — o app manda um token já assinado
pela Apple e o backend valida contra o JWKS público.

**Além da variável**, a capability *Sign in with Apple* precisa estar habilitada no identificador
do app no portal da Apple. O entitlement já está no repositório
(`app/ios/Runner/Runner.entitlements`), mas ele sozinho não basta para builds assinados — a chamada
falha em tempo de execução com um erro que não indica a causa.

> A App Store **exige** Sign in with Apple em qualquer app que ofereça login social de terceiros
> (diretriz 4.8). Como o app oferece Google, isto não é opcional para publicar no iOS.

---

## 4. Deep links (o link do e-mail abrir o app)

Estado: o esquema `myotrack://` já funciona. O link `https://myotrack.app/redefinir-senha?...` que
o backend manda por e-mail **abre o navegador**, não o app.

O código que serve os dois arquivos de verificação existe, mas **está no branch
`feat/verificacao-de-dominio`, ainda não mesclado em `main`**. O `AndroidManifest.xml` em `main` já
declara `autoVerify="true"` para `myotrack.app`, e o entitlement de associated domains do iOS
também já está lá — ou seja, os dois lados do app estão prontos e esperando o servidor.

| Variável | Onde achar o valor |
|---|---|
| `MYOTRACK_ANDROID_PACKAGE_NAME` | `com.myotrack.app` |
| `MYOTRACK_ANDROID_CERT_FINGERPRINTS` | Play Console > Setup > App signing |
| `MYOTRACK_APPLE_APP_ID` | `TEAMID.com.myotrack.app` — o Team ID está no portal da Apple, em Membership |

**A pegadinha do Android:** com Play App Signing, a impressão digital é a **SHA-256 do Google**,
não a do seu keystore de upload — o Google reassina o APK antes de distribuir. Trocar as duas é o
engano comum, e o sintoma é o link seguir abrindo o navegador sem erro nenhum.

**Ainda falta, fora do código:** o domínio precisa rotear `/.well-known/*` para a API. Hoje o Caddy
do repositório .NET manda tudo que não é `/api/*` para os estáticos do frontend. Os dois arquivos
têm de responder `200` com `Content-Type: application/json` e **sem redirecionamento** — as duas
plataformas recusam 301/302.

---

## 5. Pagamentos e assinaturas

Estado: **desligado**, e aqui falta mais código do que credencial.

### Stripe (web)

| Variável | Onde | Sem ela |
|---|---|---|
| `MYOTRACK_STRIPE_SECRET_KEY` | API | Pagamento desligado; todos no plano gratuito |
| `MYOTRACK_STRIPE_WEBHOOK_SECRET` | API | O webhook não valida assinatura |
| `MYOTRACK_STRIPE_PRO_PRICE_ID` | API | Não há o que vender no checkout |

### Lojas (App Store e Google Play) — falta implementação

`StoreReceiptVerifier` é uma interface **sem nenhuma implementação no repositório**. Os endpoints
`/api/billing/apple/verify` e `/api/billing/google/verify` respondem sempre
`503 — "Pagamentos ainda não estão disponíveis neste ambiente."`

Isto é importante porque **nenhuma credencial resolve sozinha**: é preciso escrever as duas
implementações. E é obrigatório para publicar:

> A App Store recusa app que venda conteúdo digital por fora do seu sistema de compra (diretriz
> 3.1.1), e o Google Play tem regra equivalente. Ou seja: o Stripe atende a web, mas **o app não
> pode vender assinatura por ele**.

Para quando for implementar, será necessário: chave da App Store Connect API (conta paga da Apple)
e uma conta de serviço do Google Play Developer API.

---

## 6. Infraestrutura de produção

| Variável | Onde | Sem ela |
|---|---|---|
| `MYOTRACK_JWT_SIGNING_KEY` | API | **Chave de desenvolvimento pública.** Ver o topo deste documento |
| `MYOTRACK_DB_URL` / `_USER` / `_PASSWORD` | Ambos | Aponta para o Postgres local do compose, com senha `dev-only-password` |
| `MYOTRACK_STORAGE_ENDPOINT` / `_ACCESS_KEY` / `_SECRET_KEY` / `_BUCKET` | Ambos | Aponta para o MinIO local, com credencial `dev-only-password` |
| `MYOTRACK_STORAGE_PUBLIC_ENDPOINT` | Ambos | As URLs pré-assinadas de mídia apontam para um endereço que o celular não alcança |
| `MYOTRACK_PUBLIC_BASE_URL` | API | Os links do e-mail apontam para `http://localhost:5173` |
| `MYOTRACK_CORS_ORIGINS` | API | Só `http://localhost:5173` é aceito |

O `MYOTRACK_STORAGE_PUBLIC_ENDPOINT` merece atenção: é o endereço que o **cliente** usa nas URLs
pré-assinadas. Em desenvolvimento é igual ao interno e por isso nunca aparece; em produção, se
ficar vazio, o app recebe URLs de mídia apontando para um host interno e as fotos simplesmente não
carregam.

---

## 7. E-mail

| Variável | Onde | Sem ela |
|---|---|---|
| `MYOTRACK_EMAIL_USER` | API | O e-mail não é enviado, só registrado no log da API |
| `MYOTRACK_EMAIL_PASSWORD` | API | Idem |
| `MYOTRACK_EMAIL_FROM` | API | Usa o próprio usuário SMTP como remetente |
| `MYOTRACK_EMAIL_HOST` / `_PORT` | API | `smtp.gmail.com` na 587 com STARTTLS |

O padrão aponta para o Gmail. Se for usá-lo, a senha precisa ser uma **senha de app** (exige 2FA
na conta) — a senha normal da conta é recusada.

Sem isto o fluxo de recuperação de senha continua funcionando para desenvolver: o link aparece no
log da API. Em produção, ele simplesmente não chega a ninguém.

O **export de dados do LGPD** também depende de SMTP — o arquivo vai anexado ao e-mail. Esta é uma
das poucas degradações desta lista que **não** é silenciosa: o endpoint recusa com `503` e mensagem
explícita em vez de responder "enviado", justamente porque é um direito do titular e não um aviso
qualquer.

---

## 8. Inteligência artificial

| Variável | Onde | Sem ela |
|---|---|---|
| `MYOTRACK_ANTHROPIC_API_KEY` ou `MYOTRACK_GEMINI_API_KEY` | **Worker** | Treino e dieta saem só do motor de regras, sem narrativa; sem análise de foto de refeição |
| `MYOTRACK_VISION_BASE_URL` | Worker | Análise de vídeo falha |

**A chave só existe no Worker.** A API é o processo exposto à internet e nunca a vê. Se configurar
no lugar errado, a geração continua funcionando — pelo motor de regras, sem IA — e **nada avisa**.

A análise de vídeo depende de um serviço Python (FastAPI + MediaPipe Pose) que vive **no outro
repositório**, em `vision/`. O Worker o procura em `http://localhost:8000`. Sem ele de pé, os jobs
de vídeo falham; o resto funciona.

A análise ilustrada de refeição usa um modelo de imagem do Gemini que exige **chave com billing
ativo**. Sem cota, cai no modo padrão silenciosamente.

---

## 9. Assinatura e publicação do app

### Android

Falta: **keystore de release**. Hoje `app/android/app/build.gradle.kts` assina o release com a
**chave de debug** (o `TODO` do template do Flutter, linha 34). Um APK assim não é aceito pela Play
Store.

```bash
keytool -genkey -v -keystore myotrack-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Depois: `android/key.properties` (fora do git) e o `signingConfig` de release apontando para ele.

### iOS

Falta: certificado de distribuição, perfil de provisionamento e **Team ID**. O projeto Xcode não
tem `DEVELOPMENT_TEAM` definido — hoje só compila sem assinatura, que é como o CI o valida
(`flutter build ios --no-codesign`).

Alvo mínimo já definido: iOS 14.

### Para as duas lojas, além do código

- **URL de política de privacidade** — obrigatória nas duas. O app já tem o registro de
  consentimento (`ConsentType.PRIVACY_POLICY`), mas o documento em si precisa existir e estar
  hospedado.
- **Formulário de privacidade de dados** (Data safety no Play, App Privacy na Apple). Este app
  processa **foto, vídeo e dados de saúde** — vídeo de execução é potencialmente biométrico, o que
  costuma exigir declaração mais detalhada. A política de retenção já está implementada (vídeo 30
  dias, foto 90), o que ajuda a responder.
- **Ícones do app** — são os do template do Flutter. Conferido byte a byte: as cinco densidades do
  Android (`mipmap-*/ic_launcher.png`) e o `Icon-App-1024x1024` do iOS são idênticos aos arquivos
  que o `flutter create` gera. Nenhuma das duas lojas aceita o ícone padrão.
- Aconselhamento de treino e dieta gerado por IA tende a atrair revisão mais cuidadosa nas duas
  lojas.

---

## Ordem que eu sugiro

1. **`MYOTRACK_JWT_SIGNING_KEY`** — é o único risco real de segurança, e leva um minuto.
2. **Firebase** (grátis) — destrava o push no Android inteiro, que é a maior lacuna de produto.
3. **Google Cloud** (grátis) — destrava o login com Google.
4. **Play Console** (US$ 25) — destrava os deep links no Android e a distribuição.
5. **Apple Developer** (US$ 99/ano) — destrava tudo do iOS de uma vez: login, deep links, push,
   assinatura e publicação.
6. **Stripe e lojas** — por último, e as lojas exigem escrever as duas implementações de
   `StoreReceiptVerifier` antes de qualquer credencial servir para algo.

---

## Resumo: nada disto quebra o desenvolvimento

Vale repetir, porque é uma escolha de projeto e não um acidente: `docker compose up -d` seguido de
`./gradlew :myotrack-api:bootRun` funciona sem configurar **nada** desta lista. Cada entrada de
`application.yml` documenta o que acontece quando fica vazia, e a lista completa está lá — este
documento é o recorte do que exige uma decisão ou uma compra fora do repositório.
