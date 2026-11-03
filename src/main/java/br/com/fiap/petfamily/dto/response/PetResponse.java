package br.com.fiap.petfamily.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PetResponse {
    private Long id;
    private String nome;
    private String especie;
    private String raca;
    private Integer idade;
    private Double peso;
    private String observacoesSaude;
    private Long tutorId;
    private String tutorNome;
    private int totalConsultas;
    private int totalLembretesPendentes;
}
