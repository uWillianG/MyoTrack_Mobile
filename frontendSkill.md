# Padrões de interface do MyoTrack

Vale para `app/` — o aplicativo Flutter. Não descreve o que a interface é hoje em todas as
telas; descreve **o que ela precisa ser**. A Hoje (`app/lib/features/home/today_page.dart`) é a
referência construída, e as demais telas se convertem contra este texto.

Onde houver conflito entre este documento e uma tela existente, o documento ganha.

---

## 0. As duas tentativas que falharam, e o que elas provaram

Este documento existe porque duas versões da Hoje foram rejeitadas, e as duas erraram em
direções opostas.

**A primeira** empilhou seis cartões brancos idênticos e acrescentou um painel escuro no topo.
O veredito foi "feio, e com informações demais — o usuário nem sabe o que fazer primeiro". A
tela mostrava cerca de trinta números numa visão só.

**A segunda** cortou até sobrar um anel, um botão e uma linha. Cinco elementos. O veredito foi
"horrível ainda".

Duas densidades opostas, o mesmo resultado. Isso elimina a hipótese fácil:

> **Densidade não era a causa.** As duas telas eram Material 3 com um acento verde e a fonte do
> sistema — a assinatura visual de um projeto Flutter recém-criado. Nenhum rearranjo de
> espaçamento remove esse carimbo.

O que consertou, na ordem do efeito:

1. **Uma fonte própria empacotada.** É o fator isolado de maior impacto, e foi recusado duas
   vezes com o argumento errado (ver §5).
2. **Cor por assunto**, em vez de um acento e cinza.
3. **Um bloco promovido pela hora**, que responde "o que faço primeiro" sem esconder o resto.

---

## 1. A forma: mosaico com um herói

```
   terça, 4 de agosto                       (WG)   ← data + avatar, no lugar da barra

   ╔══════════════════════════════════════════╗
   ║ 🍴 Nutrição                              ║    O HERÓI
   ║ 624 kcal restam                          ║    cor cheia, número grande,
   ║ 1.476 de 2.100 kcal                      ║    uma ação — e só isso
   ║ ▓▓▓▓ ▓▓▓▓▓▓▓▓ ▓▓▓░░░░░░░                 ║
   ║ [        Fotografar refeição        ]    ║
   ╚══════════════════════════════════════════╝

   ┌──────────────────┐ ┌──────────────────┐
   │ 🥚 Proteína      │ │ 🏋 Treino        │        OS LADRILHOS
   │ 62 g             │ │ 55 min           │        cor lavada, um valor,
   │ faltam de 172 g  │ │ Treino B · Peito │        uma linha
   └──────────────────┘ └──────────────────┘
   ┌──────────────────┐ ┌──────────────────┐
   │ 🔥 Semana        │ │ ⚖ Peso           │
   │ 3/4  ●●○●○●●     │ │ 82,5 kg  −0,3 kg │
   └──────────────────┘ └──────────────────┘
   ┌────────────────────────────────────────┐
   │ 🏅 Sequência                         8 │        o ímpar deita
   └────────────────────────────────────────┘
```

**Um herói por tela.** Ele é o único bloco em cor cheia e o único com botão de largura cheia.

**E ele é menor do que quer ser.** A primeira versão do herói ocupava metade da tela: número a
56, respiro de 24, botão de 50, mais uma frase solta sobre proteína. Cada um desses números caiu
um degrau (48 / 20 / 46) e a frase virou ladrilho — o herói perdeu ~60 dp e o mosaico ganhou uma
fileira inteira. **Frase dentro do herói é candidata a virar ladrilho**: como texto ela empurra
o bloco sem ganhar o destaque que um número teria.

**O assunto promovido sai do mosaico.** Nunca aparece nos dois lugares — a duplicação é o que
faz uma tela parecer cheia sem dizer nada a mais.

**O resto do app cabe, em ladrilho.** Foi o que a segunda tentativa errou ao esvaziar: o
produto tem nutrição, treino, progresso, peso, conquistas e fila de revisão, e escondê-los não
deixou a tela bonita — deixou pequena. Um ladrilho custa 146 dp e não disputa atenção com o
herói, porque não tem cor cheia nem ação.

### Ladrilho ou seção: a escolha é de natureza, não de tamanho

Abaixo do herói há duas formas possíveis, e usar a errada desfaz o sistema:

- **`Tile` é para assuntos diferentes.** Na Hoje, treino, semana e peso são coisas distintas,
  cada uma com a própria cor, e o valor de cada ladrilho responde a uma pergunta que não é a
  das outras. Por isso a grade de dois em dois funciona: são peças autônomas.
- **`BlockSection` é para facetas do mesmo assunto.** No diário, calorias, macros, histórico e
  refeições são o **mesmo** número visto de quatro ângulos. Picotá-los em ladrilhos coloridos
  sugeriria uma independência que eles não têm — e a tela voltaria a parecer o painel de
  instrumentos que a primeira tentativa era.

A regra prática: **se dois blocos vizinhos levam ao mesmo lugar e falam do mesmo número, são
seções da mesma coisa, não ladrilhos.**

Daí sai a forma de cada tela: a Hoje é um herói e um mosaico; o diário e o plano são um herói e
três seções, todos em esmeralda porque são todos nutrição.

---

## 2. A hora decide o herói

A regra vive numa **função pura no topo do arquivo**, `pickHero`, e não dentro de um `build`:
decisão de produto enterrada num widget é decisão que ninguém revisa.

| Faixa | Herói |
|---|---|
| **5h–12h** | O treino, se ainda não foi feito. Quem abre o app cedo está decidindo se vai à academia. |
| **12h–20h** | As calorias. É a pergunta que traz a pessoa ao app na fila do restaurante, e a única que ela não responde de cabeça. |
| **20h–5h** | Fechar o dia. Às nove da manhã esse convite pede algo que ainda não aconteceu. |
| qualquer | Sem plano **nem** dieta: a tela inteira vira o caminho para montá-los. |

