package br.com.fiap.petfamily.repository;

import br.com.fiap.petfamily.entity.InteracaoIA;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface InteracaoIARepository extends JpaRepository<InteracaoIA, Long> {

    List<InteracaoIA> findByPetIdOrderByDataHoraDesc(Long petId);

    Page<InteracaoIA> findByPetId(Long petId, Pageable pageable);
}
