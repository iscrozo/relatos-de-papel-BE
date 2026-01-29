package com.relatosdepapel.catalogue.service.impl;

import com.relatosdepapel.catalogue.dto.BookDTO;
import com.relatosdepapel.catalogue.entity.Book;
import com.relatosdepapel.catalogue.repository.BookRepository;
import com.relatosdepapel.catalogue.service.BookService;
import org.springframework.stereotype.Service;

import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;


@Service
public class BookServiceImpl implements BookService {

    private static final String BOOK_NOT_FOUND = "Book not found";

    private final BookRepository repository;

    public BookServiceImpl(BookRepository repository) {
        this.repository = repository;
    }


    // Añadir libro

    @Override
    public BookDTO create(BookDTO bookDTO) {
        Book book = mapToEntity(bookDTO);
        Book saved = repository.save(book);
        return mapToDTO(saved);
    }


    // Actualizar

    @Override
    public BookDTO update(Long id, BookDTO bookDTO) {
        Book existing = repository.findById(id)
                .orElseThrow(() -> new RuntimeException(BOOK_NOT_FOUND));

        existing.setTitle(bookDTO.getTitle());
        existing.setAuthor(bookDTO.getAuthor());
        existing.setIsbn(bookDTO.getIsbn());
        existing.setCategory(bookDTO.getCategory());
        existing.setPublicationDate(bookDTO.getPublicationDate());
        existing.setRating(bookDTO.getRating());
        existing.setVisible(bookDTO.getVisible());

        return mapToDTO(repository.save(existing));
    }


    // Acualizar parcialmente 

    @Override
    public BookDTO partialUpdate(Long id, Map<String, Object> fields) {
        Book existing = repository.findById(id)
                .orElseThrow(() -> new RuntimeException(BOOK_NOT_FOUND));

        fields.forEach((key, value) -> {
            switch (key) {
                case "title" -> existing.setTitle((String) value);
                case "author" -> existing.setAuthor((String) value);
                case "isbn" -> existing.setIsbn((String) value);
                case "category" -> existing.setCategory((String) value);
                case "publicationDate" ->
                        existing.setPublicationDate(java.time.LocalDate.parse(value.toString()));
                case "rating" -> existing.setRating((Integer) value);
                case "visible" -> existing.setVisible((Boolean) value);
                default -> {
                    // campo desconocido
                }
            }
        });

        return mapToDTO(repository.save(existing));
    }


    // Eliminar libro

    @Override
    public void delete(Long id) {
        repository.deleteById(id);
    }


    // Buscar por ID

    @Override
    public BookDTO findById(Long id) {
        return repository.findById(id)
                .map(this::mapToDTO)
                .orElseThrow(() -> new RuntimeException(BOOK_NOT_FOUND));
    }


    // Encontrar todos los libros visibles

    @Override
    public List<BookDTO> findAllVisible() {
        return repository.findAll()
                .stream()
                .filter(book -> Boolean.TRUE.equals(book.getVisible()))
                .map(this::mapToDTO)
                .toList();
    }


    // Buscar

    @Override
    public List<BookDTO> search(String title, String author, String isbn,
                                String category, Integer rating, Boolean visible) {

        return repository.findAll((root, query, cb) -> {

            List<Predicate> predicates = new ArrayList<>();

            if (title != null) {
                predicates.add(
                        cb.like(
                                cb.lower(root.get("title")),
                                "%" + title.toLowerCase() + "%"
                        )
                );
            }

            if (author != null) {
                predicates.add(
                        cb.like(
                                cb.lower(root.get("author")),
                                "%" + author.toLowerCase() + "%"
                        )
                );
            }

            if (isbn != null) {
                predicates.add(cb.equal(root.get("isbn"), isbn));
            }

            if (category != null) {
                predicates.add(cb.equal(root.get("category"), category));
            }

            if (rating != null) {
                predicates.add(cb.equal(root.get("rating"), rating));
            }

            if (visible != null) {
                predicates.add(cb.equal(root.get("visible"), visible));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        }).stream()
          .map(this::mapToDTO)
          .toList();
    }



    private BookDTO mapToDTO(Book book) {
        BookDTO dto = new BookDTO();
        dto.setId(book.getId());
        dto.setTitle(book.getTitle());
        dto.setAuthor(book.getAuthor());
        dto.setIsbn(book.getIsbn());
        dto.setCategory(book.getCategory());
        dto.setPublicationDate(book.getPublicationDate());
        dto.setRating(book.getRating());
        dto.setVisible(book.getVisible());
        return dto;
    }

    private Book mapToEntity(BookDTO dto) {
        Book book = new Book();
        book.setTitle(dto.getTitle());
        book.setAuthor(dto.getAuthor());
        book.setIsbn(dto.getIsbn());
        book.setCategory(dto.getCategory());
        book.setPublicationDate(dto.getPublicationDate());
        book.setRating(dto.getRating());
        book.setVisible(dto.getVisible());
        return book;
    }
}
