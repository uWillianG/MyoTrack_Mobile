package com.myotrack.domain;

/** Buscas genéricas por valor persistido e por nome de JSON para os {@link WireEnum}. */
public final class WireEnums {

    private WireEnums() {
    }

    public static <E extends Enum<E> & WireEnum> E fromValue(Class<E> type, int value) {
        for (E candidate : type.getEnumConstants()) {
            if (candidate.getValue() == value) {
                return candidate;
            }
        }
        throw new IllegalArgumentException(
                "Valor %d não corresponde a nenhum %s.".formatted(value, type.getSimpleName()));
    }

    /**
     * Aceita o nome PascalCase do contrato JSON e, por tolerância, a própria constante Java
     * (UPPER_SNAKE) — útil quando o valor vem de configuração ou de um teste.
     */
    public static <E extends Enum<E> & WireEnum> E fromWireName(Class<E> type, String name) {
        for (E candidate : type.getEnumConstants()) {
            if (candidate.getWireName().equalsIgnoreCase(name) || candidate.name().equalsIgnoreCase(name)) {
                return candidate;
            }
        }
        throw new IllegalArgumentException(
                "'%s' não corresponde a nenhum %s.".formatted(name, type.getSimpleName()));
    }
}
