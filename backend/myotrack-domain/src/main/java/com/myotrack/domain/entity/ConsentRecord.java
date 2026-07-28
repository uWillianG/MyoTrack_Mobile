package com.myotrack.domain.entity;

import com.myotrack.domain.ConsentType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/** Trilha de consentimento exigida pela LGPD para dados sensíveis de saúde. */
@Entity
@Table(name = "ConsentRecords")
@Getter
@Setter
public class ConsentRecord {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @Column(name = "Type", nullable = false)
    private ConsentType type;

    @Column(name = "TermsVersion", nullable = false)
    private String termsVersion;

    @Column(name = "GrantedAt", nullable = false)
    private OffsetDateTime grantedAt = OffsetDateTime.now();

    @Column(name = "RevokedAt")
    private OffsetDateTime revokedAt;
}
