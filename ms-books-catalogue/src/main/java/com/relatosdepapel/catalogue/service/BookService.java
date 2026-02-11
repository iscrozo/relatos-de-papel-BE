package com.relatosdepapel.catalogue.service;

import com.relatosdepapel.catalogue.dto.BookDTO;

import java.util.List;
import java.util.Map;

public interface BookService {

    BookDTO create(BookDTO bookDTO);

    BookDTO update(Long id, BookDTO bookDTO);

    BookDTO partialUpdate(Long id, Map<String, Object> fields);

    void delete(Long id);

    BookDTO findById(Long id);

    List<BookDTO> findAllVisible();

    List<BookDTO> search(
            String title,
            String author,
            String isbn,
            String category,
            Integer rating,
            Boolean visible
    );

    /** Reindexa todos los libros de la base de datos en Elasticsearch (útil tras arrancar ES o para pruebas). */
    void reindex();
}
