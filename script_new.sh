#!/bin/bash

# Charger les variables depuis le fichier .env
source .env

# Nombre d'ordinateurs défini dans le fichier .env
NUMBER_COMPUTER=${NUMBER_COMPUTER:-1}

# Fichier de sortie pour les informations de connexion DB
DB_CREDENTIALS_FILE="db_credentials.txt"
> "$DB_CREDENTIALS_FILE"  # Réinitialiser le fichier des credentials

# Commencer le contenu du fichier docker-compose
echo "version: '3.8'" > docker-compose.yml
echo "services:" >> docker-compose.yml

# Boucle pour chaque ordinateur
for ((i=1; i<=NUMBER_COMPUTER; i++)); do
  # Variables dynamiques pour chaque ordinateur
  COMPUTER_NAME_VAR="COMPUTER${i}_NAME"
  UBUNTU_NAME_VAR="COMPUTER${i}_UBUNTU_NAME"

  COMPUTER_NAME=${!COMPUTER_NAME_VAR}
  UBUNTU_NAME=${!UBUNTU_NAME_VAR}

  # Générer un nom d'utilisateur et un mot de passe aléatoires pour MySQL
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
  cat <<EOL >> docker-compose.yml
  apache_${COMPUTER_NAME}:
    build: .
    container_name: apache_${COMPUTER_NAME}
    ports:
      - "808${i}:80"
    volumes:
      - /home/${UBUNTU_NAME}/worldskills_app:/var/www/html
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
      - "808${i}2:80"
    networks:
      - ${COMPUTER_NAME}_network

EOL
done

# Ajouter la section des réseaux
echo "networks:" >> docker-compose.yml
for ((i=1; i<=NUMBER_COMPUTER; i++)); do
  COMPUTER_NAME_VAR="COMPUTER${i}_NAME"
  COMPUTER_NAME=${!COMPUTER_NAME_VAR}
  echo "  ${COMPUTER_NAME}_network:" >> docker-compose.yml
  echo "    driver: bridge" >> docker-compose.yml
done

echo "Fichier docker-compose.yml généré avec succès pour ${NUMBER_COMPUTER} ordinateurs."
echo "Les identifiants de connexion MySQL ont été sauvegardés dans ${DB_CREDENTIALS_FILE}."
