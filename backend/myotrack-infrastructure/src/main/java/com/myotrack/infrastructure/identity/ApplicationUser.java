package com.myotrack.infrastructure.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Usuário. Mapeia a tabela que o ASP.NET Core Identity criou, com todas as colunas
 * originais — inclusive as que o Spring Security não usa (lockout, two-factor,
 * telefone): elas continuam preenchidas nos registros existentes e a tabela é
 * compartilhada com o .NET até o corte.
 *
 * <p>{@code PasswordHash} guarda o formato V3 do Identity; ver
 * {@code AspNetIdentityPasswordEncoder} para o algoritmo de verificação.
 */
@Entity
@Table(name = "AspNetUsers")
@Getter
@Setter
public class ApplicationUser {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "DisplayName")
    private String displayName;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "UserName", length = 256)
    private String userName;

    @Column(name = "NormalizedUserName", length = 256)
    private String normalizedUserName;

    @Column(name = "Email", length = 256)
    private String email;

    @Column(name = "NormalizedEmail", length = 256)
    private String normalizedEmail;

    @Column(name = "EmailConfirmed", nullable = false)
    private boolean emailConfirmed;

    /** Null para contas criadas pelo login com Google (sem senha). */
    @Column(name = "PasswordHash")
    private String passwordHash;

    /**
     * Muda a cada troca de senha. O .NET o usa para invalidar sessões; mantemos
     * o campo preenchido para não quebrar quem ainda lê pela API antiga.
     */
    @Column(name = "SecurityStamp")
    private String securityStamp;

    @Column(name = "ConcurrencyStamp")
    private String concurrencyStamp;

    @Column(name = "PhoneNumber")
    private String phoneNumber;

    @Column(name = "PhoneNumberConfirmed", nullable = false)
    private boolean phoneNumberConfirmed;

    @Column(name = "TwoFactorEnabled", nullable = false)
    private boolean twoFactorEnabled;

    @Column(name = "LockoutEnd")
    private OffsetDateTime lockoutEnd;

    @Column(name = "LockoutEnabled", nullable = false)
    private boolean lockoutEnabled;

    @Column(name = "AccessFailedCount", nullable = false)
    private int accessFailedCount;
}
