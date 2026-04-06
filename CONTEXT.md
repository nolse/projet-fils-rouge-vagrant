# Contexte Projet Fil Rouge - IC Group DevOps
# A coller en debut de session Claude pour reprendre sans perte de contexte

## Stack technique
- Terraform 1.14.5 | AWS us-east-1 | Backend S3 : terraform-backend-balde
- Ansible >= 2.12 | Collection community.docker
- Docker | Images : alphabalde/ic-webapp:1.0, jenkins/jenkins:lts, odoo:13.0, dpage/pgadmin4
- Minikube v1.35.0 | kubectl v1.32.13 | driver Docker sur VM Vagrant Ubuntu 22.04
- VM Vagrant : IP fixe 192.168.56.100 | interface enp0s8 | Minikube IP 192.168.49.2
- Repo infra  : https://github.com/nolse/projet_fil_rouge_infra
- Repo ansible: https://github.com/nolse/projet-fils-rouge

## Architecture serveurs AWS (Partie 2)
| Serveur | Type      | Ce qui tourne                 | Ports       |
|---------|-----------|-------------------------------|-------------|
| jenkins | t3.medium | jenkins/jenkins:lts           | 8080, 50000 |
| webapp  | t3.micro  | ic-webapp (port 80) + pgAdmin | 80, 5050    |
| odoo    | t3.medium | Odoo 13 + PostgreSQL          | 8069, 5432  |

## Architecture Kubernetes (Partie 3)
| Ressource         | Type       | Image                    | Port  |
|-------------------|------------|--------------------------|-------|
| postgres          | Deployment | postgres:13              | 5432  |
| postgres-service  | ClusterIP  | -                        | 5432  |
| postgres-pvc      | PVC        | -                        | 2Gi   |
| odoo              | Deployment | odoo:13.0                | 8069  |
| odoo-service      | NodePort   | -                        | 30069 |
| odoo-config       | ConfigMap  | odoo.conf                | -     |
| odoo-pvc          | PVC        | /var/lib/odoo            | 1Gi   |
| pgadmin           | Deployment | dpage/pgadmin4           | 80    |
| pgadmin-service   | NodePort   | -                        | 30050 |
| pgadmin-config    | ConfigMap  | servers.json             | -     |
| ic-webapp         | Deployment | alphabalde/ic-webapp:1.0 | 8080  |
| ic-webapp-service | NodePort   | -                        | 30080 |
| icgroup-secrets   | Secret     | 5 cles BDD + pgAdmin     | -     |

## Credentials
- Odoo login    : admin / admin
- pgAdmin login : admin@icgroup.fr / pgadmin_password
- PostgreSQL    : odoo / odoo_password

## Workflow Kubernetes (a suivre a chaque session)

### Demarrage
# 1. Depuis Git Bash Windows
cd /d/cursus_devops/vagrant/minikube/minikube_ubuntu22
vagrant up && vagrant ssh

# 2. Dans la VM
minikube start --driver=docker

# 3. Configurer le reseau (iptables DNAT vers Minikube)
bash setup-network.sh

# 4. Deployer toutes les ressources
bash kubernetes/commandes_utils.sh deploy

### Acces depuis Windows (ports fixes - pas de port-forward necessaire)
- ic-webapp -> http://192.168.56.100:30080
- Odoo      -> http://192.168.56.100:30069
- pgAdmin   -> http://192.168.56.100:30050

### Fin de session
minikube stop
exit
vagrant halt

## Points importants Kubernetes
- Sur Vagrant, l'IP Minikube (192.168.49.2) n'est pas directement accessible depuis Windows
  -> setup-network.sh configure des regles iptables DNAT sur l'interface enp0s8
  -> Les NodePorts sont accessibles via l'IP fixe de la VM 192.168.56.100
  -> Les ports sont fixes et ne changent pas entre les sessions
- Reseau VM : enp0s8 = 192.168.56.100 (host-only VirtualBox) | br-b5510e82bb93 = bridge Minikube
- --update=web dans les args Odoo : regenere les assets CSS/JS a chaque demarrage
- PVC necessaires : postgres-pvc (2Gi) ET odoo-pvc (1Gi /var/lib/odoo)
- La base odoo est creee automatiquement par Odoo au 1er demarrage via odoo.conf
  -> Ne pas utiliser le database manager pour recreer la base
  -> Se connecter directement sur http://192.168.56.100:30069 avec admin/admin

## Structure Kubernetes
kubernetes/
├── namespace.yml
├── secrets.yml
├── commandes_utils.sh
├── architecture.svg
├── README.md
├── postgres/
│   ├── deployment.yml
│   ├── service.yml
│   └── pvc.yml
├── odoo/
│   ├── deployment.yml     # args: --config + --update=web
│   ├── service.yml
│   ├── configmap.yml      # odoo.conf avec connexion TCP postgres-service
│   └── pvc.yml            # /var/lib/odoo 1Gi
├── pgadmin/
│   ├── deployment.yml
│   ├── service.yml
│   └── configmap.yml      # servers.json preconfiguree
└── webapp/
    ├── deployment.yml     # ODOO_URL et PGADMIN_URL fixes (NodePorts)
    └── service.yml

## Reste a faire
- HTTPS avec Ingress (bonus)
- Script reproduction Partie 2 avec sleeps (terraform + ansible)

## Workflow WSL Partie 2 (a suivre a chaque session)
# 1. Depuis Git Bash
cd ~/cursus-devops/projet_fil_rouge_infra/app && terraform apply
# 2. Depuis Git Bash
terraform output -json public_ips > ~/cursus-devops/projet-fils-rouge/inventaire/terraform_ips.json
# 3. Depuis WSL
wsl
rm -rf ~/projet-fils-rouge
cp -r /mnt/c/Users/balde/cursus-devops/projet-fils-rouge ~/projet-fils-rouge
cp /mnt/c/Users/balde/cursus-devops/projet_fil_rouge_infra/.secrets/projet-fil-rouge-key.pem ~/projet-fil-rouge-key.pem
chmod 600 ~/projet-fil-rouge-key.pem
cd ~/projet-fils-rouge
bash inventaire/generate_inventory.sh
ansible-playbook -i inventaire/hosts.yml playbook.yml -v
# 4. Depuis Git Bash - fin de session
cd ~/cursus-devops/projet_fil_rouge_infra/app && terraform destroy

