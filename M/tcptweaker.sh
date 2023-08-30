#!/bin/bash

clear
echo -e "\033[1;37m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;37m                      TCP TWEAKER                      \E[0m"
echo -e "\033[1;37m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# Verificar se as configurações já estão presentes
if grep -q "^#PH56" /etc/sysctl.conf; then
    echo ""
    echo "As configurações de rede TCP Tweaker já foram adicionadas no sistema!"
    echo ""
    read -p "Deseja remover as configurações do TCP Tweaker? [s/n]: " -e -i n resposta0
    if [[ "$resposta0" = 's' ]]; then
        grep -v "^#PH56" /etc/sysctl.conf > /tmp/syscl && mv /tmp/syscl /etc/sysctl.conf
        sysctl -p /etc/sysctl.conf > /dev/null
        echo ""
        echo "As configurações de rede do TCP Tweaker foram removidas com sucesso."
        echo ""
    else
        echo ""
    fi
    exit
fi

# Informar sobre o ajuste
echo ""
echo "ESTE SCRIPT IRÁ ALTERAR AS CONFIGURAÇÕES DE REDE DO"
echo "SISTEMA PARA REDUZIR A LATÊNCIA E MELHORAR A VELOCIDADE"
echo ""
read -p "Continuar com a instalação? [s/n]: " -e -i n resposta
if [[ "$resposta" != 's' ]]; then
    echo ""
    echo "A instalação foi cancelada pelo usuário!"
    echo ""
    exit
fi

# Adicionar as configurações de ajuste
echo ""
echo "Modificando as seguintes configurações:"
echo " " >> /etc/sysctl.conf
echo "#PH56 - TCP Tweaker" >> /etc/sysctl.conf
echo "net.ipv4.tcp_window_scaling = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_slow_start_after_idle = 0" >> /etc/sysctl.conf
sleep 2

# Recarregar configurações
echo ""
sysctl -p /etc/sysctl.conf

echo ""
echo "As configurações de rede do TCP Tweaker foram adicionadas com sucesso."
echo ""
exit
