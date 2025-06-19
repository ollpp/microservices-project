package com.example.orderservice.service;

import com.example.orderservice.client.ProductServiceClient;
import com.example.orderservice.client.UserServiceClient;
import com.example.orderservice.dto.OrderRequest;
import com.example.orderservice.dto.ProductDto;
import com.example.orderservice.dto.UserDto;
import com.example.orderservice.entity.Order;
import com.example.orderservice.entity.OrderItem;
import com.example.orderservice.entity.OrderStatus;
import com.example.orderservice.repository.OrderRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserServiceClient userServiceClient;

    @Autowired
    private ProductServiceClient productServiceClient;

    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }

    public Optional<Order> getOrderById(Long id) {
        return orderRepository.findById(id);
    }

    public List<Order> getOrdersByUserId(Long userId) {
        return orderRepository.findByUserId(userId);
    }

    public List<Order> getOrdersByStatus(OrderStatus status) {
        return orderRepository.findByStatus(status);
    }

    @Transactional
    public Order createOrder(OrderRequest orderRequest) {

        // 1. 사용자 존재 여부 확인
        UserDto user = userServiceClient.getUserById(orderRequest.getUserId());
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        // 2. 상품 정보 및 재고 확인
        List<Long> productIds = orderRequest.getItems().stream()
                .map(OrderRequest.OrderItemRequest::getProductId)
                .toList();

        List<ProductDto> products = productServiceClient.getProductsByIds(productIds);

        if (products.size() != productIds.size()) {
            throw new RuntimeException("Products not found");
        }

        // 3. 주문 생성
        Order order = new Order();
        order.setUserId(orderRequest.getUserId());
        order.setStatus(OrderStatus.PENDING);

        BigDecimal totalAmount = BigDecimal.ZERO;

        // 4. 주문 아이템 생성
        for (OrderRequest.OrderItemRequest itemRequest : orderRequest.getItems()) {

            ProductDto product = products.stream()
                    .filter(p -> p.getId().equals(itemRequest.getProductId()))
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("Product not found"));

            if (product.getStockQuantity() < itemRequest.getQuantity()) {
                throw new RuntimeException("Product stock quantity less than stock quantity");
            }

            OrderItem orderItem = new OrderItem();
            orderItem.setProductId(product.getId());
            orderItem.setQuantity(itemRequest.getQuantity());
            orderItem.setUnitPrice(product.getPrice());

            BigDecimal itemTotal = product.getPrice().multiply(BigDecimal.valueOf(itemRequest.getQuantity()));
            totalAmount = totalAmount.add(itemTotal);

            if (order.getOrderItems() == null) {
                order.setOrderItems(new ArrayList<>());
            }
            order.getOrderItems().add(orderItem);

        }

        order.setTotalAmount(totalAmount);

        // 5. 주문 저장
        Order savedOrder = orderRepository.save(order);

        // 6. 재고 업데이트
        for (OrderRequest.OrderItemRequest itemRequest : orderRequest.getItems()) {
            productServiceClient.updateStock(itemRequest.getProductId(), itemRequest.getQuantity());
        }

        return savedOrder;
    }

    public Order updateOrderStatus(Long id, OrderStatus status) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        order.setStatus(status);
        return orderRepository.save(order);
    }

    public void deleteOrder(Long id) {
        orderRepository.deleteById(id);
    }


}
