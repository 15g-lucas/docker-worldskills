#!/bin/bash

# Charger les variables depuis le fichier .env (ou autre par ex env.local...)
source .env

# Nombre d'ordinateurs défini dans le fichier .env (Defaut 1 pour pas que le script crash)
NUMBER_COMPUTER=${NUMBER_COMPUTER:-1}

# Fichier de sortie pour les informations de connexion DB (En txt)
DB_CREDENTIALS_FILE="db_credentials.txt"
> "$DB_CREDENTIALS_FILE"  # Réinitialiser le fichier des credentials

# Commencer le contenu du fichier docker-compose
echo "services:" >> docker-compose.yaml

# Boucle pour chaque ordinateur
for ((i=1; i<=NUMBER_COMPUTER; i++)); do
  # Variables dynamiques pour chaque ordinateur
  COMPUTER_NAME_VAR="COMPUTER${i}_NAME"
  UBUNTU_NAME_VAR="computer${i}"

  COMPUTER_NAME=${!COMPUTER_NAME_VAR}
  UBUNTU_NAME=${!UBUNTU_NAME_VAR}

  # Générer un nom d'utilisateur et un mot de passe aléatoires pour MySQL (via open SSL)
  MYSQL_USER="user_$RANDOM"
  MYSQL_PASSWORD=$(openssl rand -base64 12)
  MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
  MYSQL_DATABASE="db_$i"

  # Sauvegarder les credentials dans le fichier texte
  echo "Computer ${i}:" >> "$DB_CREDENTIALS_FILE"
  echo "  MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}" >> "$DB_CREDENTIALS_FILE"
  echo "  MYSQL_DATABASE: ${MYSQL_DATABASE}" >> "$DB_CREDENTIALS_FILE"
  echo "  MYSQL_USER: ${MYSQL_USER}" >> "$DB_CREDENTIALS_FILE"
  echo "  MYSQL_PASSWORD: ${MYSQL_PASSWORD}" >> "$DB_CREDENTIALS_FILE"
  echo "" >> "$DB_CREDENTIALS_FILE"

  # Ajouter les services Apache, MySQL, phpMyAdmin pour cet ordinateur
  cat <<EOL >> docker-compose.yaml
  apache_${COMPUTER_NAME}:
    build: .
    container_name: apache_${COMPUTER_NAME}
    ports:
      - "808${i}:80"
    volumes:
      - /home/${UBUNTU_NAME_VAR}/app:/var/www/html
      - ./apache/apache.conf:/etc/apache2/sites-available/000-default.conf
    networks:
      - ${COMPUTER_NAME}_network

  mysql_${COMPUTER_NAME}:
    image: mysql:5.7
    container_name: mysql_${COMPUTER_NAME}
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "330${i}:3306"
    volumes:
      - ./computer${i}_mysql_data:/var/lib/mysql
    networks:
      - ${COMPUTER_NAME}_network

  phpmyadmin_${COMPUTER_NAME}:
    image: phpmyadmin/phpmyadmin
    container_name: phpmyadmin_${COMPUTER_NAME}
    environment:
      PMA_HOST: mysql_${COMPUTER_NAME}
      PMA_USER: root
      PMA_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    ports:
      - "818${i}:80"
    networks:
      - ${COMPUTER_NAME}_network

EOL
done

# Ajouter la section des réseaux (Un réseau par ordinateur)
echo "networks:" >> docker-compose.yaml
for ((i=1; i<=NUMBER_COMPUTER; i++)); do
  COMPUTER_NAME_VAR="COMPUTER${i}_NAME"
  COMPUTER_NAME=${!COMPUTER_NAME_VAR}
  echo "  ${COMPUTER_NAME}_network:" >> docker-compose.yaml
  echo "    driver: bridge" >> docker-compose.yaml
done

echo "Fichier docker-compose.yaml généré avec succès pour ${NUMBER_COMPUTER} ordinateurs."
echo "Les identifiants de connexion MySQL ont été sauvegardés dans ${DB_CREDENTIALS_FILE}."
