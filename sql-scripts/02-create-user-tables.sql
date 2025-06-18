-- ===================================
-- User Service Database Schema (PDB 환경)
-- ===================================

-- XEPDB1에서 User Service 사용자로 연결
CONNECT USER_SERVICE/user123@XEPDB1;

-- 기존 테이블이 있다면 삭제 (개발용)
BEGIN
EXECUTE IMMEDIATE 'DROP TABLE users CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP SEQUENCE users_seq';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

-- ===================================
-- USERS 테이블 생성
-- ===================================
CREATE TABLE users (
                       id NUMBER(19) PRIMARY KEY,
                       username VARCHAR2(50) UNIQUE NOT NULL,
                       email VARCHAR2(100) UNIQUE NOT NULL,
                       password VARCHAR2(255) NOT NULL,
                       first_name VARCHAR2(50),
                       last_name VARCHAR2(50),
                       phone VARCHAR2(20),
                       address VARCHAR2(500),
                       status VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
                       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                       updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- 시퀀스 생성
-- ===================================
CREATE SEQUENCE users_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- ===================================
-- 트리거 생성 (자동 ID 할당)
-- ===================================
CREATE OR REPLACE TRIGGER users_trigger
    BEFORE INSERT ON users
    FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := users_seq.NEXTVAL;
END IF;
    :NEW.created_at := CURRENT_TIMESTAMP;
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

-- ===================================
-- 업데이트 트리거 생성
-- ===================================
CREATE OR REPLACE TRIGGER users_update_trigger
    BEFORE UPDATE ON users
                      FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

-- ===================================
-- 인덱스 생성 (성능 최적화)
-- ===================================
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

-- ===================================
-- 샘플 데이터 삽입 (테스트용)
-- ===================================
INSERT INTO users (username, email, password, first_name, last_name, phone) VALUES
    ('admin', 'admin@example.com', 'password123', 'Admin', 'User', '010-1234-5678');

INSERT INTO users (username, email, password, first_name, last_name, phone) VALUES
    ('john_doe', 'john@example.com', 'password123', 'John', 'Doe', '010-2345-6789');

INSERT INTO users (username, email, password, first_name, last_name, phone) VALUES
    ('jane_smith', 'jane@example.com', 'password123', 'Jane', 'Smith', '010-3456-7890');

-- 커밋
COMMIT;

-- 로그 출력
PROMPT 'User Service tables created successfully in XEPDB1!';