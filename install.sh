
#PHP, Mysql e Extensões
echo "Instalando PHP, MySQL e Extensões..."
sudo apt update && sudo apt install -y php php8.3-common git nginx mariadb-server mariadb-client curl

echo "A instalação está em andamento. Isso pode levar algum tempo..."

# Solicitar a senha root do MariaDB
read -s -p "Digite a senha root para o MariaDB (deixe em branco para senha vazia): " db_root_password
echo

# Exibir mensagem de configuração segura do MariaDB
echo -e "Configurando o MariaDB de forma segura..."

# Executar a configuração segura do MariaDB automaticamente
sudo mysql_secure_installation <<EOF

Y
$db_root_password
$db_root_password
Y
Y
Y
Y
EOF

# Exibir mensagem de conclusão
echo -e "\e[1;32mConfiguração do MariaDB concluída com sucesso!\e[0m"