import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/router.dart';
import '../../core/widgets/glass_segmented.dart';
import '../../core/widgets/pressable.dart';
import 'auth_controller.dart';
import 'data/social_sign_in.dart';
import 'widgets/auth_message.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/password_rules.dart';

/// Entrar e criar conta — a mesma tela, e é de propósito.
///
/// **Por que uma tela só, e não duas.** Entrar e cadastrar-se compartilham o e-mail, a senha e
/// os botões de provedor: são o mesmo formulário com dois campos a mais. Separá-los em rotas
/// obrigaria quem errou o alvo a sair da tela e voltar, perdendo o que já digitou — e faria a
/// escolha mais comum do app depender de uma navegação.
///
/// **Por que o modo troca por segmentado, e não por um link no rodapé.** O link dizia "Não
/// tenho conta. Criar agora" na base de uma tela que, no cadastro, rola: quem chegou para se
/// cadastrar precisava ler o formulário inteiro de login antes de descobrir que existia outro
/// caminho. O segmentado põe as duas opções no topo, ditas por inteiro, e a pastilha que corre
/// entre elas é o mesmo controle que a Nutrição e a Análise já usam.
///
/// **A troca de modo cresce, não corta.** Os campos exclusivos do cadastro — nome, regras e
/// confirmação — abrem e fecham em altura, com o conteúdo desaparecendo junto. É a leitura
/// honesta do que acontece: não são duas telas que se substituem, é um formulário que ganha
/// campos. Justamente por isso o modo *não* se troca por arrasto lateral, que prometeria duas
/// páginas lado a lado onde há uma só.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

