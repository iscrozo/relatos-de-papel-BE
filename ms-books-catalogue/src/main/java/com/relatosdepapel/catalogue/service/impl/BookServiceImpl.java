package com.relatosdepapel.catalogue.service.impl;

import com.relatosdepapel.catalogue.document.BookDocument;
import com.relatosdepapel.catalogue.dto.BookDTO;
import com.relatosdepapel.catalogue.entity.Book;
import com.relatosdepapel.catalogue.repository.BookRepository;
import com.relatosdepapel.catalogue.repository.BookSearchRepository;
import com.relatosdepapel.catalogue.service.BookService;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.query.Criteria;
import org.springframework.data.elasticsearch.core.query.CriteriaQuery;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.StreamSupport;


@Service
public class BookServiceImpl implements BookService {

    private static final String BOOK_NOT_FOUND = "Book not found";

    private final BookRepository repository;
    private final BookSearchRepository searchRepository;
    private final ElasticsearchOperations elasticsearchOperations;

    public BookServiceImpl(BookRepository repository,
                          BookSearchRepository searchRepository,
                          ElasticsearchOperations elasticsearchOperations) {
        this.repository = repository;
        this.searchRepository = searchRepository;
        this.elasticsearchOperations = elasticsearchOperations;
    }


    // Añadir libro

