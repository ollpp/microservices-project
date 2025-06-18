-- ===================================
-- Order Service Database Schema (PDB 환경)
-- ===================================

-- XEPDB1에서 Order Service 사용자로 연결
CONNECT ORDER_SERVICE/order123@XEPDB1;

-- 기존 테이블이 있다면 삭제 (개발용)
BEGIN
EXECUTE IMMEDIATE 'DROP TABLE order_items CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE orders CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP SEQUENCE orders_seq';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP SEQUENCE order_items_seq';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

-- ===================================
-- ORDERS 테이블 생성
-- ===================================
CREATE TABLE orders (
                        id NUMBER(19) PRIMARY KEY,
                        user_id NUMBER(19) NOT NULL,
                        order_number VARCHAR2(50) UNIQUE NOT NULL,
                        total_amount NUMBER(12,2) NOT NULL CHECK (total_amount >= 0),
                        discount_amount NUMBER(12,2) DEFAULT 0 CHECK (discount_amount >= 0),
                        tax_amount NUMBER(12,2) DEFAULT 0 CHECK (tax_amount >= 0),
                        final_amount NUMBER(12,2) NOT NULL CHECK (final_amount >= 0),
                        status VARCHAR2(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED')),
                        payment_status VARCHAR2(20) DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'PAID', 'FAILED', 'REFUNDED')),
                        payment_method VARCHAR2(50),
                        shipping_address CLOB,
                        order_notes CLOB,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        shipped_at TIMESTAMP,
                        delivered_at TIMESTAMP
);

-- ===================================
-- ORDER_ITEMS 테이블 생성
-- ===================================
CREATE TABLE order_items (
                             id NUMBER(19) PRIMARY KEY,
                             order_id NUMBER(19) NOT NULL,
                             product_id NUMBER(19) NOT NULL,
                             product_name VARCHAR2(100) NOT NULL,
                             product_sku VARCHAR2(50),
                             quantity NUMBER(10) NOT NULL CHECK (quantity > 0),
                             unit_price NUMBER(10,2) NOT NULL CHECK (unit_price >= 0),
                             total_price NUMBER(12,2) NOT NULL CHECK (total_price >= 0),
                             discount_amount NUMBER(10,2) DEFAULT 0 CHECK (discount_amount >= 0),
                             created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 외래키 제약조건
                             CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- ===================================
-- 시퀀스 생성
-- ===================================
CREATE SEQUENCE orders_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE order_items_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- ===================================
-- 주문 트리거 생성 (자동 ID 및 주문번호 할당)
-- ===================================
CREATE OR REPLACE TRIGGER orders_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := orders_seq.NEXTVAL;
END IF;
    :NEW.created_at := CURRENT_TIMESTAMP;
    :NEW.updated_at := CURRENT_TIMESTAMP;

    -- 주문번호 자동 생성 (없는 경우)
    IF :NEW.order_number IS NULL THEN
        :NEW.order_number := 'ORD-' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '-' || LPAD(:NEW.id, 6, '0');
END IF;

    -- final_amount 계산
    :NEW.final_amount := :NEW.total_amount - NVL(:NEW.discount_amount, 0) + NVL(:NEW.tax_amount, 0);
END;
/

-- ===================================
-- 주문 업데이트 트리거
-- ===================================
CREATE OR REPLACE TRIGGER orders_update_trigger
    BEFORE UPDATE ON orders
                      FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;

    -- 상태 변경에 따른 타임스탬프 업데이트
    IF :NEW.status = 'SHIPPED' AND :OLD.status != 'SHIPPED' THEN
        :NEW.shipped_at := CURRENT_TIMESTAMP;
END IF;

    IF :NEW.status = 'DELIVERED' AND :OLD.status != 'DELIVERED' THEN
        :NEW.delivered_at := CURRENT_TIMESTAMP;
END IF;

    -- final_amount 재계산
    :NEW.final_amount := :NEW.total_amount - NVL(:NEW.discount_amount, 0) + NVL(:NEW.tax_amount, 0);
END;
/

-- ===================================
-- 주문 아이템 트리거 생성
-- ===================================
CREATE OR REPLACE TRIGGER order_items_trigger
    BEFORE INSERT ON order_items
    FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := order_items_seq.NEXTVAL;
END IF;
    :NEW.created_at := CURRENT_TIMESTAMP;

    -- total_price 계산
    :NEW.total_price := (:NEW.quantity * :NEW.unit_price) - NVL(:NEW.discount_amount, 0);
END;
/

-- ===================================
-- 인덱스 생성 (성능 최적화)
-- ===================================
-- Orders 인덱스
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_orders_order_number ON orders(order_number);

-- Order Items 인덱스
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- ===================================
-- 샘플 데이터 삽입 (테스트용)
-- ===================================

-- 샘플 주문 1
INSERT INTO orders (user_id, total_amount, tax_amount, payment_method, shipping_address) VALUES
    (1, 3500000, 350000, 'CREDIT_CARD', '서울특별시 강남구 테헤란로 123');

-- 샘플 주문 아이템 1
INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price) VALUES
    (1, 1, 'MacBook Pro 16"', 'PRD-000001', 1, 3500000);

-- 샘플 주문 2
INSERT INTO orders (user_id, total_amount, tax_amount, payment_method, shipping_address) VALUES
    (2, 1850000, 185000, 'BANK_TRANSFER', '부산광역시 해운대구 해운대로 456');

-- 샘플 주문 아이템 2
INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price) VALUES
    (2, 2, 'iPhone 15 Pro', 'PRD-000002', 1, 1500000);

INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price) VALUES
    (2, 4, 'AirPods Pro', 'PRD-000004', 1, 350000);

-- 커밋
COMMIT;

-- 로그 출력
PROMPT 'Order Service tables created successfully in XEPDB1!';