Fora da faixa, cai para o próximo elegível — sempre há um herói, e ele nunca é um bloco vazio.

**O relógio é um provider.** `nowProvider` (`today_controller.dart`) existe para que as dez da
noite sejam testáveis. Uma tela que muda com a hora e lê `DateTime.now()` direto no `build` é
uma tela cujo teste passa ou falha conforme a hora do CI — e cujas outras caras ninguém confere
nunca.

**Regra geral:** quando um bloco só faz sentido em parte do dia, ele só existe nessa parte.
Isso não esconde funcionalidade — a rota própria e a gaveta do avatar continuam lá.

E a ação muda de forma quando já foi cumprida: treino feito hoje deixa de ter botão e vira
estado. Botão que insiste em algo concluído ensina a ignorar botões.

---

## 3. O app é escuro, e o fundo é preto

`themeMode: ThemeMode.dark` em `main.dart`, e `Palette.dark.surface` é **#000000**.

Não é a variante que o sistema operacional escolhe: é a identidade do produto. Em tela OLED o
pixel preto está desligado, então o fundo desaparece de verdade e os blocos coloridos ficam
suspensos no escuro — é o que faz o mosaico ler como objeto iluminado em vez de retângulo
pintado sobre cinza.

O argumento clássico contra o #000 é real, e duas coisas o desarmam neste app:

- **O texto não é branco puro.** `onSurface` é `#E6EBE8`. O halo que faz a letra vibrar na
  rolagem vem do par #FFFFFF sobre #000000; três degraus abaixo do branco ele some.
- **Nada precisa escurecer.** O sistema empilha para **cima** — ladrilho lavado e herói em cor
  cheia são sempre mais claros que o fundo. A escada de containers existe para diálogo, folha e
  campo, e todos sobem.

**Os lavados do tema escuro subiram um degrau** junto com a troca. Contra o quase-preto anterior
eles já se destacavam; contra o #000 o problema é outro — a borda do ladrilho precisa ser
inequívoca, senão o bloco parece um retângulo de texto solto no escuro.

`AppTheme.light` continua definido, testado e capturado na galeria: desfazer a decisão é trocar
uma linha. Mas **nenhum usuário o vê hoje** — se ele for para ficar assim, apague-o em vez de
manter um tema que ninguém abre.

---

## 4. Cor por assunto

`app/lib/core/design/blocks.dart`. Cada assunto tem uma família com quatro papéis:
`tone` (fundo cheio do herói), `onTone` (texto sobre ele), `wash` (fundo do ladrilho) e `ink`
(número e ícone sobre o `wash`).

| Família | Cor | Assunto |
|---|---|---|
| `Blocks.nutrition` | **esmeralda** `#047857` | Calorias, macros, refeições. É a cor da marca. |
| `Blocks.workout` | **índigo** `#4338CA` | Treino, plano, execução. |
| `Blocks.progress` | **âmbar** `#B45309` | Semana e peso — os dois medem tempo passando, e os dois levam a `/progresso`. |
| `Blocks.award` | **magenta** `#BE185D` | Conquistas. A única família que não descreve rotina, e a única que pode ser festiva. |
| `Blocks.neutral` | superfície | Procedimento: fechar o dia, fila do revisor, passo de configuração. |

### A disciplina que impede o arco-íris

Sem ela isto vira um app infantil:

1. **Um bloco saturado por tela.** Só o herói usa `tone`. Todos os demais usam `wash`, com a
   cor cheia aparecendo apenas no número e no ícone.
2. **A cor pertence ao assunto, não ao estado.** Nutrição é esmeralda aqui e na aba Nutrição.
   Cor que muda de significado entre telas não é sistema, é decoração.
3. **Nunca é o único portador.** Todo bloco tem rótulo escrito e ícone próprio.
4. **Duas peças da mesma cor lado a lado leem como grupo.** Semana e Peso são âmbar de
   propósito — dispensa um título dizendo que são a mesma coisa.

Contraste conferido em todos os pares: `ink` sobre `wash` fica entre 4,6:1 e 6,2:1 no claro e
acima de 8:1 no escuro; `onTone` sobre `tone`, entre 5,0:1 e 7,9:1.

---

## 5. Tipografia

**A fonte é a Manrope, empacotada no APK.** 165 KB, arquivo variável, declarada em
`pubspec.yaml`, licença OFL registrada em `main.dart`.

O projeto usava a fonte de cada plataforma com o argumento de que "fonte que chega pela rede é
fonte que às vezes não chega no subsolo de uma academia". **O argumento é verdadeiro e não se
aplica**: esta viaja dentro do binário, disponível no primeiro frame, offline. A recusa
anterior foi um erro que custou duas rodadas de redesenho.

**Por que a Manrope:** grotesca geométrica de altura-x muito alta, que mantém 12 px legível
numa tela suada; bojo de lado reto, que dá contorno à palavra; algarismos largos e confiantes,
que é o que este app mais desenha grande. Não é Inter, Poppins nem Montserrat.

**Um arquivo variável, não cinco estáticos.** As instâncias estáticas têm 326 KB cada — os
cinco pesos dariam 1,6 MB. O variável entrega 200–800 em 165 KB, e o Flutter interpola o eixo
`wght` a partir do `fontWeight`. Quem confere se está funcionando é a galeria visual: um peso
que não pega sai como texto todo do mesmo tom, e é invisível no código.

### Três tamanhos por tela

