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

echo -e "${INFO}Digite a versão do PHP:${NC}"
read PHP_VER

# Verifica se o parâmetro -nogit foi passado
while [[ "$1" != "" ]]; do
    case $1 in
        -nogit )
            echo "No git"
            no_git=true
            ;;
        * )
            echo "Parâmetro inválido: $1"
            exit 1
    esac
    shift
done

#PHP, Mysql e Extensões
echo -e "${INFO}Instalando PHP, MySQL e Extensões...${NC}"
sudo apt update && sudo apt install -y php php$PHP_VER-common php$PHP_VER-mysql php$PHP_VER-intl php$PHP_VER-fpm php$PHP_VER-xml php$PHP_VER-zip git nginx mariadb-server mariadb-client curl unzip

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

# Loop para solicitar o nome do novo usuário
while true; do
    # Solicita ao usuário o nome do novo usuário
    echo -e "${INFO}Informe o usuário do BD ('q' para sair):${NC}"
    read db_username

    # Verifica se o usuário digitou 'q' para sair
    if [ "$db_username" == "q" ]; then
        exit 0
    fi

    # Verifica se o nome do novo usuário está vazio
    if [ -z "$db_username" ]; then
        echo -e "${WARNING}Atenção, o nome do usuário não pode ser vazio!${NC}"
    else
        break
    fi
done

# Solicita ao usuário a senha para o novo usuário
echo -e "${INFO}Digite a senha para o novo usuário:${NC}"
stty -echo
read db_password
stty echo

# Cria o novo usuário com a senha fornecida
sudo mysql -e "CREATE USER '$db_username'@'localhost' IDENTIFIED BY '$db_password';"
echo -e "${SUCCESS}Usuário '$db_username' criado com sucesso.${NC}"

# Concede ao novo usuário privilégios para acessar e gerenciar o banco de dados
sudo mysql -e "GRANT ALL PRIVILEGES ON $database_name.* TO '$db_username'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
echo -e "${SUCCESS}Privilégios concedidos para o usuário '$db_username' no banco de dados '$database_name'.${NC}"

# Exibe informações sobre o novo banco de dados e usuário
echo -e "${INFO}Banco de dados: $database_name"
echo -e "Usuário: $db_username"
echo -e "Senha: ********${NC}"

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

# Solicita ao usuário o nome da pasta para o projeto
project_folder=""
while [ -z "$project_folder" ]; do
    echo -e "${INFO}Digite o nome da pasta do projeto ('q' para sair):${NC}"
    read project_folder

    if [ "$project_folder" = "q" ]; then
        echo -e "${ALERT}Encerrando o script.${NC}"
        exit 1
    elif [ -z "$project_folder" ]; then
        echo -e "${WARNING}Atenção, o nome da pasta do projeto não pode estar vazio.${NC}"
    fi
done

echo -e "${SUCCESS}Pasta do projeto definida como: $project_folder${NC}"

project_path="/var/www/$project_folder"

#Clone do repositório git
if ! [ "$no_git" = true ]; then
    # Altera permissões da pasta www
    sudo chmod o+w /var/www

    echo -e "${INFO}Digite o repositório no github (e.g. yosef/myproject.git):${NC}"
    read project_repository
    
    if [ -z "$project_repository" ]; then
        echo -e "${ALERT}Nenhum repositório informado.${NC}"
        exit 1
    else
        if [ -d "$project_path" ]; then
            echo -e "${ALERT}A pasta já está ocupada, para configurar rode o script com -nogit.${NC}"
            exit 1
        else
            git clone "$REP_URL$project_repository" "$project_path"
            clone_status=$?
            if [ $clone_status -ne 0 ]; then
                echo -e "${ALERT}Erro ao clonar repositório.${NC}"
                exit 1
            fi
        fi
    fi
else
    echo -e "${INFO}Pulando etapa de clone de repositório...${NC}"
    if [ -d "$project_path" ]; then
        echo -e "${INFO}Verificando a existência da pasta...${NC}"
    else
        echo -e "${WARNING}A pasta '$project_path' não existe.${NC}"
    fi
fi

echo -e "${INFO}Preparando variáveis de ambiente...${NC}"

cp "$project_path/.env.example" ".env"
if [ $? -ne 0 ]; then
    echo -e "${ALERT}Erro ao copiar o arquivo .env${NC}"
    exit 1
fi

env_file="$project_path/.env"

# Substitui os valores das variáveis no arquivo .env
sed -i "s/^APP_NAME=.*/APP_NAME=$project_folder/" "$env_file"
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=$database_name/" "$env_file"
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=$db_username/" "$env_file"
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$db_password/" "$env_file"

echo -e "${INFO}Variáveis alteradas com sucesso no arquivo $env_file.${NC}"

cd $project_path
composer install --optimize-autoloader --no-dev

echo -e "${INFO}Alterando permissões do Storage e Bootstrap...${NC}"
sudo chmod -R 777 storage
sudo chmod -R 777 bootstrap
echo -e "${SUCCESS}Permissões alteradas com sucesso!${NC}"

echo -e "${INFO}Ajustando o NGINX...${NC}"
sudo mv "/etc/nginx/sites-available/default" "/etc/nginx/sites-available/backup"

# Define o caminho para o arquivo de configuração do Nginx
nginx_config="/etc/nginx/sites-available/default"

# Conteúdo do arquivo de configuração
nginx_content="server {
    listen 80;
    listen [::]:80;
    server_name example.com;
    root $project_path/public;

    add_header X-Frame-Options 'SAMEORIGIN';
    add_header X-Content-Type-Options 'nosniff';

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php$PHP_VER-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}"

# Cria o arquivo de configuração
echo "$nginx_content" | sudo tee "$nginx_config" > /dev/null

# Verifica se o arquivo foi criado com sucesso
if [ -f "$nginx_config" ]; then
    echo -e "${SUCCESS}Arquivo de configuração do Nginx criado com sucesso em: $nginx_config ${NC}"
else
    echo -e "${ALERT}Erro ao criar o arquivo de configuração do Nginx. ${NC}"
    exit 1
fi

sudo systemctl restart nginx
echo -e "${SUCCESS}NGINX pronto!${NC}"

echo -e "${INFO}Gerando chave da aplicação...${NC}"
php artisan key:generate