package com.myotrack.infrastructure.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "AspNetRoles")
@Getter
@Setter
public class ApplicationRole {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "Name", length = 256)
    private String name;

    /** O Identity normaliza para maiúsculas; é por esta coluna que a busca acontece. */
    @Column(name = "NormalizedName", length = 256)
    private String normalizedName;

    @Column(name = "ConcurrencyStamp")
    private String concurrencyStamp;
}
