package com.relatosdepapel.catalogue.document;

import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;

import java.math.BigDecimal;

/**
 * Modelo del libro en Elasticsearch para búsquedas.
 * Equivalente al modelo relacional Book, con tipos de campo adecuados para búsqueda.
 *
 * Tipos elegidos:
 * - title, author: search_as_you_type → búsqueda por prefijo y sugerencias al escribir
 * - isbn, category: keyword → filtros exactos y agregaciones
 * - price, stock, publicationYear, rating: numéricos para filtros y rangos
 * - visible: boolean para filtro
 */
@Document(indexName = "books")
public class BookDocument {

    @Id
    private Long id;

    /** Búsqueda por texto y autocompletado (sugerencias al escribir). */
    @Field(type = FieldType.Search_As_You_Type)
    private String title;

    /** Búsqueda por texto y autocompletado por autor. */
    @Field(type = FieldType.Search_As_You_Type)
    private String author;

    /** Identificador único; búsqueda exacta. */
    @Field(type = FieldType.Keyword)
    private String isbn;

    @Field(type = FieldType.Double)
    private Double price;

    @Field(type = FieldType.Integer)
    private Integer stock;

    /** Categoría: filtros exactos y facetas. */
    @Field(type = FieldType.Keyword)
    private String category;

    @Field(type = FieldType.Integer)
    private Integer publicationYear;

    @Field(type = FieldType.Integer)
    private Integer rating;

    @Field(type = FieldType.Boolean)
    private Boolean visible;

    public BookDocument() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public String getIsbn() {
        return isbn;
    }

    public void setIsbn(String isbn) {
        this.isbn = isbn;
    }

    public Double getPrice() {
        return price;
    }

    public void setPrice(Double price) {
        this.price = price;
    }

    public Integer getStock() {
        return stock;
    }

    public void setStock(Integer stock) {
        this.stock = stock;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public Integer getPublicationYear() {
        return publicationYear;
    }

    public void setPublicationYear(Integer publicationYear) {
        this.publicationYear = publicationYear;
    }

    public Integer getRating() {
        return rating;
    }

    public void setRating(Integer rating) {
        this.rating = rating;
    }

    public Boolean getVisible() {
        return visible;
    }

    public void setVisible(Boolean visible) {
        this.visible = visible;
    }
}