| Papel | Estilo |
|---|---|
| O número do herói | `AppTypography.numeric(size: 56)`, peso 800 |
| O número do ladrilho | `AppTypography.numeric(size: 28)` |
| Título / ação | `titleMedium`, `titleSmall` |
| Rótulo e apoio | `labelSmall`, `bodySmall` esmaecido |

**Nada de caixa alta.** Uma versão anterior tinha cinco rótulos em caixa alta espaçada gritando
na mesma tela. Um recurso desses funciona uma vez por tela ou nenhuma; em todo bloco vira
barulho. O rótulo do bloco vai em caixa normal — "Nutrição", "Treino", "Semana".

**Número passa pelo `Fmt`** (`app/lib/core/design/format.dart`): "1.476" e não "1476"; "110 g" e
não "110g"; diferença com o sinal escrito e o traço matemático (−, U+2212), nunca o hífen.

---

## 6. Espaço, raio, movimento

`app/lib/core/design/tokens.dart`. Número que aparece três vezes mora lá.

- **`Space.gutter`** (20) é a margem lateral de tudo.
- **Raio**: herói `Radii.xl` (28), ladrilho `Radii.lg` (24), botão dentro deles mais fechado.
  Arcos iguais brigam.
- **Altura fixa de ladrilho** (146, ou 84 deitado): dois ladrilhos lado a lado com alturas
  diferentes são o detalhe que faz uma grade parecer montada às pressas.
- **Espaço entre blocos**: `Space.sm` (12). O mosaico é uma grade, não uma lista — vãos largos
  o desmontam.
- **`Motion`** — 140 / 220 / 380 ms. Sempre respeite `MediaQuery.disableAnimationsOf(context)`.

---

## 7. Os componentes

`app/lib/core/widgets/blocks.dart`. **Não escreva um `Container` colorido à mão.**

```dart
HeroBlock(
  colors: Blocks.nutrition(brightness),
  label: 'Nutrição',
  icon: Icons.restaurant,
  action: HeroAction(label: 'Fotografar refeição', onPressed: ...),
  child: HeroFigure(value: '624', unit: 'kcal restam', colors: colors,
                    detail: 'Faltam 62 g de proteína'),
)

Tile(
  colors: Blocks.workout(brightness),
  label: 'Treino',
  icon: Icons.fitness_center,
  value: '55 min',
  detail: 'Treino B · Peito e tríceps',
  footer: /* opcional: os pontos da semana */,
  onTap: ...,
)

TileGrid(tiles: [...])   // duas colunas; o ímpar que sobra deita sozinho

BlockSection(
  colors: Blocks.nutrition(brightness),
  label: 'Macros do dia',
  icon: Icons.pie_chart_outline,
  trailing: 'média 1.904 kcal',      // opcional
  padding: EdgeInsets.zero,          // zero quando o conteúdo é lista: o fio precisa
  child: /* medidores, gráfico, lista */,   // encostar nas bordas
)

BlockMeter(colors: colors, label: 'Proteína', value: '110 / 172 g', ratio: 0.64)

// `onEdit` torna a seção inteira tocável e põe um lápis no canto do rótulo. A seção toda,
// e não só o lápis: um alvo de 24 dp num canto obriga a mira, e a pessoa já está olhando
// para o conteúdo que quer mudar.
BlockSection(..., onEdit: () => _abreAFolhaDoGrupo())

MealBar(                              // a assinatura da nutrição
  slices: MealBar.slicesOf(mealKcal: [...], consumed: 1476, target: 2100),
  colors: colors,
  onTone: true,                       // false sobre fundo lavado
)
```

`EmptyState` (`app/lib/core/widgets/empty_state.dart`) continua para tela vazia — o ícone vai
dentro de um disco, nunca solto, senão lê como avaria.

**Componente novo só entra quando o mesmo desenho aparecer em três lugares.** Já foram criados
e removidos um `InkPanel`, um `SectionCard` e um `QuietRow`: cada um nasceu de uma tentativa que
não vingou, e abstração que sobrevive à ideia que a gerou é peso morto.

### Todo texto de um bloco é conteúdo, e todo conteúdo encolhe

O `label`, o `trailing` e a `unit` **não são constantes**: no diário o label é a data do dia
aberto; no Progresso o trailing é "maior carga por exercício" e a unidade é "de 12 semanas".
Cada um deles já estourou a linha em 360 dp, um de cada vez, conforme uma tela nova passou a
escrever algo mais longo ali.

Os três moram em `Flexible`/`Expanded` com `ellipsis`. **Quando um componente compartilhado
recebe texto de fora, o texto encolhe** — não há rótulo curto o suficiente para a próxima tela.

E rótulo de controle segue a mesma regra ao contrário: "4 semanas / 12 semanas / Tudo"
estourava o segmentado, e virou "1 mês / 3 meses / Tudo" — o recorte exato fica no rótulo de
cada bloco, que é onde ele precisa ser preciso.

### `Material`, e não `Container`, para fundo pintado

Um fundo pintado por `BoxDecoration` fica **acima** do Material mais próximo, e todo respingo de
toque dos filhos desaparece atrás dele. O Flutter chega a avisar quando um `ListTile` cai nessa
armadilha — foi assim que apareceu, duas vezes.

### Eixo de gráfico: o passo vem antes do formato

O eixo de peso saía "84 · 84 · 83 · 83 · 82 · 82". O `fl_chart` escolhe passos menores que a
unidade quando a faixa é estreita — e peso corporal tem faixa estreita por natureza —, e
arredondar para inteiro fazia dois rótulos diferentes virarem o mesmo texto, um sobre o outro.
**Calcule o passo, e derive a casa decimal dele.**

---

## 8. Os quatro estados

