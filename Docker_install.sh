#!/bin/bash

#exit si une erreur apparait
set -e 

#Verification du root
if [ "$EUID" -ne 0 ]; then
  echo "Erreur : Ce script doit être lancé en tant que root (ou avec sudo)."
  exit 1
fi

#Fonction pour un affichage propre
log() {
  echo ""
  echo "=============================================================================="
  echo "=> $1"
  echo "=============================================================================="
  echo ""
}
 

#Desinstalation de potentiel docker
log "Nettoyage des anciennes versions de Docker..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do apt-get remove $pkg || true; done




#Install de docker
log "Installation des dépendances et du dépôt Docker..."
# Add Docker's official GPG key:
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc


# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
 apt-get update


#Ajout des packages
log "Installation de Docker Engine..."
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Verification de l'install
log "Vérification de l'installation :"
docker --version

#ajout de l'utilisateur dans le groupe docker
log "Configuration de l'utilisateur pour le groupe Docker..."
if [ -z "$SUDO_USER" ]; then
	read -p "Quel utilisateur faut-il ajouter au groupe docker ? " user_to_add
	usermod -aG docker "$user_to_add"
	log "Utilisateur $user_to_add ajouté au groupe docker.
else
	usermod -aG docker $SUDO_USER
	log "Utilisateur $SUDO_USER ajouté au groupe docker."
fi


#Ajout de condition pour installer portainer (demander a l'utilisateur si il le veut)
log "Installation de Portainer (Optionnel)"

read -p "Voulez vous installer Portainer ? y/n " install_portainer

if [ "$install_portainer" = "y" ]; then
	log "Installation de Portainer via Docker Compose..."
	mkdir /srv/docker
	mkdir /srv/docker/portainer
	cd /srv/docker/portainer
	
	log "Création du fichier docker-compose.yaml dans $PORTAINER_DIR..."
	cat <<-EOF > docker-compose.yaml
		version: '3.8'
		services:
		  portainer:
		    image: portainer/portainer-ce:latest
		    container_name: portainer
		    restart: always
		    ports:
		      - "9000:9000"
		      - "9443:9443"
		    volumes:
		      - /var/run/docker.sock:/var/run/docker.sock
		      - portainer_data:/data

		volumes:
		  portainer_data:
	EOF
	
	
    	log "Lancement de Portainer avec Docker Compose..."
	docker compose up -d
	
	log "Portainer est installé et accessible sur https://<ip_du_serveur>:9443"
else
    	log "Installation de Portainer ignorée."
fi


# --- Fin du script ---
log "Script terminé avec succès ! 🎉"
