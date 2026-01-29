package com.relatosdepapel.catalogue.controller;

import com.relatosdepapel.catalogue.dto.BookDTO;
import com.relatosdepapel.catalogue.service.BookService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/books")
public class BookController {

    private final BookService service;

    public BookController(BookService service) {
        this.service = service;
    }

    // Crear libro
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BookDTO create(@RequestBody BookDTO bookDTO) {
        return service.create(bookDTO);
    }

    // Obtener todos los libros visibles
    @GetMapping
    public List<BookDTO> getAll() {
        return service.findAllVisible();
    }

    // Obtener libro por ID
    @GetMapping("/{id}")
    public BookDTO getById(@PathVariable Long id) {
        return service.findById(id);
    }

    // Busacar libros con filtros
    @GetMapping("/search")
    public List<BookDTO> search(
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String author,
            @RequestParam(required = false) String isbn,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Integer rating,
            @RequestParam(required = false) Boolean visible
    ) {
        return service.search(title, author, isbn, category, rating, visible);
    }

    // Actualizar libro
    @PutMapping("/{id}")
    public BookDTO update(
            @PathVariable Long id,
            @RequestBody BookDTO bookDTO
    ) {
        return service.update(id, bookDTO);
    }

    // Actualizar libro parcialmente
    @PatchMapping("/{id}")
    public BookDTO partialUpdate(
            @PathVariable Long id,
            @RequestBody Map<String, Object> fields
    ) {
        return service.partialUpdate(id, fields);
    }

    // Eliminar libro
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
