package com.myotrack.api.auth;

/**
 * Identidade vinda de um provedor externo (Google ou Apple), já validada.
 *
 * <p>Existe para que {@link AccountService} não precise conhecer o formato de cada provedor: o
 * serviço de cada um valida seu token e devolve este contrato comum.
 *
 * @param provider    nome gravado em {@code AspNetUserLogins.LoginProvider}
 * @param subject     identificador estável do usuário no provedor ({@code sub})
 * @param email       e-mail verificado; na Apple pode ser um relay {@code @privaterelay.appleid.com}
 * @param displayName nome para exibição — a Apple só o envia na PRIMEIRA autorização, então pode
 *                    vir null em todos os logins seguintes
 */
public record ExternalIdentity(String provider, String subject, String email, String displayName) {
}
