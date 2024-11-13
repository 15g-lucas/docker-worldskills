#!/bin/bash

# Charger les variables depuis le fichier .env
source .env

# Nombre d'ordinateurs défini dans le fichier .env
NUMBER_COMPUTER=${NUMBER_COMPUTER:-1} # Default to 1 if not set

# Commencer le contenu du fichier docker-compose
echo "version: '3.8'" > docker-compose.yml
echo "services:" >> docker-compose.yml

# Boucle pour chaque ordinateur
for ((i=1; i<=NUMBER_COMPUTER; i++)); do
  # Utiliser des variables spécifiques pour chaque ordinateur
  COMPUTER_NAME_VAR="COMPUTER${i}_NAME"
  UBUNTU_NAME_VAR="COMPUTER${i}_UBUNTU_NAME"
  MYSQL_ROOT_PASSWORD_VAR="MYSQL_ROOT_PASSWORD${i}"
  MYSQL_DATABASE_VAR="MYSQL_DATABASE${i}"
  MYSQL_USER_VAR="MYSQL_USER${i}"
  MYSQL_PASSWORD_VAR="MYSQL_PASSWORD${i}"

  # Extraire les valeurs des variables dynamiques
  COMPUTER_NAME=${!COMPUTER_NAME_VAR}
  UBUNTU_NAME=${!UBUNTU_NAME_VAR}
  MYSQL_ROOT_PASSWORD=${!MYSQL_ROOT_PASSWORD_VAR}
  MYSQL_DATABASE=${!MYSQL_DATABASE_VAR}
  MYSQL_USER=${!MYSQL_USER_VAR}
  MYSQL_PASSWORD=${!MYSQL_PASSWORD_VAR}

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
