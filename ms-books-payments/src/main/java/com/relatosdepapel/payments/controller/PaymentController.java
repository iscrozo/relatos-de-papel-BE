package com.relatosdepapel.payments.controller;

import com.relatosdepapel.payments.dto.PaymentDTO;
import com.relatosdepapel.payments.service.PaymentService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    private final PaymentService service;

    public PaymentController(PaymentService service) {
        this.service = service;
    }

    // Crear pago
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PaymentDTO create(@RequestBody PaymentDTO paymentDTO) {
        return service.create(paymentDTO);
    }

    // Obtener todos los pagos
    @GetMapping
    public List<PaymentDTO> getAll() {
        return service.findAll();
    }

    // Obtener pago por ID
    @GetMapping("/{id}")
    public PaymentDTO getById(@PathVariable Long id) {
        return service.findById(id);
    }

    // Buscar pagos con filtros
    @GetMapping("/search")
    public List<PaymentDTO> search(
            @RequestParam(required = false) Long bookId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String paymentMethod
    ) {
        return service.search(bookId, status, paymentMethod);
    }

    // Actualizar pago
    @PutMapping("/{id}")
    public PaymentDTO update(
            @PathVariable Long id,
            @RequestBody PaymentDTO paymentDTO
    ) {
        return service.update(id, paymentDTO);
    }

    // Actualizar pago parcialmente
    @PatchMapping("/{id}")
    public PaymentDTO partialUpdate(
            @PathVariable Long id,
            @RequestBody Map<String, Object> fields
    ) {
        return service.partialUpdate(id, fields);
    }

    // Eliminar pago
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