### Carregando
**Esqueleto do tamanho exato do conteúdo**, nunca a tela vazia. O mosaico tem
`_MosaicSkeleton`: um bloco cinza com a altura do herói e dois ladrilhos. Sem isso a tela nasce
vazia e salta quando a resposta chega — e o salto é mais visível que a espera. Trocar o herói
depois faria a tela inteira mudar de cor na cara do usuário.

### Erro
Fica no lugar do bloco, com o que aconteceu e "Tentar de novo". Uma chamada falhando não
derruba as outras: o herói cai para o assunto que ainda respondeu.

**Erro é "não sei", nunca "não existe".** Foi um defeito real: sem rede, as consultas voltavam
nulas e a tela anunciava os primeiros passos a quem usa o app há meses, dizendo que o perfil e o
plano dele não existiam. **Toda derivação de estado a partir de `valueOrNull` precisa checar
`hasError` antes de concluir ausência.**

### Vazio
`EmptyState`, com texto que é convite e não lamento.

### Primeiro acesso
A regra "bloco só aparece quando tem o que dizer" está certa e, sozinha, entrega uma tela em
branco a quem acabou de criar a conta — **quem chega ao produto encontra o pior estado dele.**

Na Hoje, o herói inteiro é substituído: "Vamos montar seu plano." e três passos numerados.

- **Numere só quando for sequência de verdade.** Ali é — treino e dieta nascem do perfil.
- **Passo cumprido vira registro, não destino**: perde o `onTap` e ganha o visto. Alvo de toque
  que não leva a lugar novo ensina a desconfiar dos outros.
- **Faltando só um dos passos**, ele vira um ladrilho neutro e o app continua servindo o que já
  existe. O onboarding de tela cheia é para quem não tem nada.

---

## 9. Desenho a lápis

**`StrokeCap.round` transborda meia espessura para cada lado.** Com traço de 14 dp num raio de
101, cada ponta come 0,069 rad — mais que uma fresta de 3°. Um anel segmentado saiu liso por
isso, com os segmentos existindo no código e não na tela. Quem desenha fresta entre segmentos
arredondados soma `(strokeWidth / 2) / radius` de cada lado à conta.

Barra ou anel de progresso **satura em 100%**: passar da meta não merece uma segunda volta, e o
número já conta o resto — ele zera.

**Todo `CustomPaint` e todo desenho declara `Semantics`.** É invisível para o leitor de tela. A
barra de refeições diz "80 por cento da meta, em 3 refeições"; os pontos da semana dizem quantos
dos sete tiveram treino.

---

## 10. O texto da interface

- **Voz ativa, e a mesma palavra do começo ao fim.** Dois caminhos para o mesmo recurso usam o
  mesmo rótulo — "Fotografar refeição" no herói e na folha de captura rápida. Vocabulário que
  muda entre dois caminhos faz o usuário achar que são coisas diferentes.
- **E dois rótulos iguais para coisas diferentes é o erro oposto**, igualmente caro: o botão do
  herói dizia "Registrar refeição" enquanto o flutuante dizia "Registrar".
- **Nomeie pelo que a pessoa controla**, não pela implementação. "Anotar peso", não "Registrar
  medição".
- **Erro diz o que houve e o que fazer**, sem pedir desculpa: "Peso guardado no aparelho. Sobe
  quando houver rede."
- **Específico ganha de esperto.** "3/4 treinos" diz se a semana vai bem; "3 treinos" não diz
  nada. "4 planos · há 12 dias" é outra urgência que "4 planos".

---

## 11. O piso de qualidade

- **44 dp de alvo de toque**, 50–52 no botão principal — este app é usado com a mão suada.
- **4,5:1** em texto, **3:1** em elemento gráfico.
- **Fonte do sistema ampliada não quebra a tela.** Número grande usa `FittedBox(scaleDown)` com
  `maxLines: 1`; texto de ladrilho tem `maxLines: 2` e `ellipsis`.
- **Celular pequeno (360 × 800) é o alvo de teste**, não o grande.

---

## 12. Como avaliar e verificar

### A galeria visual

```bash
cd app && flutter test --update-goldens --tags gallery --run-skipped test/design
```

Escreve PNGs em `app/test/design/goldens/`. Não é teste de regressão — é a bancada onde o design
é avaliado. **Olhe as imagens.**

Toda tela convertida entra na galeria **nos dois temas**, e mais:

- **cada cara que a tela tem.** A Hoje tem quatro capturas por tema (manhã, tarde, noite,
  primeiro acesso), porque avaliar só uma seria avaliar um quarto do desenho.
- **o estado de primeiro acesso**, sempre. É o estado que ninguém olha e o primeiro que o
  usuário vê.
- **a lista cheia, quando a tela tem lista.** A vazia julga o convite; a cheia julga o ritmo
  entre os itens, e é onde aparecem os estouros de linha e os blocos que empurram o conteúdo
  para fora da dobra.
- **o caso torto junto com o feliz.** O histórico de execução leva uma análise avaliada e uma
  que não deu para avaliar: uma galeria só de caminho feliz não é bancada de design nenhuma.

### Antes de abrir o PR

```bash
cd app && dart format lib test && flutter analyze --fatal-infos && flutter test
```

### Lista de revisão

- [ ] Escrevi a pergunta e a ação da tela, cada uma em uma frase
- [ ] Um herói, e o assunto dele **não** se repete no mosaico
- [ ] Um bloco saturado; todo o resto lavado
- [ ] Toda cor tem rótulo escrito e ícone
- [ ] Três tamanhos de texto, nenhum em caixa alta
- [ ] Todo número passou pelo `Fmt`
- [ ] Espaço, raio e altura saem dos tokens
- [ ] Os quatro estados existem, e erro não vira "não existe"
- [ ] O que depende de relógio lê `nowProvider`, não `DateTime.now()`
- [ ] `Semantics` em tudo que é desenhado a lápis
- [ ] Cabe em 360 × 800 com a fonte ampliada
- [ ] Entrou na galeria, em todas as caras e nos dois temas, e eu olhei

