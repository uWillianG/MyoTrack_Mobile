-- Catálogo de alimentos: subconjunto curado da dieta brasileira, valores por 100 g.
--
-- POR QUE AQUI E NÃO NO DbSeeder. O catálogo era semeado em Java, no startup da API, com a
-- guarda `if (foods.count() == 0)`. Isso funciona uma vez e depois congela: um item novo nunca
-- entra num banco que já tem alimentos, e a lista Java passa a descrever um catálogo que só
-- existe em máquina nova. Migração faz o oposto — roda uma vez por banco, na ordem, e o que ela
-- afirma é o que está lá. O seed de alimentos saiu do DbSeeder junto com esta migração; o de
-- papéis e exercícios continua onde estava, porque aqueles sincronizam a cada boot de propósito.
--
-- IDEMPOTENTE POR NOME, e não por id. Os bancos de desenvolvimento já têm as ~50 primeiras
-- linhas gravadas pelo seed antigo, com ids que o IDENTITY distribuiu; casar por id gravaria
-- tudo em duplicidade. O `NOT EXISTS` por nome em minúsculas insere só o que falta.
--
-- O UPDATE no fim existe pelas linhas antigas: elas nasceram antes da coluna "UsableInDiet" e
-- pegaram o DEFAULT `true` do ALTER TABLE. Sem ele, "Whey protein concentrado (pó)" continuaria
-- elegível a plano alimentar num banco já existente e não num banco novo — a pior espécie de
-- divergência, porque só aparece em produção.
--
-- Fonte dos valores: TACO 4ª ed. (arredondados) onde a coluna diz TACO. As linhas marcadas como
-- Custom são estimativas de preparações e industrializados que a TACO não cobre; elas existem
-- porque o diário precisa achar o que a pessoa comeu de verdade, e não o que seria ideal ter
-- comido. Nenhuma delas entra em plano alimentar — é o que a coluna "UsableInDiet" decide.

