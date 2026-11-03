package br.com.fiap.petfamily.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class InteracaoIAResponse {
    private Long id;
    private String pergunta;
    private String resposta;
    private LocalDateTime dataHora;
    private String categoria;
    private Long petId;
    private String petNome;
}