---

## 13. Preencher e consultar são tarefas diferentes

O Perfil era um assistente de cinco etapas, e a **aba Perfil era esse assistente** — inclusive
para quem já tinha perfil. Mudar os dias de treino custava cinco toques: entrar, avançar até a
etapa certa, mudar, avançar até o fim para achar o botão que salva. E a única aba do app que
nunca mostrava o seu assunto era justamente a chamada "Perfil".

**Assistente é a forma certa para preencher a primeira vez e a forma errada para consultar e
editar.** Uma tela que tenta servir às duas é ruim nas duas. A regra:

- **Sem dado** → cadastro: os grupos numa página só, e o botão no fim.
- **Com dado** → resumo: o que está salvo, agrupado, e cada grupo abre sozinho numa folha.

E as duas usam **os mesmos widgets de campo** (`profile_editors.dart`). É o que faz o app ter
uma forma só para aprender: quem preencheu "Dias de treino" no cadastro reencontra o mesmo
controle, no mesmo lugar dentro do grupo, quando volta meses depois.

### Folha edita rascunho, não o estado compartilhado

A folha de edição guarda uma **cópia** do formulário e só a entrega no "Salvar". Sem isso, cada
toque num chip já aparecia no resumo atrás da folha — e fechar sem salvar deixava a tela
mostrando um valor que o servidor não tem.

### Grupo vazio diz o que a ausência significa

"Academia completa" é o efeito de não marcar equipamento nenhum; "Nenhuma área sensível" é o
efeito de não marcar lesão. Em branco, os dois pareceriam dado faltando — e a pessoa não teria
como decidir se precisa mexer.

### Rótulo curto, explicação do que está escolhido

Os três chips de biotipo traziam a definição dentro do próprio rótulo ("Ectomorfo (magro,
dificuldade de ganhar peso)") e cada um ocupava uma linha inteira, cortado no fim. Rótulo de
três palavras cabe numa linha; a definição do **escolhido** cabe embaixo, sem competir com as
outras duas. Vale para toda escolha: o controle mostra a opção, não o manual dela.

### Cor só onde ela já significa alguma coisa

A primeira tentativa deu uma família a cada grupo do perfil e errou duas vezes: saíram quatro
blocos índigo seguidos (equipamento e lesões também alimentam o treino), e "Você" ficou em
âmbar — que no resto do app significa **progresso**. Ficaram coloridos só Treino e Alimentação,
cujas famílias o usuário já aprendeu na Hoje; o resto é neutro.

---

## 14. Fundir duas telas: o que a fusão cobra

O **Progresso** absorveu as **Conquistas**. As duas respondiam "estou evoluindo?" e obrigavam a
pessoa a escolher entre conferir o número e ver o que ele rendeu. `/conquistas` virou um
redirect — a rota fica de pé porque link de e-mail e notificação apontam para ela.

Fundir telas cria riscos que nenhuma delas tinha sozinha, e um deles mandou no desenho:

> **Abrir o Progresso marca as conquistas como vistas.** Quem foi lá só olhar o peso gastaria a
> comemoração sem ver nada.

Daí a regra: **o que é consumido ao ser visto mora acima da dobra.** A comemoração
(`AchievementsHighlight`) fica logo abaixo da manchete e só existe quando há novidade; a lista
inteira (`AchievementsSection`) fica no fim, onde inventário deve ficar. Marcar como visto algo
que exigiria rolagem seria enganar quem veio comemorar.

### A manchete pode sair do perfil, e não só do relógio

Na Hoje quem promove é a hora; no Progresso é o **objetivo** (`pickProgressFocus`): emagrecer
abre no peso, hipertrofia no volume, condicionamento na constância. Antes os três viam a mesma
pilha de gráficos e dois deles tinham de rolar até achar o seu.

Como o `pickHero`, é função pura no topo do arquivo e recebe o valor em vez de ler o provider —
é o que faz a tabela inteira caber num teste.

### Um comentário que mentia

`progress_page.dart` afirmava que o relatório semanal ficava **acima** dos gráficos "porque é
leitura, não consulta", e o código o punha depois de tudo. Comentário e código divergiram em
silêncio, e quem lesse o arquivo acreditaria no comentário. O relatório subiu — ele é o único
bloco que já vem interpretado.

---

## 15. A manchete pode trocar de assunto dentro da mesma tela

No modo treino (`/treinar`) o herói é a **série** enquanto ela acontece e vira o **cronômetro**
quando o descanso começa. A regra: **o que muda sozinho ganha o bloco enquanto está mudando.** É
a única coisa da tela que se altera sem o usuário tocar, e é para vê-la que ele olha o aparelho
apoiado no banco a dois metros.

**Campo de texto não entra em bloco de cor cheia.** A caixa perde o contraste que o tema garante
no fundo normal, e digitar carga com a mão suada é a operação que menos pode falhar ali. Os
campos ficam numa seção abaixo, sempre no mesmo lugar.

**Selo dentro de bloco cheio herda a cor do bloco.** O `ReviewBadge` saía esmeralda dentro do
herói índigo do treino — uma família no meio de outra. Com `onTone` ele vira um véu translúcido
sobre o próprio bloco, e o recado passa a ser dado pelo ícone e pelo texto, não pelo matiz.

**Três telas parecidas podem continuar três.** `/treino` (consulta), `/treinar` (execução) e
`/registrar` (lançamento) lidam todas com séries e cargas, e fundi-las era tentador. O uso é que
difere: sentado escolhendo, de pé com cronômetro correndo, sentado lançando o que já fez. Uma
tela com três modos poria o modo errado na frente da pessoa no momento errado.

