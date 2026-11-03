package br.com.fiap.petfamily.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "pets")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"tutor", "consultas", "lembretes", "interacoesIA"})
public class Pet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @Column(nullable = false)
    private String nome;

    @Column(nullable = false)
    private String especie;

    private String raca;

    private Integer idade;

    private Double peso;

    @Column(columnDefinition = "TEXT")
    private String observacoesSaude;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tutor_id", nullable = false)
    private Tutor tutor;

    @OneToMany(mappedBy = "pet", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<Consulta> consultas = new ArrayList<>();

    @OneToMany(mappedBy = "pet", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<Lembrete> lembretes = new ArrayList<>();

    @OneToMany(mappedBy = "pet", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<InteracaoIA> interacoesIA = new ArrayList<>();
}
