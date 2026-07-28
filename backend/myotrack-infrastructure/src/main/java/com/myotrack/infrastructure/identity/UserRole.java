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

/** Vínculo usuário↔papel (chave composta, como no Identity). */
@Entity
@Table(name = "AspNetUserRoles")
@Getter
@Setter
public class UserRole {

    @EmbeddedId
    private Key id;

    public UserRole() {
    }

    public UserRole(UUID userId, UUID roleId) {
        this.id = new Key(userId, roleId);
    }

    @Embeddable
    @Getter
    @Setter
    public static class Key implements Serializable {

        @Column(name = "UserId", nullable = false)
        private UUID userId;

        @Column(name = "RoleId", nullable = false)
        private UUID roleId;

        public Key() {
        }

        public Key(UUID userId, UUID roleId) {
            this.userId = userId;
            this.roleId = roleId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) {
                return true;
            }
            if (!(other instanceof Key key)) {
                return false;
            }
            return Objects.equals(userId, key.userId) && Objects.equals(roleId, key.roleId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(userId, roleId);
        }
    }
}
