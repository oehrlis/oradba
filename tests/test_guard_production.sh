#!/usr/bin/env bash
# Test script to debug the production syntax error

echo "=== Bash Version ==="
bash --version

echo ""
echo "=== File Info ==="
file /opt/oracle/local/oradba/lib/oradba_common.sh

echo ""
echo "=== Checksum ==="
cksum /opt/oracle/local/oradba/lib/oradba_common.sh

echo ""
echo "=== Line Endings Check ==="
# Check for CRLF
if grep -q $'\r' /opt/oracle/local/oradba/lib/oradba_common.sh; then
    echo "WARNING: File contains CRLF (Windows) line endings!"
else
    echo "OK: File uses LF (Unix) line endings"
fi

echo ""
echo "=== Guard Section (lines 118-150) ===" 
sed -n '118,150p' /opt/oracle/local/oradba/lib/oradba_common.sh

echo ""
echo "=== Count if statements in guard ==="
sed -n '118,147p' /opt/oracle/local/oradba/lib/oradba_common.sh | grep -c "if \[\["

echo ""
echo "=== Count fi statements in guard ==="
sed -n '118,147p' /opt/oracle/local/oradba/lib/oradba_common.sh | grep -c "^[[:space:]]*fi"

echo ""
echo "=== Syntax check on full file ==="
bash -n /opt/oracle/local/oradba/lib/oradba_common.sh
if [[ $? -eq 0 ]]; then
    echo "OK: No syntax errors found"
else
    echo "FAILED: Syntax errors detected"
fi

echo ""
echo "=== Test minimal guard structure ==="
cat > /tmp/test_guard_minimal.sh << 'EOF'
#!/usr/bin/env bash
if [[ -z "${LOG_COLOR_DEBUG+x}" ]]; then
    export ORADBA_COMMON_SOURCED="true"
    
    if [[ -t 2 ]] && [[ "${ORADBA_NO_COLOR:-0}" != "1" ]]; then
        readonly LOG_COLOR_DEBUG="\033[0;36m"
    else
        readonly LOG_COLOR_DEBUG=""
    fi
fi

oradba_log() {
    echo "test"
}

oradba_log
EOF

bash /tmp/test_guard_minimal.sh
if [[ $? -eq 0 ]]; then
    echo "OK: Minimal guard structure works"
else
    echo "FAILED: Minimal guard structure fails"
fi

echo ""
echo "=== Test sourcing minimal guard ==="
bash -c 'source /tmp/test_guard_minimal.sh 2>&1'
if [[ $? -eq 0 ]]; then
    echo "OK: Can source minimal guard"
else
    echo "FAILED: Cannot source minimal guard"
fi

echo ""
echo "=== Attempt to source actual oradba_common.sh ==="
bash -c 'source /opt/oracle/local/oradba/lib/oradba_common.sh 2>&1' || echo "FAILED as expected"

echo ""
echo "=== Shell options ==="
set -o

echo ""
echo "=== Check for hidden characters around line 156 ==="
sed -n '145,160p' /opt/oracle/local/oradba/lib/oradba_common.sh | od -c | head -30
