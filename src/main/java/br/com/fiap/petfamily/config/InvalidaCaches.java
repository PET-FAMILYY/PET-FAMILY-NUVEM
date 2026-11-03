package br.com.fiap.petfamily.config;

import org.springframework.cache.annotation.CacheEvict;

import java.lang.annotation.*;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@CacheEvict(cacheNames = {CacheNames.TUTORES, CacheNames.PETS, CacheNames.CONSULTAS,
        CacheNames.LEMBRETES, CacheNames.DASHBOARD}, allEntries = true)
public @interface InvalidaCaches {
}
