package br.com.fiap.petfamily;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * CRUD completo de Pet pela API, conferindo cada etapa com SELECT direto na tabela
 * (mesma verificação que o vídeo da Sprint 4 faz no banco em nuvem).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@TestPropertySource(properties = "cors.allowed-origins=*")
class PetCrudPersistenciaIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private EntityManager em;

    @Test
    void cicloCompletoCriarLerAtualizarExcluirPersisteNoBanco() throws Exception {
        MvcResult registro = mockMvc.perform(post("/auth/registrar")
                        .contentType("application/json")
                        .content("""
                                {"nome":"DEMO Tutor CRUD","email":"demo.crud@teste.com","senha":"senha123"}"""))
                .andExpect(status().isCreated())
                .andReturn();
        String auth = "Bearer " + json(registro).get("token").asText();

        // CREATE
        MvcResult criado = mockMvc.perform(post("/pets")
                        .header("Authorization", auth)
                        .contentType("application/json")
                        .content("""
                                {"nome":"DEMO-Sprint4-Rex","especie":"Cachorro","raca":"SRD","idade":3,"peso":12.5}"""))
                .andExpect(status().isCreated())
                .andReturn();
        long id = json(criado).get("id").asLong();

        em.flush();
        List<String> nomes = jdbc.queryForList("SELECT nome FROM pets WHERE id = ?", String.class, id);
        assertEquals(List.of("DEMO-Sprint4-Rex"), nomes);

        // READ
        mockMvc.perform(get("/pets/{id}", id).header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("DEMO-Sprint4-Rex"))
                .andExpect(jsonPath("$.especie").value("Cachorro"));
        mockMvc.perform(get("/pets").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[?(@.id == %d)]".formatted(id)).exists());

        // UPDATE
        mockMvc.perform(put("/pets/{id}", id)
                        .header("Authorization", auth)
                        .contentType("application/json")
                        .content("""
                                {"nome":"DEMO-Sprint4-Rex-Atualizado","especie":"Cachorro","raca":"Labrador","idade":4,"peso":14.0}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("DEMO-Sprint4-Rex-Atualizado"));

        em.flush();
        assertEquals("DEMO-Sprint4-Rex-Atualizado",
                jdbc.queryForObject("SELECT nome FROM pets WHERE id = ?", String.class, id));
        assertEquals("Labrador",
                jdbc.queryForObject("SELECT raca FROM pets WHERE id = ?", String.class, id));

        // DELETE
        mockMvc.perform(delete("/pets/{id}", id).header("Authorization", auth))
                .andExpect(status().isNoContent());

        em.flush();
        assertEquals(0, jdbc.queryForObject("SELECT COUNT(*) FROM pets WHERE id = ?", Integer.class, id));
        mockMvc.perform(get("/pets/{id}", id).header("Authorization", auth))
                .andExpect(status().isNotFound());
    }

    @Test
    void criarPetSemTokenEhRejeitadoESemEscritaNoBanco() throws Exception {
        Integer antes = jdbc.queryForObject("SELECT COUNT(*) FROM pets", Integer.class);

        mockMvc.perform(post("/pets")
                        .contentType("application/json")
                        .content("""
                                {"nome":"DEMO-Sem-Token","especie":"Gato"}"""))
                .andExpect(status().isUnauthorized());

        assertTrue(antes != null);
        assertEquals(antes, jdbc.queryForObject("SELECT COUNT(*) FROM pets", Integer.class));
    }

    @Test
    void actuatorInfoEhPublicoParaOSmokeTestDoCd() throws Exception {
        mockMvc.perform(get("/actuator/info")).andExpect(status().isOk());
    }

    private JsonNode json(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }
}
