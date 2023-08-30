#!/bin/bash

DATABASE="activation.db"
ACTIVE_PORTS=("443" "80" "8080")

# Função para ativar uma chave
activate_key() {
    local key="$1"
    local ip="$2"
    # Verificar se a chave já está ativada ou expirada no banco de dados
    if sqlite3 "$DATABASE" "SELECT * FROM activation_keys WHERE key='$key' AND (used=1 OR datetime('now') > expiry)"; then
        echo "Chave inválida ou expirada."
        return 1
    fi
    # Ativar a chave
    sqlite3 "$DATABASE" "UPDATE activation_keys SET used=1, ip='$ip' WHERE key='$key'"
    echo "Chave ativada com sucesso para o IP $ip."
}

# Função para verificar se uma chave está ativada
check_key() {
    local key="$1"
    if sqlite3 "$DATABASE" "SELECT * FROM activation_keys WHERE key='$key' AND used=1"; then
        echo "Chave válida e ativada."
    else
        echo "Chave inválida ou não ativada."
    fi
}

# Função para desativar uma chave (marcar como usada)
deactivate_key() {
    local key="$1"
    sqlite3 "$DATABASE" "UPDATE activation_keys SET used=1 WHERE key='$key'"
    echo "Chave desativada com sucesso."
}

# Função para consultar o banco de dados
query_database() {
    local query="$1"
    sqlite3 "$DATABASE" "$query"
}

# Função para verificar se uma porta está ativa
check_port() {
    local port="$1"
    nc -z -w5 localhost "$port" >/dev/null 2>&1
}

# Função para desativar as portas caso o IP não esteja associado a uma chave
deactivate_ports() {
    local ip="$1"
    for port in "${ACTIVE_PORTS[@]}"; do
        if ! check_key_by_ip "$ip"; then
            echo "IP do servidor não associado a nenhuma chave. Desativando porta $port."
            # Aqui você pode adicionar comandos para desativar a porta, por exemplo:
            # iptables -A INPUT -p tcp --dport "$port" -j DROP
        fi
    done
}

# Função para verificar se o IP está associado a alguma chave
check_key_by_ip() {
    local ip="$1"
    if sqlite3 "$DATABASE" "SELECT * FROM activation_keys WHERE ip='$ip' AND used=1"; then
        return 0
    else
        return 1
    fi
}

# Função para instalar o SSL
inst_ssl() {
    apt-get install stunnel4 -y
    cat <<EOF > /etc/stunnel/stunnel.conf
client = no
[SSL]
cert = /etc/stunnel/stunnel.pem
accept = 443
connect = 127.0.0.1:80
EOF
    openssl genrsa -out stunnel.key 2048 > /dev/null 2>&1
    (for _ in {1..6}; do echo ""; done; echo "@cloudflare") | openssl req -new -key stunnel.key -x509 -days 1000 -out stunnel.crt
    cat stunnel.crt stunnel.key > /etc/stunnel/stunnel.pem
    sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
    service stunnel4 restart
    rm -rf /etc/ger-frm/stunnel.crt
    rm -rf /etc/ger-frm/stunnel.key
    rm -rf /root/stunnel.crt
    rm -rf /root/stunnel.key
}

# Função para configurar o Python
inst_py() {
    pkill -f 80
    pkill python
    apt install python screen -y

    pt=$(netstat -nplt | grep 'sshd' | awk -F ":" NR==1{'print $2'} | cut -d " " -f 1)

    cat <<'EOF' > proxy.py
# ... (o restante do seu script Python)
EOF

    screen -dmS pythonwe python proxy.py -p 80 &
}

clear && clear
echo -e "\033[1;31m———————————————————————————————————————————————————\033[1;37m"
echo -e "\033[1;32m             MODDERAJUDA WEBSOCKET SSH "
echo -e "\033[1;31m———————————————————————————————————————————————————\033[1;37m"
echo -e "\033[1;37m      WEBSOCKET SSH USARÁ A PORTA 80 e 443"
echo
echo -e "\033[1;37m                 INSTALANDO SSL... "
fun_bar 'inst_ssl'
echo -e "\033[1;37m                 CONFIGURANDO SSL.. "
fun_bar 'inst_ssl'
read -rp "  STATUS DE CONEXÃO : " msgbanner
[[ -z "$msgbanner" ]] && msgbanner="SSL + Pay"
echo
echo -e "\033[1;37m                 CONFIGURANDO PYTHON.. "
fun_bar 'inst_py'
rm -rf proxy.py
echo -e "                 INSTALAÇÃO CONCLUÍDA "
echo
