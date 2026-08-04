-- Pro concedido por constância de treino.
--
-- TABELA SEPARADA DE "UserSubscriptions", e não uma linha nela. Aquela tabela é o cache local
-- do que a loja (Stripe, Apple, Google) diz — o webhook a reescreve inteira quando a assinatura
-- muda de status. Uma concessão gravada lá seria apagada na primeira notificação, e pior: ela
-- apareceria em qualquer contagem de assinantes como receita que nunca existiu. Aqui a origem
-- do Pro fica explícita e auditável, e o "quem pagou" continua sendo uma pergunta com resposta
-- exata.
--
-- Uma concessão por marca, para sempre: o índice único em (UserId, Milestone) é o que impede
-- que doze semanas seguidas — que permanecem verdadeiras por meses — rendam um mês de Pro a
-- cada abertura do app. Quem perde a sequência e a reconquista não ganha de novo, e isso é
-- deliberado: a alternativa é uma janela de recarga, que vira alvo de quem quiser ciclar.

CREATE TABLE "ProGrants" (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    -- O id da marca no catálogo: 'quatro-semanas', 'doze-semanas'. Texto e não enum do banco
    -- porque a lista muda com o produto, e ALTER TYPE em produção é migração travando tabela.
    "Milestone" varchar(50) NOT NULL,
    "GrantedAt" timestamp with time zone NOT NULL,
    "ExpiresAt" timestamp with time zone NOT NULL,
    -- A sequência no momento da concessão. Não decide nada: existe para que uma auditoria
    -- consiga responder "por que esta pessoa ganhou" sem reprocessar o histórico de sessões.
    "StreakWeeks" integer NOT NULL,
    CONSTRAINT "PK_ProGrants" PRIMARY KEY ("Id")
);

CREATE UNIQUE INDEX "IX_ProGrants_UserId_Milestone" ON "ProGrants" ("UserId", "Milestone");

-- A consulta quente: "este usuário tem Pro concedido valendo agora?". Roda em toda checagem de
-- limite de IA, que é o caminho mais percorrido do backend.
CREATE INDEX "IX_ProGrants_UserId_ExpiresAt" ON "ProGrants" ("UserId", "ExpiresAt");
