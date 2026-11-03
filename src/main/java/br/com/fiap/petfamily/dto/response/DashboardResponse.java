package br.com.fiap.petfamily.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DashboardResponse {
    private long totalTutores;
    private long totalPets;
    private long totalConsultas;
    private long totalLembretesPendentes;
    private long totalInteracoesIA;
    private double taxaAdesaoPreventiva;
}
