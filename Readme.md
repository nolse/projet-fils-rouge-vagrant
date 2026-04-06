# Projet Fil Rouge — IC Group DevOps

Deploiement complet d'une infrastructure DevOps en 3 parties :
conteneurisation, CI/CD et orchestration Kubernetes.

## Stack technique

- **Docker** — conteneurisation des applications
- **Terraform** — provisioning infrastructure AWS
- **Ansible** — deploiement et configuration des serveurs
- **Jenkins** — pipeline CI/CD
- **Kubernetes (Minikube)** — orchestration locale sur VM Vagrant

## Applications deployees

| Application | Image | Description |
|---|---|---|
| ic-webapp | alphabalde/ic-webapp:1.0 | Site vitrine IC Group |
| Odoo | odoo:13.0 | ERP metier |
| PostgreSQL | postgres:13 | Base de donnees Odoo |
| pgAdmin | dpage/pgadmin4 | Interface admin BDD |
| Jenkins | jenkins/jenkins:lts | Pipeline CI/CD |

---

## Partie 1 — Conteneurisation Docker

Construction et publication de l'image ic-webapp.

```bash
docker build -t alphabalde/ic-webapp:1.0 .
docker push alphabalde/ic-webapp:1.0
```

---

## Partie 2 — CI/CD Jenkins + Ansible

Provisioning AWS via Terraform, deploiement via Ansible.

```bash
# 1. Provisioning infrastructure (depuis Git Bash)
cd ~/cursus-devops/projet_fil_rouge_infra/app && terraform apply

# 2. Export des IPs
terraform output -json public_ips > ~/cursus-devops/projet-fils-rouge/inventaire/terraform_ips.json

# 3. Deploiement Ansible (depuis WSL)
wsl
rm -rf ~/projet-fils-rouge
cp -r /mnt/c/Users/balde/cursus-devops/projet-fils-rouge ~/projet-fils-rouge
cp /mnt/c/Users/balde/cursus-devops/projet_fil_rouge_infra/.secrets/projet-fil-rouge-key.pem ~/projet-fil-rouge-key.pem
chmod 600 ~/projet-fil-rouge-key.pem
cd ~/projet-fils-rouge
bash inventaire/generate_inventory.sh
ansible-playbook -i inventaire/hosts.yml playbook.yml -v

# 4. Fin de session (depuis Git Bash)
cd ~/cursus-devops/projet_fil_rouge_infra/app && terraform destroy
```

**Acces :**
- Jenkins  : `http://<jenkins_ip>:8080`
- ic-webapp : `http://<webapp_ip>`
- pgAdmin  : `http://<webapp_ip>:5050`
- Odoo     : `http://<odoo_ip>:8069`

---

## Partie 3 — Kubernetes (Minikube)

Deploiement de toutes les applications dans un cluster Kubernetes local
sur une VM Vagrant Ubuntu 22.04 (IP fixe : 192.168.56.100).

Les NodePorts sont accessibles directement depuis Windows via des regles
iptables configurees par `setup-network.sh`. Aucun port-forward necessaire.

### Workflow par session

```bash
# 1. Demarrer la VM (depuis Git Bash Windows)
cd /d/cursus_devops/vagrant/minikube/minikube_ubuntu22
vagrant up
vagrant ssh

# 2. Demarrer Minikube (dans la VM)
minikube start --driver=docker

# 3. Configurer le reseau iptables
bash setup-network.sh

# 4. Deployer toutes les ressources
bash kubernetes/commandes_utils.sh deploy

# 5. Fin de session
minikube stop
exit
vagrant halt
```

### Acces depuis Windows (ports fixes)

| Application | URL |
|---|---|
| ic-webapp | http://192.168.56.100:30080 |
| Odoo | http://192.168.56.100:30069 |
| pgAdmin | http://192.168.56.100:30050 |

### Credentials

| Application | Login | Password |
|---|---|---|
| Odoo | admin | admin |
| pgAdmin | admin@icgroup.fr | pgadmin_password |
| PostgreSQL | odoo | odoo_password |

---

## Structure du projet

```
projet-fils-rouge/
├── Dockerfile                  # Image ic-webapp
├── releases.txt                # Version + URLs Odoo/pgAdmin
├── Jenkinsfile                 # Pipeline CI/CD
├── setup-network.sh            # Regles iptables pour acces Windows
├── playbook.yml                # Playbook Ansible principal
├── ansible.cfg
├── requirements.yml
├── roles/
│   ├── odoo_role/
│   ├── pgadmin_role/
│   ├── webapp_role/
│   └── jenkins_role/
├── inventaire/
│   ├── generate_inventory.sh
│   └── hosts.yml.example
└── kubernetes/
    ├── namespace.yml
    ├── secrets.yml
    ├── commandes_utils.sh
    ├── architecture.svg
    ├── README.md
    ├── postgres/
    ├── odoo/
    ├── pgadmin/
    └── webapp/
```

## Auteur

Balde — Formation DevOps EazyTraining
