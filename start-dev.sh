#!/bin/bash

# Script para iniciar o servidor de desenvolvimento
# Garante que apenas uma instância rode por vez

LOCKFILE="/tmp/lanchonete-dev.lock"
PIDFILE="/tmp/lanchonete-dev.pid"

# Função para limpar ao sair
cleanup() {
    echo "Limpando..."
    rm -f "$LOCKFILE" "$PIDFILE"
    pkill -P $$ 2>/dev/null
}

trap cleanup EXIT INT TERM

# Verifica se já existe uma instância rodando
if [ -f "$LOCKFILE" ]; then
    PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "❌ Erro: Servidor já está rodando (PID: $PID)"
        echo "Para parar: kill $PID"
        echo "Ou execute: ./stop-dev.sh"
        exit 1
    else
        echo "Removendo lock file antigo..."
        rm -f "$LOCKFILE" "$PIDFILE"
    fi
fi

# Mata processos órfãos do Vite
echo "Verificando processos órfãos..."
ORPHANS=$(pgrep -f 'node.*bin/vite' 2>/dev/null)
if [ -n "$ORPHANS" ]; then
    echo "Matando processos órfãos: $ORPHANS"
    pkill -9 -f 'node.*bin/vite' 2>/dev/null
    sleep 1
fi

# Libera a porta 5173 se estiver em uso
echo "Verificando porta 5173..."
PORT_PID=$(lsof -ti:5173 2>/dev/null)
if [ -n "$PORT_PID" ]; then
    echo "Liberando porta 5173 (PID: $PORT_PID)..."
    kill -9 $PORT_PID 2>/dev/null
    sleep 1
fi

# Cria lock file
touch "$LOCKFILE"
echo $$ > "$PIDFILE"

# Inicia o servidor
cd "$(dirname "$0")"
echo "🚀 Iniciando servidor Vite na porta 5173..."
echo "📝 PID do processo: $$"
echo "🛑 Para parar: ./stop-dev.sh ou Ctrl+C"
echo ""

npm run dev