---

## 16. Quando o herói é o trabalho, e não o resultado

A análise de refeição (`meals/meal_analysis_page.dart`) é a primeira tela cujo assunto é uma
**operação assíncrona**: fotografar o prato, esperar a IA, corrigir a estimativa. O herói dela
não descreve um número do usuário — descreve o estado do trabalho. Parado, é o convite com
"Fotografar prato"; correndo, é o cronômetro do progresso. É o mesmo mecanismo do modo treino
(§15), aplicado a um trabalho que acontece no servidor em vez de no banco da academia.

**O resultado não sobe para o herói.** O desenho escolhido na conversa mostrava a manchete
virando "pronto → resultado" no fim, e ela não foi construída assim, de propósito: a refeição
analisada é salva sozinha e continua **editável item por item**. Promovê-la ao herói daria dois
caminhos — ou ela apareceria duas vezes, no bloco e na lista, ou apareceria uma vez sem os
botões de porção que são a razão de ela estar na tela. A regra que fica: **um resultado que
ainda se edita mora onde se edita.** O herói fica com o que só se olha.

### Dizer o que a IA não faz é parte do convite

A tela vazia diz "A IA estima as calorias e os macros — **e a estimativa fica editável, item por
item**, antes de contar no seu dia". A segunda metade da frase é a que importa: sem ela, um
número errado vira motivo para desinstalar em vez de motivo para tocar em "Ajustar".

E **a frase some quando já houve uma foto.** Com histórico, o herói passa a contar quantas
refeições foram analisadas. Explicação repetida a cada abertura para quem já entendeu é ruído —
o primeiro acesso (§8) é um estado, não um enfeite permanente.

### Preferência não abre a lista, fecha

O interruptor da análise ilustrada estava entre o herói e as refeições e empurrava para baixo
justamente o que a pessoa veio ver. Ele é ajuste da **próxima** captura: vai para o fim da
lista. **Ajuste de comportamento futuro fica depois do conteúdo presente.**

### O estado vira texto no rótulo da seção

"Fora do diário" era um `Chip` e "você ajustou" era um lápis de 16 dp com tooltip — dentro de um
bloco que já é uma moldura, um chip é moldura dentro de moldura, e tooltip no celular não abre.
Os dois viraram o `trailing` do `BlockSection`. Estado é texto.

### A fonte do teste é quadrada, e isso é um favor

O teste de widget renderiza sem a Manrope: cada glifo vira um quadrado do tamanho da fonte, e o
texto sai bem mais largo que no aparelho. A linha "Ajustar · Tirar do diário" passava, com a
fonte real, e estourava 132 px no teste. Não é artefato — é o que acontece com o corpo de texto
ampliado pela acessibilidade. **`Flexible` dos dois lados e `spaceBetween`, nunca `Spacer` entre
botões de texto:** o `Spacer` empurra o estouro para fora da vista em vez de deixar o botão
encolher.

### O número do herói é o que não está em nenhum cartão

A metade de vídeo (`videos/video_analysis_page.dart`) tem um número óbvio para a manchete — a
nota da última execução —, e ele é o errado: essa nota continua no cartão dela, ao lado do
vídeo e dos pontos que a explicam, e o herói a mostraria duas vezes. O bloco leva a **média das
notas** (`scoreAverage`, pura e no topo do arquivo), que só o conjunto sabe dizer e responde
"estou melhorando?" — a pergunta pela qual se volta à tela.

A regra geral: **quando a lista já mostra os resultados, a manchete carrega o agregado.** É a
mesma disciplina do "assunto promovido sai do mosaico", aplicada a um número.

E o agregado conta o que entrou nele, não o tamanho da lista: com duas análises e uma nota
nula, "média de 2 execuções" é uma média que o usuário não consegue refazer de cabeça.

### Nota é grandeza, não semáforo

A nota saía num chip que mudava de cor — verde acima de 80, âmbar no meio, vermelho abaixo de
60. É cor por estado, que o §4 proíbe: a mesma peça passava a ter três significados, e a
família do treino sumia justamente no dado principal da tela. Agora é número grande em `ink`
mais barra proporcional: **quem dá o recado é o tamanho, não o matiz.**

`score` nulo não vira zero em lugar nenhum — nem no cartão, nem na média. "Não deu para
avaliar" é uma afirmação sobre o vídeo; zero seria uma afirmação sobre o corpo de quem gravou.

### A instrução que decide o sucesso vem antes do gesto, não depois

Gravar exigia duas folhas em sequência — exercício numa, origem do vídeo noutra —, e o
enquadramento ("de lado, corpo inteiro no quadro, até 30s") estava enterrado como subtítulo na
segunda. É a instrução que decide se o vídeo vai ser avaliável, e ela chegava depois de a
decisão estar tomada. Subiu para o herói, como faixa sobre a cor cheia; a folha de origem
sumiu (gravar é a ação do bloco, galeria é o botão de texto), e só o exercício — que o servidor
exige — ainda pergunta.

### Erros e acertos são dois grupos com nome, não uma lista colorida

As ocorrências e os pontos corretos vinham na mesma coluna, distinguidos por cor de ícone —
lê-se como registro de log. Separados sob "O que corrigir" e "O que já está bom", viram duas
respostas: o que mudar na próxima série e o que não mexer. O vermelho do ícone de erro é a
única cor fora da família na tela, e não anda sozinho: forma de ícone própria e título escrito.

### Espaço de mídia se paga com mídia

