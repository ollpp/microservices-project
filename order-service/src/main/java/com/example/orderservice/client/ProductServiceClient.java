package com.example.orderservice.client;

import com.example.orderservice.dto.ProductDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.Arrays;
import java.util.List;

@Component
public class ProductServiceClient {

    @Autowired
    private RestTemplate restTemplate;

    @Value("${services.product-service.url}")
    private String productServiceUrl;

    public ProductDto getProductById(Long productId) {
        try {
            return restTemplate.getForObject(
                    productServiceUrl + "/api/products/" + productId,
                    ProductDto.class
            );
        } catch (Exception e) {
            throw new RuntimeException("Product service is unavailable");
        }
    }

    public List<ProductDto> getProductsByIds(List<Long> productIds) {
        try {
            ProductDto[] products = restTemplate.postForObject(
                    productServiceUrl + "/api/products/batch",
                    productIds,
                    ProductDto[].class
            );
            return Arrays.asList(products != null ? products : new ProductDto[0]);
        } catch (Exception e) {
            throw new RuntimeException("Product service is unavailable");
        }
    }

    public void updateStock(Long productId, Integer quantity) {
        try {
            restTemplate.put(
                    productServiceUrl + "/api/products/" + productId + "/stock?quantity=" + quantity,
                    null
            );
        } catch (Exception e) {
            throw new RuntimeException("Failed to update product stock");
        }
    }



}
