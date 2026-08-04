package com.myotrack.api.rewards;

import com.myotrack.api.rewards.RewardService.RewardStatus;
import com.myotrack.api.security.CurrentUser;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * A recompensa por constância: quantas semanas seguidas, e o Pro que elas renderam.
 *
 * <p>Um endpoint só, e de leitura, porque <b>o app não tem o que pedir</b>. Não existe "reivindicar
 * conquista": o servidor reconta a sequência a partir das sessões que ele guardou e concede o que
 * for devido. Um endpoint de reivindicação seria um endpoint em que o cliente afirma ter treinado
 * doze semanas — e com Pro em jogo, essa afirmação vale dinheiro.
 *
 * <p>As outras dez conquistas do app continuam derivadas no cliente e não passam por aqui: elas
 * pintam um selo, e um selo forjado não custa nada a ninguém.
 */
@RestController
@RequestMapping("/api/rewards")
public class RewardsController {

    private final RewardService rewards;

    public RewardsController(RewardService rewards) {
        this.rewards = rewards;
    }

    @GetMapping
    public RewardStatus status() {
        return rewards.evaluate(CurrentUser.id());
    }
}
