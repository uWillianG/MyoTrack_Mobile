package com.myotrack.infrastructure.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Identidade externa vinculada à conta (provider "Google" + o {@code sub} do token).
 * É por aqui que o login social reencontra o usuário em vez de criar uma conta nova.
 */
@Entity
@Table(name = "AspNetUserLogins")
@Getter
@Setter
public class UserLogin {

    @EmbeddedId
    private Key id;

    @Column(name = "ProviderDisplayName")
    private String providerDisplayName;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    public UserLogin() {
    }

    public UserLogin(String loginProvider, String providerKey, UUID userId, String providerDisplayName) {
        this.id = new Key(loginProvider, providerKey);
        this.userId = userId;
        this.providerDisplayName = providerDisplayName;
    }

    @Embeddable
    @Getter
    @Setter
    public static class Key implements Serializable {

        @Column(name = "LoginProvider", nullable = false)
        private String loginProvider;

        @Column(name = "ProviderKey", nullable = false)
        private String providerKey;

        public Key() {
        }

        public Key(String loginProvider, String providerKey) {
            this.loginProvider = loginProvider;
            this.providerKey = providerKey;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) {
                return true;
            }
            if (!(other instanceof Key key)) {
                return false;
            }
            return Objects.equals(loginProvider, key.loginProvider)
                    && Objects.equals(providerKey, key.providerKey);
        }

        @Override
        public int hashCode() {
            return Objects.hash(loginProvider, providerKey);
        }
    }
}
