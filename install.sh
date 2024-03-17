YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#PHP, Mysql e Extensões
echo -e "${YELLOW}Instalando PHP, MySQL e Extensões...${NC}"
sudo apt update && sudo apt install -y php php8.3-common git nginx mariadb-server mariadb-client curl

echo -e "${YELLOW}A instalação está em andamento. Isso pode levar algum tempo...${NC}"

# Solicitar a senha root do MariaDB
echo -e "${YELLOW}Digite a senha root para o MariaDB (deixe em branco para senha vazia):${NC} " 
stty -echo
read db_root_password
stty echo

# Exibir mensagem de configuração segura do MariaDB
echo -e "${YELLOW}Configurando o MariaDB de forma segura...${NC}"

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
echo -e "${GREEN}Configuração do MariaDB concluída com sucesso!${NC}"

# Solicita ao usuário o nome do banco de dados
echo -e "${YELLOW}Digite o nome do banco de dados:${NC}"
read database_name

# Verifica se o nome do banco de dados foi fornecido
if [ -z "$database_name" ]; then
    echo "O nome do banco de dados não pode estar vazio."
    exit 1
fi

# Cria o banco de dados com o nome fornecido pelo usuário
sudo mariadb <<MYSQL_SCRIPT
CREATE DATABASE $database_name;
MYSQL_SCRIPT

# Exibir mensagem de conclusão
echo -e "${GREEN}Banco de dados criado com sucesso!${NC}"

# Instala o Composer
echo -e "${YELLOW}Instalando o Composer...${NC}"
curl -sS https://getcomposer.org/installer -o composer-setup.php
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php

# Verifica se o Composer foi instalado com sucesso
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Composer instalado com sucesso.${NC}"
else
    echo "Ocorreu um erro ao instalar o Composer."
    exit 1
fi

