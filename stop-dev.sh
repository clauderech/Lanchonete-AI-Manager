#!/bin/bash

# Script para parar o servidor de desenvolvimento

LOCKFILE="/tmp/lanchonete-dev.lock"
PIDFILE="/tmp/lanchonete-dev.pid"

if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "🛑 Parando servidor (PID: $PID)..."
        kill "$PID" 2>/dev/null
        sleep 2
        
        # Se ainda estiver rodando, força
        if kill -0 "$PID" 2>/dev/null; then
            echo "Forçando parada..."
            kill -9 "$PID" 2>/dev/null
        fi
        echo "✅ Servidor parado"
    else
        echo "⚠️  Processo não está rodando"
    fi
    rm -f "$PIDFILE" "$LOCKFILE"
else
    echo "⚠️  Nenhum servidor em execução"
fi

# Mata qualquer processo órfão
ORPHANS=$(pgrep -f 'node.*bin/vite' 2>/dev/null)
if [ -n "$ORPHANS" ]; then
    echo "🧹 Limpando processos órfãos..."
    pkill -9 -f 'node.*bin/vite' 2>/dev/null
    pkill -9 -f 'npm.*dev' 2>/dev/null
    echo "✅ Limpo"
fi

echo "✨ Tudo pronto!"
