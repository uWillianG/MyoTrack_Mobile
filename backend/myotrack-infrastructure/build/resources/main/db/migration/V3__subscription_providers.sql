-- Assinaturas de múltiplos provedores.
--
-- Até aqui o Stripe era a única forma de assinar, e a tabela foi modelada em cima dele
-- ("StripeCustomerId", "StripeSubscriptionId", "StripeStatus"). Com o app nas lojas passam a
-- existir TRÊS fontes de verdade — Stripe na web, App Store no iOS e Google Play no Android —
-- e cada uma tem seu próprio identificador de assinatura e seu próprio vocabulário de status.
--
-- As colunas do Stripe são preservadas: as linhas atuais continuam válidas e o fluxo web segue
-- funcionando sem migração de dados.

-- 0 = Stripe, 1 = AppStore, 2 = GooglePlay. O default cobre as linhas que já existem.
ALTER TABLE "UserSubscriptions"
    ADD COLUMN "Provider" integer NOT NULL DEFAULT 0;

-- Identificador da assinatura no provedor, seja ele qual for. Para o Stripe é uma cópia de
-- "StripeSubscriptionId"; para as lojas é o originalTransactionId (Apple) ou o purchaseToken
-- (Google). É por ele que uma notificação da loja encontra o usuário.
ALTER TABLE "UserSubscriptions"
    ADD COLUMN "ProviderSubscriptionId" text;

-- Status bruto do provedor, para diagnóstico e para a tela ("active", "SUBSCRIBED", "EXPIRED"…).
ALTER TABLE "UserSubscriptions"
    ADD COLUMN "ProviderStatus" character varying(50);

-- Backfill: as assinaturas existentes são todas do Stripe.
UPDATE "UserSubscriptions"
SET "ProviderSubscriptionId" = "StripeSubscriptionId",
    "ProviderStatus"         = "StripeStatus"
WHERE "StripeSubscriptionId" IS NOT NULL;

-- Um mesmo id de assinatura não pode pertencer a dois usuários. Parcial porque o Postgres
-- trata NULLs como distintos, e a maioria das linhas terá o campo do provedor vazio.
CREATE UNIQUE INDEX "IX_UserSubscriptions_Provider_ProviderSubscriptionId"
    ON "UserSubscriptions" ("Provider", "ProviderSubscriptionId")
    WHERE "ProviderSubscriptionId" IS NOT NULL;

-- Idempotência das notificações das lojas — mesmo papel que "StripeEventLogs" cumpre para o
-- Stripe. Apple e Google reentregam notificações até receberem 200, então processar duas vezes
-- é o caso comum, não a exceção.
CREATE TABLE "StoreNotificationLogs" (
    -- Chave natural do provedor: notificationUUID (Apple) ou messageId do Pub/Sub (Google).
    "Id" character varying(255) NOT NULL,
    "Provider" integer NOT NULL,
    "Type" character varying(100) NOT NULL,
    "ProcessedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_StoreNotificationLogs" PRIMARY KEY ("Id")
);