O lugar do vídeo era um 16:9 de largura cheia — um terço da tela por cartão, cinza, empurrando
a nota e as correções para fora da vista. Virou uma faixa de 96 dp com "Ver com o esqueleto";
ao tocar, o player abre na proporção verdadeira do arquivo. **Um espaço reservado não deve
custar o espaço que o conteúdo custaria** — só o suficiente para dizer que ele existe.

Ele também não baixa sozinho: cada vídeo são alguns MB, e uma lista que carrega todos ao abrir
gasta o pacote de dados de quem está na academia. O toque é o consentimento.

### Lista preguiçosa: o teste precisa rolar

Os cartões do histórico carregam mídia, então a lista é preguiçosa de propósito e o que está
abaixo da dobra **não existe** na árvore. Um `find.text` de segundo cartão falha por um motivo
que não é o que o teste quer medir — use `scrollUntilVisible` antes.

### Data por extenso mora no `Fmt`

`Fmt.dayMonth`, `Fmt.weekdayDayMonth` e `Fmt.time` (`core/design/format.dart`). Os nomes de mês
estavam escritos à mão na Hoje e no diário pelo mesmo motivo — `DateFormat` com locale exige
`initializeDateFormatting`, e num teste de widget que não o chama a data sai **em inglês em vez
de falhar visivelmente**. A terceira cópia é o que os trouxe para o `Fmt`, onde já moravam as
regras de número: formatação é design, e design mora num lugar só.

---

## 17. Uma conversa não tem manchete

O coach (`coach/coach_page.dart`) é a **única tela convertida sem herói**, e é de propósito. O
bloco de cor cheia promove um assunto entre vários; numa conversa não há vários — a conversa é a
tela inteira, e um bloco no topo tomaria o espaço das mensagens para repetir o que a barra de
título já diz.

Ele aparece num caso só: **enquanto não há conversa**. Aí o bloco é o que a tela tem — diz o que
o coach sabe e o que ele não é — e some para sempre na primeira pergunta. A regra que fica:
**o herói pode ser o estado vazio**, quando o cheio não tem lugar para ele.

### Sem família, e o saturado é o que você disse

O coach fala de treino, de dieta e de constância. Pintá-lo de esmeralda ou de índigo diria que
ele pertence a um desses assuntos, então ele é neutro (§4). Isso libera o único destaque da tela
para o balão **do usuário**: quem escreve não é um assunto, e por isso nenhuma das quatro
famílias serve — o contraste sai do neutro, que no escuro é claro e no claro é escuro.

O do coach fica lavado. Ele fala muito mais, e um mural de balões cheios cansaria antes da
terceira resposta.

### O lavado neutro do tema claro estava fraco, e o balão provou

