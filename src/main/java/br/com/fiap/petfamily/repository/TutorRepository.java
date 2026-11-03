package br.com.fiap.petfamily.repository;

import br.com.fiap.petfamily.entity.Tutor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TutorRepository extends JpaRepository<Tutor, Long> {

    Page<Tutor> findByNomeContainingIgnoreCase(String nome, Pageable pageable);

    boolean existsByEmail(String email);
}