enum _Mode { login, register }

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _displayName = TextEditingController();

  /// O foco vive aqui porque o formulário é uma sequência: cada campo entrega o próximo, e o
  /// último dispara o envio. Sem isso a tecla "seguinte" do teclado não leva a lugar nenhum e a
  /// pessoa precisa mirar o campo de baixo com o polegar a cada linha.
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();

  _Mode _mode = _Mode.login;
  bool _obscurePassword = true;

  bool get _isRegister => _mode == _Mode.register;

  /// As regras aparecem quando a senha entra em jogo — no foco ou no primeiro caractere — e não
  /// antes. Cinco itens desmarcados recebendo quem abriu o cadastro leem como uma lista de
  /// exigências; os mesmos cinco marcando enquanto se digita leem como ajuda.
  bool get _showRules =>
      _isRegister && (_passwordFocus.hasFocus || _password.text.isNotEmpty);

  @override
  void initState() {
    super.initState();
    // O painel de regras aparece e some com o foco, então o foco precisa repintar a tela.
    _passwordFocus.addListener(_onPasswordFocusChanged);
  }

  @override
  void dispose() {
    _passwordFocus.removeListener(_onPasswordFocusChanged);
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _displayName.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  void _onPasswordFocusChanged() {
    if (_isRegister) {
      setState(() {});
    }
  }

  void _switchTo(_Mode mode) {
    if (mode == _mode) {
      return;
    }
    // O toque háptico marca a virada no instante em que ela é decidida — é o mesmo par de
    // som-e-tato que a pastilha do segmentado tem em qualquer outro lugar do sistema.
    HapticFeedback.selectionClick();
    // Sem foco em campo nenhum: o teclado aberto cobriria justamente os campos que estão
    // nascendo, e um campo que ganha altura por baixo do teclado não é visto por ninguém.
    FocusScope.of(context).unfocus();

    setState(() {
      _mode = mode;
      // A confirmação some com a troca; o nome fica. Confirmar uma senha que talvez tenha
      // mudado não faz sentido, mas quem digitou o próprio nome e voltou para conferir alguma
      // coisa não deveria ter de digitá-lo de novo.
      _confirmation.clear();
    });
    ref.read(authControllerProvider.notifier).clearMessages();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);

    final ok = _isRegister
        ? await controller.register(
            email: _email.text.trim(),
            password: _password.text,
            displayName: _displayName.text.trim(),
          )
        : await controller.login(
            email: _email.text.trim(),
            password: _password.text,
          );

    if (ok && mounted) {
      _finishAutofill();
      context.go(Routes.home);
    }
  }

  Future<void> _social(Future<bool> Function() action) async {
    if (await action() && mounted) {
      context.go(Routes.home);
    }
  }

  /// Fecha o contexto de preenchimento automático. É o que faz o sistema oferecer "salvar esta
  /// senha?" — sem esta chamada o gerenciador do aparelho descarta o que foi digitado, e quem
  /// acabou de criar uma conta fica com uma senha nova em lugar nenhum.
  void _finishAutofill() => TextInput.finishAutofillContext();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final providers = ref.watch(authProvidersProvider);
    final theme = Theme.of(context);

    final showGoogle = providers.valueOrNull?.google ?? false;
    // Sign in with Apple só no iOS: no Android exigiria um Services ID configurado, e ali
    // o Google já cobre o caso.
    final showApple =
        (providers.valueOrNull?.apple ?? false) &&
        SocialSignIn.isAppleAvailable;
    final showPasswordReset = providers.valueOrNull?.passwordReset ?? false;

    return AuthScaffold(
      subtitle: _isRegister
          ? 'Crie sua conta e comece a treinar'
          : 'Entre para continuar seu treino',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          // Valida quando o campo perde o foco, e não só no envio. Descobrir cinco problemas
          // de uma vez depois de apertar o botão é a forma mais cara de contar que faltava um
          // arroba — aqui cada campo responde quando a pessoa termina com ele.
          autovalidateMode: AutovalidateMode.onUnfocus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Enquanto o pedido corre o controle para de responder, como todo botão da tela.
              // `IgnorePointer` e não um `onChanged` vazio: um controle que acende ao toque e
              // não faz nada é pior que um que não acende.
              IgnorePointer(
                ignoring: state.loading,
                child: GlassSegmented<_Mode>(
                  value: _mode,
                  onChanged: _switchTo,
                  segments: const [
                    GlassSegment(value: _Mode.login, label: 'Entrar'),
                    GlassSegment(value: _Mode.register, label: 'Criar conta'),
                  ],
                ),
              ),
              const SizedBox(height: Space.lg),

              _Reveal(
                visible: state.error != null || state.info != null,
                child: state.error != null
                    ? AuthMessage.error(state.error!)
                    : AuthMessage.info(state.info ?? ''),
              ),

              _Reveal(
                visible: _isRegister,
                child: Padding(
                  // O respiro de cima não é estético: com borda externa, o rótulo flutuante
                  // sobe até *fora* da caixa do campo, e o recorte que faz o campo abrir e
                  // fechar cortaria "Nome" pela metade.
                  padding: const EdgeInsets.only(
                    top: Space.xs,
                    bottom: Space.sm,
                  ),
                  child: TextFormField(
                    controller: _displayName,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                    // Um nome de duzentos caracteres não é um nome; cortar na digitação diz
                    // isso sem uma mensagem de erro depois do envio.
                    inputFormatters: [LengthLimitingTextInputFormatter(60)],
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      helperText: 'Como você quer ser chamado.',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      // No login o campo está recolhido, mas continua montado — é o que
                      // permite fechá-lo com transição em vez de corte. Validá-lo ali
                      // impediria de entrar quem nunca viu o campo.
                      if (!_isRegister) {
                        return null;
                      }
                      final name = value?.trim() ?? '';
                      if (name.isEmpty) {
                        return 'Informe seu nome.';
                      }
                      if (name.length < 2) {
                        return 'Nome muito curto.';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              TextFormField(
                controller: _email,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Informe seu e-mail.';
                  }
                  // Validação frouxa de propósito: quem decide se o e-mail existe é o
                  // servidor, e regex rigorosa recusa endereços válidos.
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'E-mail inválido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Space.sm),

              TextFormField(
                controller: _password,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                textInputAction: _isRegister
                    ? TextInputAction.next
                    : TextInputAction.done,
                autofillHints: [
                  _isRegister
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                onChanged: _isRegister ? (_) => setState(() {}) : null,
                onFieldSubmitted: (_) =>
                    _isRegister ? _confirmationFocus.requestFocus() : _submit(),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    tooltip: _obscurePassword
                        ? 'Mostrar senha'
                        : 'Ocultar senha',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  final password = value ?? '';
                  if (password.isEmpty) {
                    return 'Informe sua senha.';
                  }
                  // No login não se valida composição: a senha pode ser antiga, de antes
                  // da política atual, e reprovar aqui impediria alguém de entrar na
                  // própria conta.
                  if (_isRegister && !PasswordRule.allSatisfied(password)) {
                    return 'A senha não atende às regras abaixo.';
                  }
                  return null;
                },
              ),

              _Reveal(
                visible: _showRules,
                child: Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: PasswordRulesView(password: _password.text),
                ),
              ),

              _Reveal(
                visible: _isRegister,
                child: Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: TextFormField(
                    controller: _confirmation,
                    focusNode: _confirmationFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Confirmar senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (!_isRegister) {
                        return null;
                      }
                      return value == _password.text
                          ? null
                          : 'As senhas não conferem.';
                    },
                  ),
                ),
              ),

              const SizedBox(height: Space.lg),
              PressableScale(
                enabled: !state.loading,
                child: FilledButton(
                  onPressed: state.loading ? null : _submit,
                  child: AnimatedSwitcher(
                    duration: Motion.fast,
                    child: state.loading
                        ? SizedBox(
                            key: const ValueKey('carregando'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              // O tema pinta o indicador de primária, que é a cor do próprio
                              // botão cheio — sem isto, o botão fica com um buraco girando.
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            _isRegister ? 'Criar conta' : 'Entrar',
                            key: ValueKey(_mode),
                          ),
                  ),
                ),
              ),

              _Reveal(
                visible: !_isRegister && showPasswordReset,
                child: TextButton(
                  onPressed: state.loading
                      ? null
                      : () => context.push(Routes.forgotPassword),
                  child: const Text('Esqueci minha senha'),
                ),
              ),

              if (showGoogle || showApple) ...[
                const SizedBox(height: Space.md),
                const _OrDivider(),
                const SizedBox(height: Space.md),
                if (showGoogle)
                  PressableScale(
                    enabled: !state.loading,
                    child: OutlinedButton.icon(
                      onPressed: state.loading
                          ? null
                          : () => _social(
                              ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithGoogle,
                            ),
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Continuar com Google'),
                    ),
                  ),
                if (showGoogle && showApple) const SizedBox(height: Space.xs),
                if (showApple)
                  PressableScale(
                    enabled: !state.loading,
                    child: OutlinedButton.icon(
                      onPressed: state.loading
                          ? null
                          : () => _social(
                              ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithApple,
                            ),
                      icon: const Icon(Icons.apple, size: 24),
                      label: const Text('Continuar com Apple'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A linha com a palavra no meio, entre o formulário e os provedores.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Um fio que nasce e morre em transparente, e não uma régua de ponta a ponta: dentro de um
    // cartão de vidro, uma linha cheia encostando nas duas bordas parte a peça em duas.
    final fade = LinearGradient(
      colors: [
        theme.colorScheme.outlineVariant.withValues(alpha: 0),
        theme.colorScheme.outlineVariant,
      ],
    );

    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: fade),
            child: const SizedBox(height: 1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
          child: Text('ou', style: theme.textTheme.labelSmall),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: fade.colors.reversed.toList()),
            ),
            child: const SizedBox(height: 1),
          ),
        ),
      ],
    );
  }
}

