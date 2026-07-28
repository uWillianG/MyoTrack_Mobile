package com.myotrack.domain;

import java.util.ArrayList;
import java.util.List;

/**
 * Ponte entre as colunas {@code integer[]} do Postgres e listas de enums.
 *
 * <p>Um {@code AttributeConverter} não alcança elementos de um atributo do tipo array, então as
 * entidades guardam o {@code Integer[]} cru e expõem a lista tipada por cima dele.
 */
public final class EnumArrays {

    private EnumArrays() {
    }

    public static <E extends Enum<E> & WireEnum> List<E> toList(Class<E> type, Integer[] values) {
        if (values == null) {
            return new ArrayList<>();
        }
        List<E> result = new ArrayList<>(values.length);
        for (Integer value : values) {
            if (value != null) {
                result.add(WireEnums.fromValue(type, value));
            }
        }
        return result;
    }

    public static Integer[] toValues(List<? extends WireEnum> items) {
        if (items == null) {
            return new Integer[0];
        }
        Integer[] values = new Integer[items.size()];
        for (int i = 0; i < values.length; i++) {
            values[i] = items.get(i).getValue();
        }
        return values;
    }
}
