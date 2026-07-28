-- Tokens de redefinição de senha.
--
-- O backend .NET não tinha esta tabela: ele usava o DataProtectionTokenProvider do Identity,
-- que assina o token com a chave de Data Protection e não guarda nada. Essa chave não existe
-- do lado Java, então o token passa a ser opaco e persistido — só o hash SHA-256, nunca o valor
-- bruto, pela mesma razão de RefreshTokens e LoginCodes.
--
-- CONSEQUÊNCIA NA TRANSIÇÃO: um link de redefinição pedido no backend .NET não é aceito pelo
-- backend Java (e vice-versa). São minutos de janela por usuário, e o pedido pode ser refeito;
-- não vale sincronizar chaves de Data Protection entre as duas stacks por causa disso.

CREATE TABLE "PasswordResetTokens" (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "TokenHash" character varying(64) NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "ExpiresAt" timestamp with time zone NOT NULL,
    "UsedAt" timestamp with time zone,
    CONSTRAINT "PK_PasswordResetTokens" PRIMARY KEY ("Id")
);

CREATE UNIQUE INDEX "IX_PasswordResetTokens_TokenHash" ON "PasswordResetTokens" ("TokenHash");
CREATE INDEX "IX_PasswordResetTokens_UserId" ON "PasswordResetTokens" ("UserId");
