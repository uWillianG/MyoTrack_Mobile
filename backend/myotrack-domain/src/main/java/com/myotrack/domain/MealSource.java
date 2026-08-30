package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

/**
 * De onde veio uma linha do diário alimentar.
 *
 * <p>Existe porque a entrada manual mora na <b>mesma tabela</b> da análise por foto. Sem o
 * discriminador, "refeição sem foto" e "refeição cuja foto a retenção já apagou" seriam o mesmo
 * estado no banco — ambas com {@code MediaKey} nulo —, e nenhuma consulta conseguiria separar as
 * duas depois. A distinção não é cosmética: a varredura de retenção precisa saber quais linhas
 * nunca tiveram arquivo para não marcá-las como expiradas, e a tela precisa saber se cabe
 * oferecer "ver a foto".
 *
 * <p>Só dois valores, e é de propósito. Digitar à mão, aceitar a estimativa da IA por texto e
 * escolher no catálogo produzem a mesma coisa — números que o usuário conferiu antes de salvar —
 * e separá-los aqui criaria três estados que nenhum leitor trata de forma diferente.
 */
public enum MealSource implements WireEnum {

    PHOTO(1, "Photo"),
    MANUAL(2, "Manual");

    private final int value;
    private final String wireName;

    MealSource(int value, String wireName) {
        this.value = value;
        this.wireName = wireName;
    }

    @Override
    public int getValue() {
        return value;
    }

    @Override
    @JsonValue
    public String getWireName() {
        return wireName;
    }

    @JsonCreator
    public static MealSource fromWireName(String name) {
        return WireEnums.fromWireName(MealSource.class, name);
    }

    public static MealSource fromValue(int value) {
        return WireEnums.fromValue(MealSource.class, value);
    }
}
