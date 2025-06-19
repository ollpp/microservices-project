package com.example.orderservice.dto;

import lombok.Data;
import lombok.Getter;

import java.util.List;

@Data
@Getter
public class OrderRequest {

    private Long userId;
    private List<OrderItemRequest> items;

    @Data
    public static class OrderItemRequest {
        private Long productId;
        private Integer quantity;
    }

}
