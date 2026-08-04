# Design system

Quatro arquivos, e a regra de quando mexer em cada um.

| arquivo | o que decide |
|---|---|
| `palette.dart` | as duas paletas, escritas à mão |
| `typography.dart` | a escala de texto e o estilo dos números |
| `tokens.dart` | espaço, raio, sombra e duração |
| `format.dart` | como um número aparece escrito |

`core/theme.dart` liga os quatro ao Material e ajusta cada componente. Uma tela não deveria
precisar de mais nada além de `Theme.of(context)` e destes tokens.

## As três decisões que sustentam o resto

**1. A paleta é autoral, não gerada.** `ColorScheme.fromSeed` tinge os neutros com a cor da
semente: com um verde de marca, o fundo saía menta pálido, o cartão saía menta um pouco menos
pálido, e nada tinha profundidade. Aqui os neutros são neutros e o esmeralda aparece só onde
significa alguma coisa — ação primária, progresso, estado ativo, número que melhorou.

O esmeralda da marca (`#059669`) continua sendo o dos e-mails e do frontend React. Ele
escurece um degrau no tema claro (contraste sobre branco) e clareia no escuro.

**2. Elevação tem duas físicas.** No claro, sombra curta e diluída. No escuro, sombra nenhuma
— preto sobre preto não é profundidade — e quem separa é a superfície mais clara com uma
borda de 1 px. Nos dois casos `surfaceTintColor` é transparente: o véu de cor primária que o
Material 3 pinta sobre superfícies elevadas é o que mais denuncia um tema gerado.

**3. Número é design.** Antes, o mesmo 1476 saía "1.476" no hub e "1476" no diário, e "110 g"
num lugar contra "110g" no outro. Nenhuma tela estava errada sozinha. Formatação passa por
`Fmt`, e número que é o assunto da tela usa `AppTypography.numeric` — dígitos de largura fixa,
para o valor não dançar quando muda.

## Ao escrever uma tela

- Recuo lateral: `Space.gutter`. Espaços internos: a escala de `Space`.
- Raio: `Radii`. O botão dentro de um cartão fecha mais que o cartão (`sm` contra `md`);
  com o mesmo raio nos dois, os arcos brigam.
- Barra de progresso, campo, botão, chip, folha e diálogo já vêm ajustados pelo tema —
  passar estilo por cima costuma ser sinal de que o tema é que está errado.
- Cor cheia (`primary`) é ação. Estado selecionado é `primaryContainer`. Se a coisa mais
  berrante da tela não for o que se quer que a pessoa faça, algo está trocado.

## Ver o resultado

`test/design/gallery_test.dart` renderiza as telas principais em PNG, nos dois temas:

```
flutter test --update-goldens --tags gallery --run-skipped test/design
```

As imagens saem em `test/design/goldens/`. **Não são teste de regressão** — a suíte normal as
ignora (`dart_test.yaml`). São a bancada onde se olha antes e depois de mexer no tema; um
golden que falha por 4 dp de espaçamento só ensina o time a atualizar sem olhar.

A galeria fixa a fonte em Roboto e o locale em pt-BR para a captura não mudar de máquina para
máquina. O app não fixa fonte nenhuma: cada plataforma usa a dela.
