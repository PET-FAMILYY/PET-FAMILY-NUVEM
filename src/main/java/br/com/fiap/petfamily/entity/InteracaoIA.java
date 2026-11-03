package br.com.fiap.petfamily.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "interacoes_ia")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = "pet")
public class InteracaoIA {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String pergunta;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String resposta;

    @Column(nullable = false)
    private LocalDateTime dataHora;

    private String categoria;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pet_id", nullable = false)
    private Pet pet;
}
