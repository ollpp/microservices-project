-- ===================================
-- Product Service Database Schema (PDB 환경)
-- ===================================

-- XEPDB1에서 Product Service 사용자로 연결
CONNECT PRODUCT_SERVICE/product123@XEPDB1;

-- 기존 테이블이 있다면 삭제 (개발용)
BEGIN
EXECUTE IMMEDIATE 'DROP TABLE products CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP SEQUENCE products_seq';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

-- ===================================
-- PRODUCTS 테이블 생성
-- ===================================
CREATE TABLE products (
                          id NUMBER(19) PRIMARY KEY,
                          name VARCHAR2(100) NOT NULL,
                          description CLOB,
                          price NUMBER(10,2) NOT NULL CHECK (price >= 0),
                          stock_quantity NUMBER(10) DEFAULT 0 CHECK (stock_quantity >= 0),
                          category VARCHAR2(50),
                          brand VARCHAR2(50),
                          sku VARCHAR2(50) UNIQUE,
                          weight NUMBER(8,2),
                          dimensions VARCHAR2(100),
                          status VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'DISCONTINUED')),
                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- 시퀀스 생성
-- ===================================
CREATE SEQUENCE products_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- ===================================
-- 트리거 생성 (자동 ID 할당)
-- ===================================
CREATE OR REPLACE TRIGGER products_trigger
    BEFORE INSERT ON products
    FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := products_seq.NEXTVAL;
END IF;
    :NEW.created_at := CURRENT_TIMESTAMP;
    :NEW.updated_at := CURRENT_TIMESTAMP;

    -- SKU 자동 생성 (없는 경우)
    IF :NEW.sku IS NULL THEN
        :NEW.sku := 'PRD-' || LPAD(:NEW.id, 6, '0');
END IF;
END;
/

-- ===================================
-- 업데이트 트리거 생성
-- ===================================
CREATE OR REPLACE TRIGGER products_update_trigger
    BEFORE UPDATE ON products
                      FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

-- ===================================
-- 인덱스 생성 (성능 최적화)
-- ===================================
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_price ON products(price);

-- ===================================
-- 샘플 데이터 삽입 (테스트용)
-- ===================================
INSERT INTO products (name, description, price, stock_quantity, category, brand) VALUES
    ('MacBook Pro 16"', 'Apple MacBook Pro 16inch M3 Pro', 3500000, 10, 'Laptop', 'Apple');

INSERT INTO products (name, description, price, stock_quantity, category, brand) VALUES
    ('iPhone 15 Pro', 'Apple iPhone 15 Pro 256GB', 1500000, 25, 'Smartphone', 'Apple');

INSERT INTO products (name, description, price, stock_quantity, category, brand) VALUES
    ('Galaxy S24 Ultra', 'Samsung Galaxy S24 Ultra 512GB', 1400000, 15, 'Smartphone', 'Samsung');

INSERT INTO products (name, description, price, stock_quantity, category, brand) VALUES
    ('AirPods Pro', 'Apple AirPods Pro 3rd Gen', 350000, 50, 'Audio', 'Apple');

INSERT INTO products (name, description, price, stock_quantity, category, brand) VALUES
    ('Dell XPS 13', 'Dell XPS 13 Intel i7 16GB RAM', 2200000, 8, 'Laptop', 'Dell');

-- 커밋
COMMIT;

-- 로그 출력
PROMPT 'Product Service tables created successfully in XEPDB1!';