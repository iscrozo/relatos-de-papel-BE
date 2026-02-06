package com.relatosdepapel.payments.service.impl;

import com.relatosdepapel.payments.dto.PaymentDTO;
import com.relatosdepapel.payments.entity.Payment;
import com.relatosdepapel.payments.repository.PaymentRepository;
import com.relatosdepapel.payments.service.PaymentService;
import org.springframework.stereotype.Service;

import jakarta.persistence.criteria.Predicate;
import java.math.BigDecimal;
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
        if (payment.getStatus() == null) {
            payment.setStatus("PENDING");
        }
        if (payment.getQuantity() == null) {
            payment.setQuantity(1);
        }
        if (payment.getTotalAmount() == null && payment.getUnitPrice() != null) {
            payment.setTotalAmount(payment.getUnitPrice().multiply(java.math.BigDecimal.valueOf(payment.getQuantity())));
        }
        if (payment.getAmount() == null && payment.getTotalAmount() != null) {
            payment.setAmount(payment.getTotalAmount());
        }
        if (payment.getTransactionId() == null || payment.getTransactionId().isBlank()) {
            payment.setTransactionId("TXN-" + System.currentTimeMillis());
        }
        if (payment.getPaymentDate() == null) {
            payment.setPaymentDate(LocalDateTime.now());
        }
        Payment saved = repository.save(payment);
        return mapToDTO(saved);
    }

    @Override
    public PaymentDTO update(Long id, PaymentDTO paymentDTO) {
        Payment existing = repository.findById(id)
                .orElseThrow(() -> new RuntimeException(PAYMENT_NOT_FOUND));

        // Validaciones
        if (paymentDTO.getBookId() == null) {
            throw new IllegalArgumentException("bookId is required");
        }
        if (paymentDTO.getCustomerName() == null || paymentDTO.getCustomerName().isBlank()) {
            throw new IllegalArgumentException("customerName is required");
        }
        if (paymentDTO.getCustomerEmail() == null || paymentDTO.getCustomerEmail().isBlank()) {
            throw new IllegalArgumentException("customerEmail is required");
        }

        existing.setBookId(paymentDTO.getBookId());
        existing.setQuantity(paymentDTO.getQuantity() != null ? paymentDTO.getQuantity() : 1);
        existing.setUnitPrice(paymentDTO.getUnitPrice());
        
        // Calcular totalAmount si no viene
        if (paymentDTO.getTotalAmount() == null && paymentDTO.getUnitPrice() != null) {
            existing.setTotalAmount(paymentDTO.getUnitPrice().multiply(BigDecimal.valueOf(existing.getQuantity())));
        } else {
            existing.setTotalAmount(paymentDTO.getTotalAmount());
        }
        
        existing.setCustomerName(paymentDTO.getCustomerName());
        existing.setCustomerEmail(paymentDTO.getCustomerEmail());
        existing.setStatus(paymentDTO.getStatus());
        existing.setPaymentMethod(paymentDTO.getPaymentMethod());
        existing.setPaymentDate(paymentDTO.getPaymentDate() != null ? paymentDTO.getPaymentDate() : LocalDateTime.now());
        existing.setNotes(paymentDTO.getNotes());

        return mapToDTO(repository.save(existing));
    }

    @Override
    public PaymentDTO partialUpdate(Long id, Map<String, Object> fields) {
        Payment existing = repository.findById(id)
                .orElseThrow(() -> new RuntimeException(PAYMENT_NOT_FOUND));

        fields.forEach((key, value) -> {
            switch (key) {
                case "bookId" -> existing.setBookId(((Number) value).longValue());
                case "quantity" -> existing.setQuantity((Integer) value);
                case "unitPrice" -> existing.setUnitPrice(new java.math.BigDecimal(value.toString()));
                case "totalAmount" -> existing.setTotalAmount(new java.math.BigDecimal(value.toString()));
                case "customerName" -> existing.setCustomerName((String) value);
                case "customerEmail" -> existing.setCustomerEmail((String) value);
                case "status" -> existing.setStatus((String) value);
                case "paymentMethod" -> existing.setPaymentMethod((String) value);
                case "paymentDate" -> existing.setPaymentDate(LocalDateTime.parse(value.toString()));
                case "notes" -> existing.setNotes((String) value);
                default -> { /* campo desconocido */ }
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
        dto.setQuantity(payment.getQuantity());
        dto.setUnitPrice(payment.getUnitPrice());
        dto.setTotalAmount(payment.getTotalAmount());
        dto.setCustomerName(payment.getCustomerName());
        dto.setCustomerEmail(payment.getCustomerEmail());
        dto.setStatus(payment.getStatus());
        dto.setPaymentMethod(payment.getPaymentMethod());
        dto.setTransactionId(payment.getTransactionId());
        dto.setPaymentDate(payment.getPaymentDate());
        dto.setNotes(payment.getNotes());
        return dto;
    }

    private Payment mapToEntity(PaymentDTO dto) {
        Payment payment = new Payment();
        payment.setBookId(dto.getBookId());
        payment.setQuantity(dto.getQuantity() != null ? dto.getQuantity() : 1);
        BigDecimal price = dto.getUnitPrice() != null ? dto.getUnitPrice() : dto.getAmount();
        BigDecimal total = dto.getTotalAmount() != null ? dto.getTotalAmount() : (dto.getAmount() != null ? dto.getAmount() : BigDecimal.ZERO);
        payment.setUnitPrice(price != null ? price : BigDecimal.ZERO);
        payment.setTotalAmount(total);
        payment.setCustomerName(dto.getCustomerName() != null ? dto.getCustomerName() : "Cliente");
        payment.setCustomerEmail(dto.getCustomerEmail() != null ? dto.getCustomerEmail() : "cliente@email.com");
        payment.setStatus(dto.getStatus());
        payment.setPaymentMethod(dto.getPaymentMethod());
        payment.setTransactionId(dto.getTransactionId());
        payment.setPaymentDate(dto.getPaymentDate());
        payment.setNotes(dto.getNotes());
        return payment;
    }
}
