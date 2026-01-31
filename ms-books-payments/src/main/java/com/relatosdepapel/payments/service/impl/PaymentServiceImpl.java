package com.relatosdepapel.payments.service.impl;

import com.relatosdepapel.payments.dto.PaymentDTO;
import com.relatosdepapel.payments.entity.Payment;
import com.relatosdepapel.payments.repository.PaymentRepository;
import com.relatosdepapel.payments.service.PaymentService;
import org.springframework.stereotype.Service;

import jakarta.persistence.criteria.Predicate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class PaymentServiceImpl implements PaymentService {

    private static final String PAYMENT_NOT_FOUND = "Payment not found";

    private final PaymentRepository repository;

    public PaymentServiceImpl(PaymentRepository repository) {
        this.repository = repository;
    }

    @Override
    public PaymentDTO create(PaymentDTO paymentDTO) {
        Payment payment = mapToEntity(paymentDTO);
        if (payment.getPaymentDate() == null) {
            payment.setPaymentDate(LocalDateTime.now());
        }
        if (payment.getStatus() == null) {
            payment.setStatus("PENDING");
        }
        Payment saved = repository.save(payment);
        return mapToDTO(saved);
    }

    @Override
    public PaymentDTO update(Long id, PaymentDTO paymentDTO) {
        Payment existing = repository.findById(id)
                .orElseThrow(() -> new RuntimeException(PAYMENT_NOT_FOUND));

        existing.setBookId(paymentDTO.getBookId());
        existing.setAmount(paymentDTO.getAmount());
        existing.setStatus(paymentDTO.getStatus());
        existing.setPaymentMethod(paymentDTO.getPaymentMethod());
        existing.setPaymentDate(paymentDTO.getPaymentDate());

        return mapToDTO(repository.save(existing));
    }

    @Override
    public PaymentDTO partialUpdate(Long id, Map<String, Object> fields) {
        Payment existing = repository.findById(id)
                .orElseThrow(() -> new RuntimeException(PAYMENT_NOT_FOUND));

        fields.forEach((key, value) -> {
            switch (key) {
                case "bookId" -> existing.setBookId(((Number) value).longValue());
                case "amount" -> existing.setAmount(new java.math.BigDecimal(value.toString()));
                case "status" -> existing.setStatus((String) value);
                case "paymentMethod" -> existing.setPaymentMethod((String) value);
                case "paymentDate" -> 
                        existing.setPaymentDate(LocalDateTime.parse(value.toString()));
                default -> {
                    // campo desconocido
                }
            }
        });

        return mapToDTO(repository.save(existing));
    }

    @Override
    public void delete(Long id) {
        repository.deleteById(id);
    }

    @Override
    public PaymentDTO findById(Long id) {
        return repository.findById(id)
                .map(this::mapToDTO)
                .orElseThrow(() -> new RuntimeException(PAYMENT_NOT_FOUND));
    }

    @Override
    public List<PaymentDTO> findAll() {
        return repository.findAll()
                .stream()
                .map(this::mapToDTO)
                .toList();
    }

    @Override
    public List<PaymentDTO> search(Long bookId, String status, String paymentMethod) {
        return repository.findAll((root, query, cb) -> {

            List<Predicate> predicates = new ArrayList<>();

            if (bookId != null) {
                predicates.add(cb.equal(root.get("bookId"), bookId));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            if (paymentMethod != null) {
                predicates.add(cb.equal(root.get("paymentMethod"), paymentMethod));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        }).stream()
          .map(this::mapToDTO)
          .toList();
    }

    private PaymentDTO mapToDTO(Payment payment) {
        PaymentDTO dto = new PaymentDTO();
        dto.setId(payment.getId());
        dto.setBookId(payment.getBookId());
        dto.setAmount(payment.getAmount());
        dto.setStatus(payment.getStatus());
        dto.setPaymentMethod(payment.getPaymentMethod());
        dto.setPaymentDate(payment.getPaymentDate());
        return dto;
    }

    private Payment mapToEntity(PaymentDTO dto) {
        Payment payment = new Payment();
        payment.setBookId(dto.getBookId());
        payment.setAmount(dto.getAmount());
        payment.setStatus(dto.getStatus());
        payment.setPaymentMethod(dto.getPaymentMethod());
        payment.setPaymentDate(dto.getPaymentDate());
        return payment;
    }
}
