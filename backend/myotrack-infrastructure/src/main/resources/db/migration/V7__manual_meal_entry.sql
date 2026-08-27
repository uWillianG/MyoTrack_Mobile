-- Entrada manual de refeição no diário alimentar.
--
-- A refeição digitada à mão entra na MESMA tabela da análise por foto, e não numa tabela nova.
-- A escolha foi feita olhando os leitores, não a modelagem: diário (DiaryController), relatório
-- semanal (WeeklyReportHandler), exportação de dados e exclusão de conta (LGPD) leem
-- "MealPhotoAnalyses" e somam o que encontram. Com uma segunda tabela, cada um deles passaria a
-- ler duas fontes, uni-las e ordená-las — quatro lugares para esquecer a metade nova, e o
-- sintoma de esquecer é o pior possível: um dia do diário que fecha com menos caloria do que a
-- pessoa comeu, sem erro nenhum em lugar nenhum.
--
-- O preço é este arquivo: duas colunas que só a foto tem passam a aceitar NULL.

-- A foto e o job existem para a análise por imagem; a refeição manual não tem nem um nem outro.
ALTER TABLE "MealPhotoAnalyses" ALTER COLUMN "MediaKey" DROP NOT NULL;
ALTER TABLE "MealPhotoAnalyses" ALTER COLUMN "AnalysisJobId" DROP NOT NULL;

-- O índice único de "AnalysisJobId" continua valendo e continua correto: no Postgres, NULLs são
-- distintos entre si num índice único (NULLS DISTINCT é o padrão), então quantas refeições
-- manuais o usuário quiser convivem sem colidir, e um job continua produzindo no máximo uma
-- análise. Não é preciso recriar nada — está registrado aqui porque a leitura do baseline sugere
-- o contrário a quem não conhece essa regra.

-- Origem da linha: 1 = Photo, 2 = Manual (com.myotrack.domain.MealSource).
--
-- NÃO é derivável da nulidade de "MediaKey". A retenção de mídia (LGPD) apaga a foto e deixa a
-- linha para trás; sem esta coluna, "refeição sem foto" e "foto que expirou" seriam o mesmo
-- estado, e nenhuma consulta futura conseguiria separá-las — nem a própria varredura de
-- retenção, que precisa ignorar quem nunca teve arquivo.
--
-- O DEFAULT existe só para as linhas que já estão gravadas: todas são anteriores à entrada
-- manual, então Photo é o valor historicamente correto e não um chute. Depois disso ele sai, e
-- pelo mesmo motivo do "Provider" na V6: escrita nova sem origem declarada é bug, e falhar na
-- inserção é melhor que aparecer no diário classificada como qualquer coisa.
ALTER TABLE "MealPhotoAnalyses" ADD COLUMN "Source" integer NOT NULL DEFAULT 1;
ALTER TABLE "MealPhotoAnalyses" ALTER COLUMN "Source" DROP DEFAULT;

-- O catálogo passa a servir a dois consumidores com necessidades opostas.
--
-- O diário precisa achar o que a pessoa comeu de verdade: açúcar, refrigerante, coxinha, whey.
-- O DietRuleEngine escolhe pelo macro dominante — proteína por grama, carboidrato por grama — e
-- para ele esses mesmos itens são os melhores candidatos que existem. Ampliar o catálogo sem
-- esta coluna montaria planos alimentares de açúcar refinado e proteína em pó, numa
-- funcionalidade que ninguém pediu para mexer.
--
-- Aqui o DEFAULT fica: alimento novo é comida de verdade até alguém dizer o contrário, e o
-- inverso obrigaria toda inserção futura a se declarar apta a entrar numa dieta — pergunta que
-- quem cadastra um alimento para o diário não tem por que responder.
ALTER TABLE "FoodItems" ADD COLUMN "UsableInDiet" boolean NOT NULL DEFAULT true;