Uma seção tem rótulo e ícone ancorando a forma; um balão não tem nada — é uma mancha solta no
meio da tela. Foi ali que ficou impossível não ver: `surfaceContainerHigh` (#F0F2F1) sobre a
página (#F7F8F8) são sete pontos de diferença, e no Perfil as seções sem cor já apareciam como
retângulos fantasmas ao lado das coloridas.

A correção foi **na fonte** — `Blocks.neutral` sobe um degrau no claro — e não na tela. No
escuro fica como estava: contra o #000 qualquer superfície se afirma, e subir mais faria o
neutro gritar mais alto que as famílias, invertendo a hierarquia.

Vale como método: quando uma tela nova expõe um defeito do sistema, o conserto é no sistema. A
correção local teria deixado o Perfil errado do mesmo jeito.

### Lista de conversa é invertida

Com três mensagens, uma lista normal encosta tudo no topo e deixa meia tela de vazio entre a
última resposta e o campo de escrever — como se a conversa tivesse acabado e o resto fosse
outra coisa. Com `reverse: true` ela se apoia no compositor, e mensagem nova entra sem mexer na
posição de rolagem.

O preço é que a ordem inverte: nessa lista, **"depois" significa "acima"**. A conversa é
percorrida do fim para o começo, a régua de dia sai depois da primeira mensagem dele, e o
`_toBottom` anima para `0`, não para `maxScrollExtent`.

### A régua entre um dia e outro

Uma conversa com o coach dura meses. Sem a separação, a resposta de três semanas atrás encosta
na pergunta de hoje — que é como um conselho antigo volta a ser lido como atual. `daySeparator`
é pura, no topo do arquivo, e devolve "Hoje", "Ontem" ou a data.

### Sugestão que não é tocável é trabalho em dobro

O estado vazio já sugeria três perguntas, mas como texto: ler e ter que redigitar. Agora são
linhas de uma seção, cada uma com ícone e seta — o toque manda a pergunta.

---

## 18. Uma fila se lê pela ponta

A revisão (`reviews/review_page.dart`) é a primeira tela em que o usuário age sobre o plano de
**outra pessoa**, e a primeira cuja família de cor **muda dentro da própria tela**: a fila de
treinos é índigo, a de dietas é esmeralda. Não é contradição com o §4 — o segmentado ali troca
de assunto, não de estado, e a regra do §17 (*quem manda na cor é o destino do dado*) diz
exatamente isto. Treino revisado vira plano de treino; dieta revisada vira plano alimentar.

**A manchete promove a ponta, não o total.** `oldestPending` é pura e no topo do arquivo: o
número grande é quantos esperam, o detalhe é a idade do mais antigo, e a ação abre justamente
esse. Sem isso o revisor abre o primeiro da lista — que é só a ordem em que o servidor
respondeu —, e o plano esquecido continua esquecido.

Item sem data fica **fora** da comparação em vez de contar como antiquíssimo: data ausente é
falta de informação, não urgência. Mas a fila inteira sem data ainda precisa de uma ponta,
senão a manchete perde a ação.

### Numa fila, o rótulo colorido carrega a espera

A primeira versão pôs o e-mail do aluno no rótulo e a idade no `trailing`. Ficou errado por
dois motivos: `marina.alves@exemplo.com` disputava espaço e perdia o domínio, e a espera — que
é a dimensão pela qual se decide o que abrir — virou nota de rodapé. Invertido: **o rótulo é
"Esperando há 6 dias"**, e o e-mail desce para o corpo, com a largura toda.

**Regra geral: o rótulo do bloco carrega a dimensão pela qual a lista é percorrida.** Num
histórico é a data; numa fila é a espera.

### Nem todo toque é edição

`BlockSection.onEdit` desenhava sempre um lápis e anunciava sempre "Editar". Aqui a seção
**abre** um plano para uma decisão — e um lápis prometeria que o revisor pode reescrever a
dieta de outra pessoa, que é justamente o que ele não pode. O widget ganhou `actionIcon` e
`actionVerb`; o padrão continua lápis/"Editar".

### O que o servidor já disse não se repete

O nome do plano vem gerado como "Gerado em 2 de agosto · versão 2" — a data e a versão escritas
por extenso, os dois campos que a linha já mostra em coluna própria. Mostrá-lo era a mesma
informação três vezes na mesma seção; saiu.

### Condição de botão é `helperText`, não `hintText`

"Obrigatória ao pedir mudanças" estava como dica do campo de observação, e dica some no
primeiro caractere digitado — exatamente quando a condição passa a importar. `helperText` fica.

---

## 19. O que falta converter

Convertidas: **Hoje** (`today_page.dart`), **Nutrição** — diário (`diary_page.dart`) e plano
(`diet_plan_page.dart`) —, **Perfil** (`profile_page.dart`), **Progresso**
(`progress_page.dart`, que absorveu as conquistas), **Treino** — plano
(`workout_plan_page.dart`), modo treino (`workout_mode_page.dart`) e registro
(`log_session_page.dart`) —, a **Analisar** inteira — refeição
(`meals/meal_analysis_page.dart`, esmeralda) e execução (`videos/video_analysis_page.dart`,
índigo) —, o **Coach** (`coach/coach_page.dart`, neutro) e a **Revisão**
(`reviews/review_page.dart`, índigo ou esmeralda conforme a fila).

O Perfil também absorveu a gaveta do avatar: `accountDestinations`
(`features/home/account_destinations.dart`) alimenta a folha **e** a aba, de um lugar só. Duas
listas escritas à mão divergem na primeira tela nova, e aí o mesmo app passa a ter dois mapas
diferentes de si mesmo.

O que a Nutrição decidiu, e vale para as próximas:

- **~~As duas metades de uma aba compartilham a família.~~ Quem manda na cor é o destino do
  dado.** Escrito assim ao converter a Nutrição, onde diário e plano são os dois esmeralda, o
  enunciado parecia geral e não era: ele descrevia o caso em que as duas metades **falam do
  mesmo assunto**. Na aba Analisar o mesmo segmentado hospeda duas telas que alimentam
  assuntos diferentes — a foto do prato vira caloria no diário (esmeralda), o vídeo vira
  correção de execução no treino (índigo) —, e pintá-las iguais só porque dividem um controle
  faria a cor descrever o widget em vez do assunto. O segmentado é mobília; ele não define
  família.
- **O mesmo número pode ter leituras diferentes em telas diferentes, e isso se declara.** A
  Hoje mostra o que **resta** ("624 kcal restam") porque só faz sentido hoje; o diário mostra o
  **consumido** ("1.476 kcal") porque é navegável para trás, e "restam 624" num sábado que já
  acabou não significa nada.
- **A ação principal sai do rodapé e vira a ação do herói.** O botão de gerar dieta estava
  preso embaixo, competindo com a barra de navegação e aparecendo até enquanto o plano
  carregava, quando não havia nada para regerar.
- **`HeroAction` aceita `onPressed` nulo** — é como o botão fica enquanto a ação já está em
  andamento, e o rótulo conta o que acontece ("Gerando…").

Em ordem de retorno, o que falta:

| Tela | Família | O que fazer |
|---|---|---|
| `features/billing/billing_page.dart` | neutro | Conversão direta |
| `features/privacy/account_page.dart` | neutro | Conversão direta |
| `features/auth/` | — | Tem `auth_scaffold` próprio; alinhar tipografia e alvo de toque |
| `features/splash/splash_page.dart` | — | Trivial |

Duas dessas são destinos da aba Perfil (`accountDestinations`): quem toca num item da lista
sai de uma tela nova e entra numa antiga, que é a costura que mais se sente.

**Um caso meio-termo:** `checkin/day_close_page.dart` pegou a Manrope, o fundo preto e o `Fmt`,
mas nunca recebeu o vocabulário de blocos — os cartões dele são forma própria. Como é um fluxo
modal com ritmo próprio, dá para argumentar que está bom; pelo critério de uma linguagem só,
conta como pendente.

Converta uma por vez e gere a galeria a cada uma. Meia conversão é pior que nenhuma: duas telas
em padrões diferentes é a sensação de app costurado que este documento existe para eliminar.

### Cuidado com o fixture compartilhado

`test/features/home/home_test_harness.dart` alimenta as quatro abas de uma vez, e o dado dele é
lido por mais gente do que parece: encher `DiaryDay.week` para o gráfico do diário mudou a
avaliação de conquistas e quebrou testes que não têm nada a ver com nutrição.

Quando um campo novo do fixture pode mudar uma regra de negócio, ele entra **como parâmetro
opcional com o padrão antigo**, e quem precisa dele pede — foi assim que `week` e `meals`
entraram. E o valor tem de ser um que o servidor realmente emite: um `calorieGoal` inventado
fez a galeria capturar "MildDeficit" cru na tela, que é o comportamento correto de `DietLabels`
para valor desconhecido e não o que se queria avaliar.
