-- Tokens de push dos aparelhos.
--
-- O backend .NET não tinha isto: a SPA acompanhava as gerações por SSE com a aba aberta, então
-- nunca houve o que avisar. No app o caso comum é o oposto — o relatório semanal é gerado por um
-- agendador enquanto ninguém está olhando, e a análise de vídeo leva minutos com o aparelho no
-- bolso.
--
-- O token identifica a INSTALAÇÃO, não a pessoa. Duas consequências que definem o schema:
--
--   1. O mesmo token pode trocar de dono. Quem sai da conta e entra com outra no mesmo aparelho
--      mantém o token que o FCM já emitiu. Daí o índice único em "Token" e o registro que
--      reatribui "UserId" em vez de inserir: sem isso o aparelho passaria a receber as
--      notificações das duas contas, e o vazamento seria de dado pessoal para a pessoa errada.
--
--   2. O token expira sem avisar. O FCM o rotaciona por conta própria (reinstalação, restauração
--      de backup, limpeza de dados) e o antigo simplesmente para de valer. Por isso "LastSeenAt":
--      é o que permite distinguir aparelho ativo de lixo acumulado, já que o provedor só informa
--      que um token morreu no momento em que se tenta enviar para ele.

CREATE TABLE "DeviceTokens" (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    -- text e não varchar(N): o token do FCM não tem tamanho documentado e já passou de 160
    -- caracteres em versões diferentes do SDK. Truncar aqui produz um token que o provedor
    -- recusa como inválido, o que é indistinguível de app desinstalado.
    "Token" text NOT NULL,
    -- 0 = Android, 1 = iOS. Não é diagnóstico: a mensagem do FCM v1 carrega blocos separados
    -- para cada plataforma, e é este campo que decide qual preencher.
    "Platform" integer NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    -- Atualizado a cada registro, que o app refaz na abertura. Sem FK para "AspNetUsers", como
    -- em "RefreshTokens" e "PasswordResetTokens": a limpeza é por UserId, no purge da conta.
    "LastSeenAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_DeviceTokens" PRIMARY KEY ("Id")
);

CREATE UNIQUE INDEX "IX_DeviceTokens_Token" ON "DeviceTokens" ("Token");
CREATE INDEX "IX_DeviceTokens_UserId" ON "DeviceTokens" ("UserId");
