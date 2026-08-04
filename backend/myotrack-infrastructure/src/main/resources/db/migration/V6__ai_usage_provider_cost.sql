-- Provedor e custo na trilha de consumo de IA.
--
-- Enquanto havia um provedor só, somar tokens respondia "quanto se gastou". Com Gemini e OpenAI
-- lado a lado, duas linhas com a mesma contagem de tokens podem diferir por uma ordem de grandeza
-- em dinheiro: a tabela media uso e parecia medir gasto.
--
-- O DEFAULT no "Provider" é só para as linhas que já existem — todas elas são anteriores à
-- entrada da OpenAI, então "gemini" é o valor historicamente correto e não um chute. A coluna
-- fica NOT NULL sem default depois disso: escrita nova sem provedor é bug, e é melhor que ela
-- falhe na inserção do que apareça no relatório atribuída à conta errada.
ALTER TABLE "AiUsageLogs" ADD COLUMN "Provider" text NOT NULL DEFAULT 'gemini';
ALTER TABLE "AiUsageLogs" ALTER COLUMN "Provider" DROP DEFAULT;

-- Custo em nano-dólares (10⁻⁹), anulável.
--
-- Nano e não centavo porque uma extração de foto custa frações de centavo: em centavos inteiros
-- toda chamada arredondaria para zero e a soma do mês diria que a IA é gratuita.
--
-- Anulável porque o preço mora em configuração e um modelo recém-trocado pode não ter preço
-- registrado ainda. NULL diz "não sei"; zero afirmaria "foi de graça". Quem consultar precisa
-- somar o custo e contar as linhas nulas junto, ou vai reportar menos gasto do que houve.
ALTER TABLE "AiUsageLogs" ADD COLUMN "CostNanoUsd" bigint NULL;

-- As linhas antigas ficam com custo desconhecido, e é o que elas são: foram gravadas quando não
-- havia tabela de preços, e preencher agora com o preço de hoje dataria errado o gasto de ontem.