/// Um pedaço do formulário que abre e fecha em altura.
///
/// **Fechar não é sumir.** O conteúdo desce até a altura zero enquanto some, e o que está
/// abaixo dele sobe junto — é o que conta que os campos do cadastro não foram para outro lugar,
/// eles se recolheram ali mesmo, e que o mesmo gesto os traz de volta.
///
/// Enquanto está recolhido o conteúdo **continua montado**, e é por isso que o campo guarda o
/// que foi digitado entre uma troca de modo e outra. Em compensação ele sai do foco e do leitor
/// de tela — um campo de 0 px de altura que o TalkBack ainda anuncia é pior que um campo
/// ausente. Os validadores dos campos recolhidos precisam devolver nulo por conta própria: o
/// `Form` não sabe que eles estão escondidos.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.base,
    value: widget.visible ? 1 : 0,
  );

  late final Animation<double> _factor = CurvedAnimation(
    parent: _controller,
    curve: Motion.enter,
    reverseCurve: Motion.exit,
  );

  /// O último conteúdo que estava à mostra.
  ///
  /// A faixa de mensagem some junto com o texto dela — quando o erro é limpo, `child` já vem
  /// vazio. Guardando o anterior, o recolhimento acontece *com* a mensagem dentro, que é o que
  /// se vê no mundo: a coisa encolhe, não é apagada e depois encolhida.
  late Widget _content = widget.child;

  @override
  void didUpdateWidget(_Reveal old) {
    super.didUpdateWidget(old);

    if (widget.visible) {
      _content = widget.child;
    }
    if (widget.visible == old.visible) {
      return;
    }

    // Movimento reduzido: o campo continua aparecendo e sumindo, só que sem percorrer o
    // caminho. Aqui a informação está no estado final, não na travessia.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _factor,
      // Ancorado no topo: o que abre desce a partir de onde estava, e o que fecha sobe para
      // lá. Centrado na vertical, o conteúdo escorregaria para os dois lados ao mesmo tempo.
      // Na horizontal continua no meio — o `Align` afrouxa a largura, e com o encosto à
      // esquerda um botão de texto encolhido nasceria colado na borda do cartão.
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _factor,
        child: ExcludeFocus(
          excluding: !widget.visible,
          child: ExcludeSemantics(excluding: !widget.visible, child: _content),
        ),
      ),
    );
  }
}
