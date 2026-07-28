package com.myotrack.domain;

/**
 * Enum com dois contratos herdados do backend .NET que precisam ser preservados:
 *
 * <ul>
 *   <li><b>{@link #getValue()}</b> — o inteiro gravado no banco. Os valores são explícitos no
 *       C# original ({@code Equipment.Other = 99}), então a ordinal do Java não serve.</li>
 *   <li><b>{@link #getWireName()}</b> — o nome emitido no JSON. O ASP.NET Core usa
 *       {@code JsonStringEnumConverter}, que escreve o nome PascalCase da constante; o app e a
 *       SPA leem exatamente isso.</li>
 * </ul>
 */
public interface WireEnum {

    /** Valor persistido na coluna {@code integer}. */
    int getValue();

    /** Nome PascalCase usado no JSON, idêntico ao da constante C#. */
    String getWireName();
}
