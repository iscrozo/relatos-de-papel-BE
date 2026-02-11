package com.relatosdepapel.catalogue.repository;

import com.relatosdepapel.catalogue.document.BookDocument;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BookSearchRepository extends ElasticsearchRepository<BookDocument, Long> {
}
