# Bài 4: Thiết lập Custom Network & Named Volume bằng Docker CLI

## 1. Mục tiêu
- Tạo Custom Bridge Network (`app-net`) để các Container giao tiếp nội bộ qua tên service (DNS resolution).
- Tạo Named Volume (`db-data`) để lưu trữ dữ liệu bền vững (Data Persistence) cho Database PostgreSQL.

---

## 2. Thực thi Script khởi tạo cụm Container (`commands.sh`)

Cấp quyền thực thi và chạy script:
```bash
chmod +x commands.sh
./commands.sh
```

**Nội dung thực thi của script:**
1. Tạo Custom Bridge Network `app-net`:
   ```bash
   docker network create --driver bridge app-net
   ```
2. Tạo Named Volume `db-data`:
   ```bash
   docker volume create db-data
   ```
3. Khởi chạy Database Container `db-server` (gắn volume `db-data` và mạng `app-net`):
   ```bash
   docker run -d \
     --name db-server \
     --network app-net \
     -v db-data:/var/lib/postgresql/data \
     -e POSTGRES_USER=myuser \
     -e POSTGRES_PASSWORD=mypassword \
     -e POSTGRES_DB=testdb \
     postgres:15-alpine
   ```
4. Khởi chạy Backend Container `app-container` (kết nối mạng `app-net` và cấu hình biến môi trường kết nối DB):
   ```bash
   docker run -d \
     --name app-container \
     --network app-net \
     -e DB_HOST=db-server \
     -e DB_USER=myuser \
     -e DB_PASS=mypassword \
     -e DB_NAME=testdb \
     alpine sleep 3600
   ```

---

## 3. Kiểm tra Network & DNS Resolution

### 3.1. Kiểm tra sự tồn tại của Network & Volume
```bash
docker network ls | grep app-net
docker volume ls | grep db-data
```
**Kết quả:**
```text
b7a473b6ac3b   app-net   bridge    local
local     db-data
```

### 3.2. Kiểm tra chi tiết mạng `app-net`
```bash
docker network inspect app-net
```
*(Hiển thị 2 container `db-server` và `app-container` cùng thuộc subnet `172.18.0.0/16`)*

### 3.3. Kiểm tra phân giải tên miền nội bộ (DNS resolution) từ Backend Container
```bash
docker exec -it app-container ping -c 2 db-server
```
**Kết quả:**
```text
PING db-server (172.18.0.2) 56(84) bytes of data.
64 bytes from db-server.app-net (172.18.0.2): icmp_seq=1 ttl=64 time=0.217 ms
64 bytes from db-server.app-net (172.18.0.2): icmp_seq=2 ttl=64 time=0.095 ms

--- db-server ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1059ms
rtt min/avg/max/mdev = 0.095/0.156/0.217/0.061 ms
```
*(Backend container phân giải thành công hostname `db-server` sang IP nội bộ `172.18.0.2`).*

---

## 4. Kiểm tra Data Persistence (Lưu trữ bền vững)

### Bước 1: Thêm dữ liệu mẫu vào Database `db-server`
```bash
docker exec -i db-server psql -U myuser -d testdb <<EOF
CREATE TABLE students (id SERIAL PRIMARY KEY, name VARCHAR(50));
INSERT INTO students (name) VALUES ('Nguyen Van A'), ('Tran Thi B');
SELECT * FROM students;
EOF
```
**Kết quả:**
```text
CREATE TABLE
INSERT 0 2
 id |     name
----+--------------
  1 | Nguyen Van A
  2 | Tran Thi B
(2 rows)
```

### Bước 2: Xóa cứng Container Database
```bash
docker rm -f db-server
```

### Bước 3: Khởi chạy lại Container Database mới gắn cùng Named Volume `db-data`
```bash
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=testdb \
  postgres:15-alpine
```

### Bước 4: Xác minh dữ liệu không bị mất
```bash
docker exec -i db-server psql -U myuser -d testdb -c "SELECT * FROM students;"
```
**Kết quả:**
```text
 id |     name
----+--------------
  1 | Nguyen Van A
  2 | Tran Thi B
(2 rows)
```
*(Dữ liệu vẫn được giữ nguyên vẹn sau khi xóa và tạo lại container nhờ Named Volume `db-data`).*