WITH catalogo(nome, fonte, kcal, prot, carb, gord, fibra, dieta) AS (
    VALUES
    -- Cereais, pães, massas e tubérculos ------------------------------------------------------
    ('Arroz branco cozido',                  'TACO',   128::numeric, 2.5::numeric, 28.1::numeric, 0.2::numeric, 1.6::numeric, true),
    ('Arroz integral cozido',                'TACO',   124, 2.6,  25.8,  1.0,  2.7,  true),
    ('Arroz parboilizado cozido',            'TACO',   123, 2.5,  25.8,  1.0,  2.7,  true),
    ('Aveia em flocos crua',                 'TACO',   394, 13.9, 66.6,  8.5,  9.1,  true),
    ('Farelo de aveia',                      'TACO',   335, 14.5, 55.0,  8.0,  15.0, true),
    ('Pão francês',                          'TACO',   300, 8.0,  58.6,  3.1,  2.3,  true),
    ('Pão integral de trigo',                'TACO',   253, 9.4,  49.9,  3.7,  6.9,  true),
    ('Pão de forma branco',                  'TACO',   269, 8.9,  52.0,  3.0,  2.5,  true),
    ('Pão de queijo assado',                 'Custom', 363, 5.0,  38.0,  20.0, 1.0,  false),
    ('Torrada integral',                     'TACO',   377, 11.9, 71.6,  4.4,  5.0,  true),
    ('Biscoito cream cracker',               'TACO',   432, 9.9,  68.7,  14.4, 2.5,  false),
    ('Biscoito recheado de chocolate',       'TACO',   472, 6.4,  71.0,  18.0, 2.0,  false),
    ('Macarrão cozido',                      'TACO',   122, 3.9,  24.5,  1.3,  1.5,  true),
    ('Macarrão integral cozido',             'TACO',   124, 5.0,  25.0,  0.9,  3.0,  true),
    ('Cuscuz de milho cozido',               'TACO',   113, 2.2,  25.3,  0.6,  1.4,  true),
    ('Farinha de mandioca torrada',          'TACO',   365, 1.6,  87.9,  0.3,  6.4,  true),
    ('Tapioca (goma hidratada)',             'TACO',   240, 0,    60.0,  0,    0,    true),
    ('Polenta cozida',                       'TACO',   102, 1.8,  22.5,  0.6,  1.0,  true),
    ('Milho verde em conserva',              'TACO',   98,  3.2,  17.1,  2.2,  3.9,  true),
    ('Batata inglesa cozida',                'TACO',   52,  1.2,  11.9,  0,    1.3,  true),
    ('Batata frita',                         'TACO',   267, 5.1,  35.6,  13.0, 3.0,  false),
    ('Batata-doce cozida',                   'TACO',   77,  0.6,  18.4,  0.1,  2.2,  true),
    ('Mandioca cozida',                      'TACO',   125, 0.6,  30.1,  0.3,  1.6,  true),
    ('Inhame cozido',                        'TACO',   97,  2.1,  22.5,  0.2,  2.2,  true),
    ('Cará cozido',                          'TACO',   82,  1.5,  19.5,  0.1,  2.0,  true),
    ('Quinoa cozida',                        'TBCA',   120, 4.4,  21.3,  1.9,  2.8,  true),
    ('Granola',                              'Custom', 471, 10.2, 65.0,  19.0, 6.0,  true),
    ('Farinha de trigo',                     'TACO',   360, 9.8,  75.1,  1.4,  2.3,  true),
    ('Farinha de rosca',                     'TACO',   371, 11.4, 78.4,  1.8,  3.0,  false),
    ('Pipoca com óleo',                      'TACO',   448, 9.9,  70.8,  15.4, 14.3, false),
    ('Cereal matinal de milho',              'TACO',   375, 7.2,  84.2,  0.9,  2.9,  false),
    ('Bolo de chocolate',                    'TACO',   410, 5.4,  53.4,  19.7, 1.5,  false),
    ('Panqueca simples',                     'Custom', 227, 6.4,  28.0,  9.7,  1.0,  false),

    -- Leguminosas -----------------------------------------------------------------------------
    ('Feijão carioca cozido',                'TACO',   76,  4.8,  13.6,  0.5,  8.5,  true),
    ('Feijão preto cozido',                  'TACO',   77,  4.5,  14.0,  0.5,  8.4,  true),
    ('Feijão branco cozido',                 'TACO',   89,  6.0,  15.3,  0.6,  9.0,  true),
    ('Feijão fradinho cozido',               'TACO',   78,  5.0,  13.5,  0.6,  6.0,  true),
    ('Feijoada',                             'TACO',   117, 8.6,  5.4,   6.7,  2.4,  false),
    ('Lentilha cozida',                      'TACO',   93,  6.3,  16.3,  0.5,  7.9,  true),
    ('Grão-de-bico cozido',                  'TACO',   164, 8.9,  27.4,  2.6,  7.6,  true),
    ('Ervilha em conserva',                  'TACO',   74,  4.6,  13.2,  0.5,  4.6,  true),
    ('Soja cozida',                          'TACO',   151, 15.7, 9.4,   6.4,  6.0,  true),
    ('Tofu',                                 'TACO',   76,  8.1,  1.9,   4.8,  0.7,  true),
    ('Proteína texturizada de soja',         'Custom', 337, 51.0, 30.0,  1.5,  15.0, false),
    ('Homus',                                'Custom', 166, 7.9,  14.3,  9.6,  6.0,  true),

    -- Carnes, peixes e ovos -------------------------------------------------------------------
    ('Peito de frango grelhado (sem pele)',  'TACO',   159, 32.0, 0,     2.5,  NULL, true),
    ('Coxa de frango assada (sem pele)',     'TACO',   167, 26.9, 0,     5.8,  NULL, true),
    ('Sobrecoxa de frango assada (com pele)', 'TACO',  215, 24.0, 0,     13.0, NULL, true),
    ('Peito de peru defumado',               'TACO',   96,  17.0, 2.5,   1.8,  NULL, true),
    ('Carne bovina — patinho grelhado',      'TACO',   219, 35.9, 0,     7.3,  NULL, true),
    ('Carne bovina — alcatra grelhada',      'TACO',   241, 32.0, 0,     12.0, NULL, true),
    ('Carne bovina — contrafilé grelhado',   'TACO',   278, 32.0, 0,     16.0, NULL, true),
    ('Carne bovina — coxão mole cozido',     'TACO',   219, 31.9, 0,     9.2,  NULL, true),
    ('Carne bovina — acém moído cozido',     'TACO',   212, 26.7, 0,     10.9, NULL, true),
    ('Carne bovina — costela assada',        'TACO',   373, 28.8, 0,     28.0, NULL, false),
    ('Fígado bovino grelhado',               'TACO',   225, 29.8, 3.0,   9.5,  NULL, true),
    ('Carne suína — lombo assado',           'TACO',   210, 35.7, 0,     6.4,  NULL, true),
    ('Carne suína — pernil assado',          'TACO',   262, 29.0, 0,     15.9, NULL, true),
    ('Bacon frito',                          'TACO',   541, 30.0, 0,     47.0, NULL, false),
    ('Linguiça de porco frita',              'TACO',   296, 20.0, 0,     24.0, NULL, false),
    ('Linguiça de frango grelhada',          'TACO',   217, 20.0, 0,     15.0, NULL, false),
    ('Salsicha',                             'TACO',   257, 12.2, 3.4,   21.0, NULL, false),
    ('Presunto cozido',                      'TACO',   121, 14.4, 1.4,   6.4,  NULL, true),
    ('Mortadela',                            'TACO',   269, 11.9, 4.0,   23.0, NULL, false),
    ('Hambúrguer bovino grelhado',           'TACO',   220, 19.0, 3.0,   14.0, NULL, false),
    ('Tilápia grelhada',                     'TACO',   128, 26.0, 0,     2.0,  NULL, true),
    ('Salmão grelhado',                      'TACO',   243, 23.0, 0,     16.4, NULL, true),
    ('Sardinha assada',                      'TACO',   164, 32.2, 0,     3.9,  NULL, true),
    ('Atum em conserva (água)',              'TACO',   108, 24.0, 0,     1.0,  NULL, true),
    ('Merluza assada',                       'TACO',   122, 26.6, 0,     1.0,  NULL, true),
    ('Bacalhau cozido',                      'TACO',   138, 29.0, 0,     1.5,  NULL, true),
    ('Camarão cozido',                       'TACO',   90,  19.0, 0,     1.0,  NULL, true),
    ('Ovo de galinha cozido',                'TACO',   146, 13.3, 0.6,   9.5,  NULL, true),
    ('Ovo de galinha frito',                 'TACO',   240, 15.6, 1.2,   18.6, NULL, true),
    ('Ovo mexido',                           'TACO',   213, 13.0, 1.5,   17.0, NULL, true),
    ('Clara de ovo cozida',                  'TACO',   59,  13.4, 0,     0.1,  NULL, true),
    ('Gema de ovo cozida',                   'TACO',   353, 15.9, 1.6,   30.9, NULL, false),

    -- Laticínios ------------------------------------------------------------------------------
    ('Leite integral',                       'TACO',   61,  3.2,  4.6,   3.3,  NULL, true),
    ('Leite desnatado',                      'TACO',   35,  3.4,  5.0,   0.2,  NULL, true),
    ('Leite semidesnatado',                  'TACO',   47,  3.3,  4.8,   1.6,  NULL, true),
    ('Leite em pó integral',                 'TACO',   497, 25.4, 39.2,  26.9, NULL, false),
    ('Iogurte natural integral',             'TACO',   51,  4.1,  1.9,   3.0,  NULL, true),
    ('Iogurte natural desnatado',            'TACO',   42,  3.8,  5.8,   0.3,  NULL, true),
    ('Iogurte grego natural',                'Custom', 97,  8.8,  4.0,   5.0,  NULL, true),
    ('Iogurte de frutas',                    'TACO',   70,  3.0,  13.0,  1.0,  NULL, false),
    ('Queijo minas frescal',                 'TACO',   264, 17.4, 3.2,   20.2, NULL, true),
    ('Queijo minas meia cura',               'TACO',   321, 22.6, 2.9,   24.6, NULL, true),
    ('Queijo muçarela',                      'TACO',   330, 22.6, 3.0,   25.2, NULL, true),
    ('Queijo prato',                         'TACO',   360, 22.7, 1.9,   29.1, NULL, true),
    ('Queijo parmesão',                      'TACO',   453, 35.6, 1.7,   33.5, NULL, false),
    ('Queijo cottage',                       'Custom', 98,  11.0, 3.0,   4.5,  NULL, true),
    ('Requeijão cremoso',                    'TACO',   257, 9.6,  2.4,   23.4, NULL, true),
    ('Cream cheese',                         'Custom', 313, 6.0,  4.0,   30.0, NULL, false),
    ('Manteiga com sal',                     'TACO',   726, 0.4,  0.1,   82.4, NULL, false),
    ('Margarina',                            'TACO',   596, 0,    0,     67.0, NULL, false),
    ('Creme de leite',                       'TACO',   217, 2.0,  4.0,   21.0, NULL, false),
    ('Leite condensado',                     'TACO',   313, 7.5,  57.0,  6.7,  NULL, false),
    ('Doce de leite',                        'TACO',   306, 6.0,  59.0,  6.0,  NULL, false),

    -- Frutas ----------------------------------------------------------------------------------
    ('Banana prata',                         'TACO',   98,  1.3,  26.0,  0.1,  2.0,  true),
    ('Banana nanica',                        'TACO',   92,  1.4,  23.8,  0.1,  1.9,  true),
    ('Maçã com casca',                       'TACO',   56,  0.3,  15.2,  0,    1.3,  true),
    ('Laranja pera',                         'TACO',   37,  1.0,  8.9,   0.1,  0.8,  true),
    ('Mamão papaia',                         'TACO',   40,  0.5,  10.4,  0.1,  1.0,  true),
    ('Mamão formosa',                        'TACO',   45,  0.8,  11.6,  0.1,  1.8,  true),
    ('Abacate',                              'TACO',   96,  1.2,  6.0,   8.4,  6.3,  true),
    ('Morango',                              'TACO',   30,  0.9,  6.8,   0.3,  1.7,  true),
    ('Manga palmer',                         'TACO',   72,  0.4,  19.4,  0.2,  1.6,  true),
    ('Melancia',                             'TACO',   33,  0.9,  8.1,   0,    0.1,  true),
    ('Melão',                                'TACO',   29,  0.7,  7.5,   0,    0.3,  true),
    ('Uva itália',                           'TACO',   53,  0.7,  13.6,  0.2,  0.9,  true),
    ('Abacaxi',                              'TACO',   48,  0.9,  12.3,  0.1,  1.0,  true),
    ('Pera',                                 'TACO',   53,  0.6,  14.0,  0.1,  3.0,  true),
    ('Kiwi',                                 'TACO',   51,  1.3,  11.5,  0.6,  2.7,  true),
    ('Goiaba vermelha',                      'TACO',   54,  1.1,  13.0,  0.4,  6.2,  true),
    ('Tangerina',                            'TACO',   58,  0.8,  14.6,  0.1,  1.7,  true),
    ('Caju',                                 'TACO',   43,  1.0,  10.3,  0.3,  1.7,  true),
    ('Açaí polpa',                           'TACO',   58,  0.8,  6.2,   3.9,  2.6,  true),
    ('Coco fresco',                          'TACO',   406, 3.7,  10.4,  42.0, 5.4,  false),
    ('Ameixa',                               'TACO',   53,  0.8,  13.9,  0,    2.4,  true),
    ('Maracujá',                             'TACO',   68,  2.0,  12.3,  2.1,  1.1,  true),
    ('Pêssego',                              'TACO',   36,  0.8,  9.3,   0,    1.4,  true),
    ('Uva passa',                            'TACO',   299, 2.2,  79.0,  0.5,  3.7,  false),

    -- Verduras e legumes ----------------------------------------------------------------------
    ('Brócolis cozido',                      'TACO',   25,  2.1,  4.4,   0.5,  3.4,  true),
    ('Cenoura crua',                         'TACO',   34,  1.3,  7.7,   0.2,  3.2,  true),
    ('Cenoura cozida',                       'TACO',   30,  0.8,  6.7,   0.2,  2.6,  true),
    ('Tomate cru',                           'TACO',   15,  1.1,  3.1,   0.2,  1.2,  true),
    ('Alface crespa',                        'TACO',   11,  1.3,  1.7,   0.2,  1.8,  true),
    ('Alface americana',                     'TACO',   9,   0.6,  1.7,   0.1,  1.0,  true),
    ('Rúcula',                               'TACO',   13,  1.8,  2.2,   0.2,  1.4,  true),
    ('Abobrinha cozida',                     'TACO',   15,  1.1,  3.0,   0.2,  1.6,  true),
    ('Couve refogada',                       'TACO',   90,  3.1,  8.7,   5.5,  5.7,  true),
    ('Couve-flor cozida',                    'TACO',   19,  1.2,  3.9,   0.3,  2.1,  true),
    ('Repolho cru',                          'TACO',   17,  1.0,  4.0,   0.1,  1.9,  true),
    ('Espinafre cozido',                     'TACO',   22,  2.9,  2.6,   0.3,  2.5,  true),
    ('Beterraba cozida',                     'TACO',   32,  1.3,  7.2,   0.1,  1.9,  true),
    ('Chuchu cozido',                        'TACO',   19,  0.4,  4.8,   0.1,  1.0,  true),
    ('Pepino cru',                           'TACO',   10,  0.9,  2.0,   0,    1.1,  true),
    ('Pimentão verde',                       'TACO',   21,  1.1,  4.9,   0.2,  2.5,  true),
    ('Cebola crua',                          'TACO',   39,  1.7,  8.9,   0.1,  2.2,  true),
    ('Alho cru',                             'TACO',   113, 7.0,  23.9,  0.2,  4.3,  false),
    ('Berinjela cozida',                     'TACO',   19,  0.7,  4.4,   0.1,  2.9,  true),
    ('Quiabo cozido',                        'TACO',   30,  1.9,  6.4,   0.2,  3.6,  true),
    ('Vagem cozida',                         'TACO',   25,  1.8,  5.3,   0.2,  2.4,  true),
    ('Abóbora cozida',                       'TACO',   48,  0.9,  11.6,  0.1,  2.2,  true),
    ('Palmito em conserva',                  'TACO',   22,  1.4,  3.6,   0.4,  2.1,  true),
    ('Agrião',                               'TACO',   17,  2.7,  2.3,   0.2,  2.1,  true),
    ('Salsa',                                'TACO',   33,  3.3,  6.5,   0.5,  4.5,  false),
    ('Cogumelo champignon',                  'TBCA',   22,  3.1,  3.3,   0.3,  1.0,  true),

    -- Gorduras e oleaginosas ------------------------------------------------------------------
    ('Azeite de oliva',                      'TACO',   884, 0,    0,     100,  0,    true),
    ('Óleo de soja',                         'TACO',   884, 0,    0,     100,  0,    false),
    ('Óleo de coco',                         'TBCA',   892, 0,    0,     99.1, 0,    false),
    ('Pasta de amendoim integral',           'Custom', 589, 22.5, 21.6,  46.5, 8.0,  true),
    ('Amendoim torrado',                     'TACO',   544, 22.5, 20.3,  43.9, 8.0,  true),
    ('Castanha-de-caju torrada',             'TACO',   570, 18.5, 29.1,  46.3, 3.7,  true),
    ('Castanha-do-pará',                     'TACO',   643, 14.5, 15.1,  63.5, 7.9,  true),
    ('Amêndoa torrada',                      'TACO',   581, 18.6, 29.5,  47.3, 11.6, true),
    ('Nozes',                                'TACO',   620, 14.0, 18.4,  59.4, 7.0,  true),
    ('Avelã',                                'TACO',   632, 14.0, 17.0,  62.0, 10.0, true),
    ('Semente de chia',                      'TBCA',   486, 16.5, 42.1,  30.7, 34.4, true),
    ('Semente de linhaça',                   'TACO',   495, 14.1, 43.3,  32.3, 33.5, true),
    ('Gergelim',                             'TACO',   584, 21.2, 21.6,  50.4, 11.9, false),
    ('Maionese',                             'TACO',   302, 0.6,  7.0,   30.0, 0,    false),
    ('Chocolate ao leite',                   'TACO',   540, 7.2,  59.6,  30.3, 2.5,  false),
    ('Chocolate 70% cacau',                  'Custom', 570, 8.0,  45.0,  42.0, 11.0, false),

    -- Bebidas, doces e preparações prontas ----------------------------------------------------
    ('Açúcar refinado',                      'TACO',   387, 0,    99.5,  0,    0,    false),
    ('Mel',                                  'TACO',   309, 0.4,  84.0,  0,    0,    false),
    ('Refrigerante de cola',                 'TACO',   34,  0,    8.7,   0,    0,    false),
    ('Refrigerante zero',                    'Custom', 0,   0,    0,     0,    0,    false),
    ('Cerveja',                              'TACO',   41,  0.6,  3.3,   0,    0,    false),
    ('Vinho tinto',                          'TACO',   82,  0.2,  2.6,   0,    0,    false),
    ('Café coado sem açúcar',                'TACO',   2,   0.1,  0.3,   0,    0,    false),
    ('Suco de laranja natural',              'TACO',   37,  0.7,  8.7,   0.1,  0.2,  false),
    ('Suco de uva integral',                 'TACO',   60,  0.3,  15.0,  0,    0,    false),
    ('Água de coco',                         'TACO',   22,  0,    5.3,   0,    0,    false),
    ('Achocolatado em pó',                   'TACO',   400, 4.0,  90.0,  2.0,  3.0,  false),
    ('Ketchup',                              'Custom', 105, 1.5,  25.0,  0.2,  0.5,  false),
    ('Molho de tomate',                      'TACO',   38,  1.5,  7.0,   0.5,  1.5,  false),
    ('Barra de cereal',                      'Custom', 406, 5.0,  70.0,  12.0, 4.0,  false),
    ('Sorvete de creme',                     'TACO',   195, 3.0,  24.0,  10.0, 0.5,  false),
    ('Pudim de leite',                       'TACO',   244, 6.0,  40.0,  7.0,  0,    false),
    ('Brigadeiro',                           'Custom', 386, 5.0,  55.0,  16.0, 1.0,  false),
    ('Pizza de muçarela',                    'Custom', 269, 12.0, 30.0,  11.0, 2.0,  false),
    ('Coxinha de frango frita',              'Custom', 289, 8.0,  30.0,  15.0, 1.5,  false),
    ('Pastel de carne frito',                'Custom', 361, 8.4,  30.0,  23.0, 1.5,  false),
    ('Esfiha de carne',                      'Custom', 250, 10.0, 30.0,  10.0, 1.5,  false),
    ('Sanduíche de hambúrguer',              'Custom', 250, 13.0, 25.0,  11.0, 1.5,  false),
    ('Lasanha à bolonhesa',                  'Custom', 162, 8.0,  15.0,  7.5,  1.0,  false),
    ('Estrogonofe de frango',                'Custom', 155, 12.0, 5.0,   9.5,  0.5,  false),
    ('Arroz carreteiro',                     'Custom', 150, 9.0,  17.0,  5.0,  1.0,  false),
    ('Salgadinho de milho',                  'Custom', 500, 5.0,  60.0,  26.0, 1.5,  false),

    -- Suplementos -----------------------------------------------------------------------------
    ('Whey protein concentrado (pó)',        'Custom', 400, 80.0, 8.0,   6.0,  0,    false),
    ('Whey protein isolado (pó)',            'Custom', 373, 88.0, 2.0,   1.0,  0,    false),
    ('Albumina em pó',                       'Custom', 375, 82.0, 5.0,   1.0,  0,    false),
    ('Caseína em pó',                        'Custom', 370, 80.0, 6.0,   2.0,  0,    false),
    ('Creatina (pó)',                        'Custom', 0,   0,    0,     0,    0,    false),
    ('Maltodextrina',                        'Custom', 380, 0,    95.0,  0,    0,    false),
    ('Barra de proteína',                    'Custom', 350, 30.0, 35.0,  10.0, 5.0,  false),
    ('Hipercalórico (pó)',                   'Custom', 380, 15.0, 75.0,  3.0,  1.0,  false)
),
inseridos AS (
    INSERT INTO "FoodItems" (
        "Name", "Source", "KcalPer100g", "ProteinPer100g",
        "CarbsPer100g", "FatPer100g", "FiberPer100g", "UsableInDiet")
    SELECT c.nome, c.fonte, c.kcal, c.prot, c.carb, c.gord, c.fibra, c.dieta
    FROM catalogo c
    WHERE NOT EXISTS (
        SELECT 1 FROM "FoodItems" f WHERE lower(f."Name") = lower(c.nome)
    )
    RETURNING 1
)
-- Só as linhas que já existiam entram aqui: as recém-inseridas pelo CTE acima não são visíveis
-- para esta UPDATE (a instrução inteira enxerga um único instantâneo do banco), e nem precisam
-- ser — nasceram com o valor certo.
UPDATE "FoodItems" f
SET "UsableInDiet" = c.dieta
FROM catalogo c
WHERE lower(f."Name") = lower(c.nome)
  AND f."UsableInDiet" IS DISTINCT FROM c.dieta;

-- A busca do app é por prefixo/trecho do nome e roda a cada tecla digitada. O índice do baseline
-- ("IX_FoodItems_Name", btree em "Name") não serve para `LIKE '%arroz%'`, mas o catálogo tem
-- duas centenas de linhas: a varredura sequencial custa menos que manter um índice de trigramas,
-- e ela acontece uma vez por requisição, não uma vez por tecla — a filtragem em si é feita em
-- memória no FoodsController, porque casar "pao" com "Pão" exigiria a extensão `unaccent`, que
-- precisa de superusuário para ser criada e não existe em todo ambiente gerenciado.
