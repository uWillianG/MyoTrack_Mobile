package com.myotrack.infrastructure.identity.password;

/**
 * Falha de validação de senha. Os códigos são os mesmos do ASP.NET Identity e as descrições
 * as do PortugueseIdentityErrorDescriber — elas chegam direto na tela de cadastro.
 */
public record PasswordError(String code, String description) {
}
