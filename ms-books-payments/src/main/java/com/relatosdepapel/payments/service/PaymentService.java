package com.relatosdepapel.payments.service;

import com.relatosdepapel.payments.dto.PaymentDTO;

import java.util.List;
import java.util.Map;

public interface PaymentService {

    PaymentDTO create(PaymentDTO paymentDTO);

    PaymentDTO update(Long id, PaymentDTO paymentDTO);

    PaymentDTO partialUpdate(Long id, Map<String, Object> fields);

    void delete(Long id);

    PaymentDTO findById(Long id);

    List<PaymentDTO> findAll();

    List<PaymentDTO> search(
            Long bookId,
            String status,
            String paymentMethod
    );
}
