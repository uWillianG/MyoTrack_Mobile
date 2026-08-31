-- Conversas separadas no coach.
--
-- Até aqui cada usuário tinha UM fio só: toda pergunta caía na mesma linha do tempo, e a tela
-- carregava as últimas 50 mensagens dela. Isso se sustenta no primeiro mês e desmonta depois —
-- a dúvida de ontem sobre o ombro fica encostada na de hoje sobre a dieta, o contexto que vai
-- para o modelo mistura as duas, e não há para onde voltar quando alguém quer reler o que o
-- coach respondeu sobre a lesão. Chatbot nenhum se usa assim: conversa é um assunto, e assunto
-- tem começo, nome e um lugar na lista.

CREATE TABLE "CoachConversations" (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    -- O título nasce da primeira pergunta recortada e é reescrito pelo Worker na primeira
    -- resposta, com o assunto que o modelo entendeu. NOT NULL porque a lista não tem outro
    -- jeito de nomear uma linha: sem título ela precisaria abrir cada conversa para descobrir
    -- do que ela trata, e aí a lista não serviria para nada.
    "Title" varchar(120) NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    -- Quando a última mensagem entrou. É por ela que a lista ordena, e não por "CreatedAt":
    -- ordenar pela data em que o assunto começou afundaria para o fim da lista justamente a
    -- conversa retomada hoje.
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_CoachConversations" PRIMARY KEY ("Id")
);

-- A consulta que abre a tela: as conversas deste usuário, da mais recente para a mais antiga.
CREATE INDEX "IX_CoachConversations_UserId_UpdatedAt"
    ON "CoachConversations" ("UserId", "UpdatedAt");

-- Anulável só durante esta migração: as mensagens que já existem ainda não têm conversa, e é o
-- UPDATE abaixo que dá uma a elas antes de a coluna ficar obrigatória.
ALTER TABLE "CoachMessages" ADD COLUMN "ConversationId" uuid;

-- O que já foi conversado vira UMA conversa por usuário, e não uma por dia.
--
-- Cortar por dia inventaria uma divisão de assunto que ninguém fez: quem perguntou na segunda e
-- voltou na terça sobre a mesma dor veria dois fios sem relação. O histórico entrou no banco
-- como fio único, e é como fio único que ele continua legível — a separação por assunto começa
-- a valer daqui para a frente, que é quando existe alguém escolhendo.
WITH nova AS (
    INSERT INTO "CoachConversations" ("Id", "UserId", "Title", "CreatedAt", "UpdatedAt")
    SELECT
        gen_random_uuid(),
        m."UserId",
        -- A primeira pergunta, numa linha só e recortada. Quebra de linha dentro do título
        -- viraria uma lista com alturas diferentes por acidente de digitação.
        left(btrim(regexp_replace(coalesce((
            SELECT primeira."Content"
            FROM "CoachMessages" primeira
            WHERE primeira."UserId" = m."UserId" AND primeira."FromUser"
            ORDER BY primeira."CreatedAt"
            LIMIT 1
        ), 'Conversa com o coach'), '\s+', ' ', 'g')), 120),
        min(m."CreatedAt"),
        max(m."CreatedAt")
    FROM "CoachMessages" m
    GROUP BY m."UserId"
    RETURNING "Id", "UserId"
)
UPDATE "CoachMessages" m
SET "ConversationId" = nova."Id"
FROM nova
WHERE nova."UserId" = m."UserId";

ALTER TABLE "CoachMessages" ALTER COLUMN "ConversationId" SET NOT NULL;

-- CASCADE, e é o ponto da chave: apagar a conversa apaga o que foi dito nela. Sem isso, a
-- exclusão que a tela oferece deixaria as mensagens órfãs no banco — invisíveis para o dono e
-- ainda contando no limite diário dele.
ALTER TABLE "CoachMessages"
    ADD CONSTRAINT "FK_CoachMessages_CoachConversations_ConversationId"
    FOREIGN KEY ("ConversationId") REFERENCES "CoachConversations" ("Id") ON DELETE CASCADE;

-- A consulta de toda abertura de conversa, e a que o Worker faz antes de chamar o modelo. O
-- índice antigo por ("UserId", "CreatedAt") continua servindo à contagem do limite diário, que
-- é por usuário e não por conversa.
CREATE INDEX "IX_CoachMessages_ConversationId_CreatedAt"
    ON "CoachMessages" ("ConversationId", "CreatedAt");
