#!/bin/bash

echo "=== 1. TẠO CUSTOM BRIDGE NETWORK ==="
docker network create --driver bridge app-net

echo "=== 2. TẠO NAMED VOLUME ==="
docker volume create db-data

echo "=== 3. KHỞI CHẠY DATABASE CONTAINER (db-server) ==="
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=testdb \
  postgres:15-alpine

echo "=== 4. KHỞI CHẠY BACKEND CONTAINER (app-container) ==="
docker run -d \
  --name app-container \
  --network app-net \
  -e DB_HOST=db-server \
  -e DB_USER=myuser \
  -e DB_PASS=mypassword \
  -e DB_NAME=testdb \
  alpine sleep 3600

echo "=== HOÀN TẤT THIẾT LẬP CỤM CONTAINER ==="
