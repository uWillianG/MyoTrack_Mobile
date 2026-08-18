# Design system

Sete arquivos, e a regra de quando mexer em cada um.

| arquivo | o que decide |
|---|---|
| `palette.dart` | as duas paletas, escritas à mão |
| `typography.dart` | a escala de texto e o estilo dos números |
| `tokens.dart` | espaço, raio, sombra e duração |
| `format.dart` | como um número aparece escrito |
| `blocks.dart` | a cor de cada assunto — nutrição, treino, progresso, conquista |
| `materials.dart` | o vidro: véu, aresta e borrão |
| `springs.dart` | a física dos gestos — mola, projeção de momento, elástico |

`core/theme.dart` liga os quatro primeiros ao Material e ajusta cada componente. Uma tela não
deveria precisar de mais nada além de `Theme.of(context)` e destes tokens.

## As três decisões que sustentam o resto

**1. A paleta é autoral, não gerada.** `ColorScheme.fromSeed` tinge os neutros com a cor da
semente: com um verde de marca, o fundo saía menta pálido, o cartão saía menta um pouco menos
pálido, e nada tinha profundidade. Aqui os neutros são neutros e o esmeralda aparece só onde
significa alguma coisa — ação primária, progresso, estado ativo, número que melhorou.

O esmeralda da marca (`#059669`) continua sendo o dos e-mails e do frontend React. Ele
escurece um degrau no tema claro (contraste sobre branco) e clareia no escuro.

**2. A superfície é vidro, e a cor vive na tinta.** Cada bloco já teve um fundo pintado na cor
do assunto, e a tela cheia deles era um mosaico: sete áreas de cor competindo, nenhuma
superfície. Hoje o fundo é sempre o mesmo material translúcido (`materials.dart`) e o matiz da
família aparece no rótulo, no ícone, no traço do anel e no botão da ação — **o número grande de
um bloco é branco**. Quem separa as peças é profundidade e escala, não área de cor.

O material tem três camadas: o véu (branco a 5,5% no escuro), a aresta especular de 1 px que
nasce clara no topo e some na base, e o borrão — que é opcional e caro. Borrar atrás de um
cartão com fundo liso é gastar uma passada de composição para não mudar pixel nenhum; só a
moldura do app, por onde o conteúdo passa rolando, pede borrão de verdade.

`surfaceTintColor` continua transparente em tudo: o véu de cor primária que o Material 3 pinta
sobre superfícies elevadas é o que mais denuncia um tema gerado.

**2b. Gesto é mola, não curva.** Tudo que o dedo pode pegar — o anel da Hoje, o carrossel de
dias, a barra do vídeo — usa `springs.dart`: mola descrita por resposta e quique, destino
decidido pela **projeção do momento** (não pela distância percorrida) e limite que resiste em
vez de travar. Animação de duração fixa não sabe ser interrompida, e o instante em que o
usuário toca no que está se movendo é justamente onde a interface parece um computador
ocupado.

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
- Cor cheia é ação. Com as superfícies em vidro, o botão da família (`BlockColors.ink` com
  texto em `wash`) passou a ser a coisa mais saturada da tela — que é onde a saturação deve
  estar. Se a coisa mais berrante da tela não for o que se quer que a pessoa faça, algo está
  trocado.
- Texto dentro de um bloco de família: `onGlass` para o corpo, `ink` para o rótulo e o número
  que é o assunto. `onTone` é outra coisa — é o que vai sobre `tone`, a cor cheia de um
  controle (dia selecionado, balão da própria mensagem).

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
