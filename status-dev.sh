#!/bin/bash

# Script para verificar o status do servidor

LOCKFILE="/tmp/lanchonete-dev.lock"
PIDFILE="/tmp/lanchonete-dev.pid"

echo "📊 Status do Servidor de Desenvolvimento"
echo "=========================================="
echo ""

# Verifica lock file
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "✅ Status: RODANDO"
        echo "📝 PID: $PID"
        echo "🔗 URL: http://192.168.15.3:5173/"
        echo ""
        echo "Informações do processo:"
        ps aux | grep "$PID" | grep -v grep | head -1
    else
        echo "⚠️  Status: PARADO (lock file órfão)"
        echo "Execute: ./stop-dev.sh para limpar"
    fi
else
    echo "⚠️  Status: PARADO"
fi

echo ""
echo "Processos Vite ativos:"
PROCS=$(pgrep -f 'node.*bin/vite' 2>/dev/null)
if [ -z "$PROCS" ]; then
    echo "  Nenhum"
else
    echo "  PIDs: $PROCS"
    ps aux | grep 'node.*bin/vite' | grep -v grep
fi

echo ""
echo "Porta 5173:"
if lsof -i :5173 &>/dev/null || ss -tln | grep -q ':5173'; then
    echo "  ✅ Em uso"
    lsof -i :5173 2>/dev/null || ss -tlnp | grep ':5173'
else
    echo "  ⚪ Livre"
fi
