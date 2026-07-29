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
| `MYOTRACK_ANTHROPIC_API_KEY` ou `MYOTRACK_GEMINI_API_KEY` | Worker | Treino e dieta saem só do motor de regras; sem narrativa nem análise de foto. |
| `MYOTRACK_VISION_BASE_URL` | Worker | Análise de vídeo falha. |
| `MYOTRACK_JWT_SIGNING_KEY` | API | Usa a chave de desenvolvimento — **troque em produção**. |
| `MYOTRACK_PUBLIC_BASE_URL` | API | Base dos links enviados por e-mail. |
| `MYOTRACK_EMAIL_USER` / `_PASSWORD` | API | O e-mail não é enviado, só registrado no log. |
| `MYOTRACK_STRIPE_SECRET_KEY` | API | Pagamento desligado; todos no plano gratuito. |

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

## Deep links: verificação de domínio

O link que o backend manda por e-mail (`https://myotrack.app/redefinir-senha?...`) só abre o
app se o domínio provar que pertence ao mesmo dono. A API serve os dois arquivos que fazem
isso, em `/.well-known/`, mas **eles não aparecem enquanto não forem configurados** — servir um
arquivo incompleto é pior que não servir, porque a plataforma o busca, lê, descarta em silêncio,
e o sintoma no aparelho fica idêntico ao de arquivo nenhum.

| Variável | Onde achar o valor |
|---|---|
| `MYOTRACK_ANDROID_CERT_FINGERPRINTS` | Play Console > Setup > App signing. Com **Play App Signing** é a SHA-256 do Google, **não** a do seu keystore de upload — o Google reassina o APK antes de distribuir. Trocar as duas é o engano comum, e o sintoma é o link seguir abrindo o navegador sem erro nenhum. |
| `MYOTRACK_APPLE_APP_ID` | `TEAMID.com.myotrack.app`. O Team ID está no portal da Apple, em Membership. Exige conta paga. |

Aceita mais de uma impressão digital, separadas por vírgula — útil numa migração de chave ou
para autorizar a de debug em ambiente de teste. Para pegar a de debug:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

Confira depois de configurar:

```bash
curl -i https://myotrack.app/.well-known/assetlinks.json
curl -i https://myotrack.app/.well-known/apple-app-site-association
```

Os dois precisam responder `200` com `Content-Type: application/json`, **sem redirecionamento**
— as duas plataformas recusam 301/302. E o domínio precisa rotear `/.well-known/*` para a API:
hoje o Caddy do repositório .NET manda tudo que não é `/api/*` para os estáticos do frontend,
então falta lá um bloco

```
handle /.well-known/* {
	reverse_proxy api:8080
}
```

No Android dá para conferir a verificação no aparelho com
`adb shell pm get-app-links com.myotrack.app`.

## Falta para produção

- **Não há build de release nem assinatura.** O `android/app/build.gradle.kts` ainda assina
  release com a chave de debug (`TODO` do template do Flutter). Falta keystore no Android e
  certificado com perfil no iOS.
- **A verificação de domínio acima** ainda não tem os valores: dependem de publicar na Play
  Store e de conta paga da Apple.
