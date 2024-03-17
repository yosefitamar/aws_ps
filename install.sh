#############
# Variáveis #
#############
INFO='\033[1;33m'
SUCCESS='\033[0;32m'
ALERT='\033[41m'
WARNING='\033[45m'
NC='\033[0m'
#DEFAULT_REP=
REP_URL='https://github.com/'

#PHP, Mysql e Extensões
echo -e "${INFO}Instalando PHP, MySQL e Extensões...${NC}"
sudo apt update && sudo apt install -y php php8.3-common git nginx mariadb-server mariadb-client curl

echo -e "${INFO}A instalação está em andamento. Isso pode levar algum tempo...${NC}"

# Solicitar a senha root do MariaDB
echo -e "${INFO}Digite a senha root para o MariaDB (deixe em branco para senha vazia):${NC} " 
stty -echo
read db_root_password
stty echo

# Exibir mensagem de configuração segura do MariaDB
echo -e "${INFO}Configurando o MariaDB de forma segura...${NC}"

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
echo -e "${SUCCESS}Configuração do MariaDB concluída com sucesso!${NC}"

# Solicita ao usuário o nome do banco de dados
echo -e "${INFO}Digite o nome do banco de dados:${NC}"
read database_name

# Verifica se o nome do banco de dados foi fornecido
if [ -z "$database_name" ]; then
    echo "${WARNING}Atenção, banco de dados não foi informado! Nenhum banco será criado.{$NC}"
else
    if sudo mysql -e "SHOW DATABASES LIKE '$database_name'" | grep -q "$database_name"; then
        echo -e "${WARNING}Já existe um banco de dados com o nome '$database_name'.${NC}"
    else
        # Cria o banco de dados com o nome fornecido pelo usuário
        sudo mysql -e "CREATE DATABASE $database_name"
        echo -e "${SUCCESS}Banco de dados '$database_name' criado com sucesso.${NC}"
    fi
fi

# Instalação do Composer
if [ -x "$(command -v composer)" ]; then
    echo -e "${INFO}Composer já instalado. Pulando etapa.${NC}"
else
    echo -e "${INFO}Instalando o Composer...${NC}"
    curl -sS https://getcomposer.org/installer -o composer-setup.php
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
fi

# Verifica se o Composer foi instalado com sucesso
if [ $? -eq 0 ]; then
    echo -e "${SUCCESS}Composer instalado com sucesso.${NC}"
else
    echo -e "${ALERT}Ocorreu um erro ao instalar o Composer.${NC}"
    exit 1
fi

# Altera permissões da pasta www
sudo chmod o+w /var/www

echo -e "${INFO}Digite o repositório no github (e.g. yosef/myproject.git):${NC}"
read project_repository

# Solicita ao usuário o nome da pasta para o projeto
echo -e "${INFO}Digite o nome da pasta do projeto:${NC}"
read project_folder

if [ -z "$project_folder" ]; then
    echo -e "${ALERT}Não houve repositório. Fim do script.${NC}"
else
    git clone "$REP_URL$project_repository" "/var/www/$project_folder"
fi