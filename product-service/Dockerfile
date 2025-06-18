# Multi-stage build for Maven
FROM openjdk:17-jdk-slim as builder

# 작업 디렉토리 설정
WORKDIR /app

# Maven 설정 파일들 먼저 복사 (캐싱 최적화)
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

# Maven wrapper 실행 권한 부여
RUN chmod +x ./mvnw

# 의존성 다운로드 (캐싱을 위해 소스코드 복사 전에 실행)
RUN ./mvnw dependency:go-offline -B

# 소스코드 복사
COPY src src

# 애플리케이션 빌드 (테스트 스킵)
RUN ./mvnw clean package -DskipTests

# ===================================
# Runtime stage (실행 환경)
# ===================================
FROM openjdk:17-jre-slim

# 작업 디렉토리 설정
WORKDIR /app

# 로그 디렉토리 생성
RUN mkdir -p /app/logs

# curl 설치 (헬스체크용)
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 빌드 단계에서 생성된 JAR 파일 복사
COPY --from=builder /app/target/*.jar app.jar

# 포트 노출
EXPOSE 8080

# 헬스체크 설정
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# 애플리케이션 실행
ENTRYPOINT ["java", "-jar", "/app/app.jar"]