    @Override
    public BookDTO create(BookDTO bookDTO) {
        Book book = mapToEntity(bookDTO);
        Book saved = repository.save(book);
        indexBook(saved);
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
        existing.setPrice(bookDTO.getPrice());
        existing.setStock(bookDTO.getStock());
        existing.setCategory(bookDTO.getCategory());
        existing.setPublicationYear(bookDTO.getPublicationDate() != null ? bookDTO.getPublicationDate().getYear() : null);
        existing.setRating(bookDTO.getRating());
        existing.setVisible(bookDTO.getVisible());

        Book saved = repository.save(existing);
        indexBook(saved);
        return mapToDTO(saved);
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
                case "price" -> existing.setPrice(new java.math.BigDecimal(value.toString()));
                case "stock" -> existing.setStock((Integer) value);
                case "category" -> existing.setCategory((String) value);
                case "publicationDate" -> existing.setPublicationYear(LocalDate.parse(value.toString()).getYear());
                case "publicationYear" -> existing.setPublicationYear(value instanceof Number n ? n.intValue() : Integer.parseInt(value.toString()));
                case "rating" -> existing.setRating(value instanceof Number n ? n.intValue() : Integer.parseInt(value.toString()));
                case "visible" -> existing.setVisible(Boolean.parseBoolean(value.toString()));
                default -> { /* campo desconocido */ }
            }
        });

        Book saved = repository.save(existing);
        indexBook(saved);
        return mapToDTO(saved);
    }


    // Eliminar libro

    @Override
    public void delete(Long id) {
        repository.deleteById(id);
        searchRepository.deleteById(id);
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
        return repository.findAll().stream()
                .filter(book -> Boolean.TRUE.equals(book.getVisible()))
                .map(this::mapToDTO)
                .toList();
    }


    // Buscar (Elasticsearch; ya no usa base de datos relacional)

    @Override
    public List<BookDTO> search(String title, String author, String isbn,
                                String category, Integer rating, Boolean visible) {

        Criteria criteria = null;

        if (title != null && !title.isBlank()) {
            criteria = criteria == null
                    ? Criteria.where("title").contains(title)
                    : criteria.and(Criteria.where("title").contains(title));
        }
        if (author != null && !author.isBlank()) {
            criteria = criteria == null
                    ? Criteria.where("author").contains(author)
                    : criteria.and(Criteria.where("author").contains(author));
        }
        if (isbn != null && !isbn.isBlank()) {
            criteria = criteria == null
                    ? Criteria.where("isbn").is(isbn)
                    : criteria.and(Criteria.where("isbn").is(isbn));
        }
        if (category != null && !category.isBlank()) {
            criteria = criteria == null
                    ? Criteria.where("category").is(category)
                    : criteria.and(Criteria.where("category").is(category));
        }
        if (rating != null) {
            criteria = criteria == null
                    ? Criteria.where("rating").is(rating)
                    : criteria.and(Criteria.where("rating").is(rating));
        }
        if (visible != null) {
            criteria = criteria == null
                    ? Criteria.where("visible").is(visible)
                    : criteria.and(Criteria.where("visible").is(visible));
        }

        if (criteria == null) {
            return StreamSupport.stream(searchRepository.findAll().spliterator(), false)
                    .map(this::mapDocumentToDTO)
                    .toList();
        }

        return elasticsearchOperations.search(
                new CriteriaQuery(criteria),
                BookDocument.class
        ).stream()
         .map(SearchHit::getContent)
         .map(this::mapDocumentToDTO)
         .toList();
    }

    @Override
    public void reindex() {
        repository.findAll().forEach(this::indexBook);
    }

    private void indexBook(Book book) {
        searchRepository.save(mapToDocument(book));
    }

    private BookDocument mapToDocument(Book book) {
        BookDocument doc = new BookDocument();
        doc.setId(book.getId());
        doc.setTitle(book.getTitle());
        doc.setAuthor(book.getAuthor());
        doc.setIsbn(book.getIsbn());
        doc.setPrice(book.getPrice() != null ? book.getPrice().doubleValue() : null);
        doc.setStock(book.getStock());
        doc.setCategory(book.getCategory());
        doc.setPublicationYear(book.getPublicationYear());
        doc.setRating(book.getRating());
        doc.setVisible(book.getVisible());
        return doc;
    }

    private BookDTO mapDocumentToDTO(BookDocument doc) {
        BookDTO dto = new BookDTO();
        dto.setId(doc.getId());
        dto.setTitle(doc.getTitle());
        dto.setAuthor(doc.getAuthor());
        dto.setIsbn(doc.getIsbn());
        dto.setPrice(doc.getPrice() != null ? java.math.BigDecimal.valueOf(doc.getPrice()) : null);
        dto.setStock(doc.getStock());
        dto.setCategory(doc.getCategory());
        dto.setPublicationDate(doc.getPublicationYear() != null ? LocalDate.of(doc.getPublicationYear(), 1, 1) : null);
        dto.setRating(doc.getRating());
        dto.setVisible(doc.getVisible());
        return dto;
    }



    private BookDTO mapToDTO(Book book) {
        BookDTO dto = new BookDTO();
        dto.setId(book.getId());
        dto.setTitle(book.getTitle());
        dto.setAuthor(book.getAuthor());
        dto.setIsbn(book.getIsbn());
        dto.setPrice(book.getPrice());
        dto.setStock(book.getStock());
        dto.setCategory(book.getCategory());
        dto.setPublicationDate(book.getPublicationYear() != null ? LocalDate.of(book.getPublicationYear(), 1, 1) : null);
        dto.setRating(book.getRating());
        dto.setVisible(book.getVisible());
        return dto;
    }

    private Book mapToEntity(BookDTO dto) {
        Book book = new Book();
        book.setTitle(dto.getTitle());
        book.setAuthor(dto.getAuthor());
        book.setIsbn(dto.getIsbn() != null && !dto.getIsbn().isBlank() ? dto.getIsbn().trim() : null);
        book.setPrice(dto.getPrice() != null ? dto.getPrice() : java.math.BigDecimal.ZERO);
        book.setStock(dto.getStock() != null ? dto.getStock() : 0);
        book.setCategory(dto.getCategory());
        book.setPublicationYear(dto.getPublicationDate() != null ? dto.getPublicationDate().getYear() : null);
        book.setRating(dto.getRating());
        book.setVisible(dto.getVisible() != null ? dto.getVisible() : Boolean.TRUE);
        return book;
    }
}
