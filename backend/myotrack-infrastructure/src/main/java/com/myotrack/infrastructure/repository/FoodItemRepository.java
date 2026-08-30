package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.FoodItem;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FoodItemRepository extends JpaRepository<FoodItem, Integer> {

    List<FoodItem> findByNameContainingIgnoreCase(String fragment);

    /**
     * O catálogo inteiro, em ordem alfabética.
     *
     * <p>É o que a busca de alimentos carrega, e sim, ela carrega tudo. O filtro do usuário
     * precisa casar "pao" com "Pão" — no teclado do celular ninguém acentua enquanto procura —, e
     * fazer isso no banco exigiria a extensão {@code unaccent}, cuja criação pede superusuário e
     * não está disponível em todo Postgres gerenciado. São duas centenas de linhas curtas: menos
     * dado que uma única foto de refeição, lido uma vez por requisição.
     */
    List<FoodItem> findAllByOrderByNameAsc();

    /**
     * Os alimentos que podem entrar num plano alimentar gerado.
     *
     * <p>Ver {@code FoodItem.usableInDiet}: o catálogo do diário inclui açúcar, refrigerante e
     * suplemento porque a pessoa come essas coisas, e são exatamente eles que o
     * {@code DietRuleEngine} escolheria primeiro se os enxergasse.
     */
    List<FoodItem> findByUsableInDietTrue();
}
