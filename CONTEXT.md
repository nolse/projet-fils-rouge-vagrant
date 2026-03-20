# Contexte Projet Fil Rouge — IC Group DevOps
# À coller en début de session Claude pour reprendre sans perte de contexte

## Stack technique
- Terraform 1.14.5 | AWS us-east-1 | Backend S3 : terraform-backend-balde
- Ansible >= 2.12 | Collection community.docker
- Docker | Images : alphabalde/ic-webapp:1.0, sadofrazer/jenkins, odoo:13.0, dpage/pgadmin4
- Repo infra  : https://github.com/nolse/projet_fil_rouge_infra
- Repo ansible: https://github.com/nolse/projet-fils-rouge

## Architecture serveurs AWS
| Serveur | Type      | Ce qui tourne              | Ports            |
|---------|-----------|----------------------------|------------------|
| jenkins | t3.medium | Jenkins (sadofrazer/jenkins)| 8080, 22000, 50000|
| webapp  | t3.micro  | ic-webapp + pgAdmin        | 80, 5050         |
| odoo    | t3.medium | Odoo 13 + PostgreSQL       | 8069, 5432       |

## Structure Terraform
```
projet_fil_rouge_infra/app/
├── main.tf          # Backend S3 + provider + modules sg/ec2/eip
├── outputs.tf       # output public_ips (map jenkins/webapp/odoo)
├── variables.tf     # region, key_name, environment
└── terraform.tfvars # region=us-east-1 | key=projet-fil-rouge-key | env=prod
modules/ : security_group | ec2 | eip
Ports SG : 22, 80, 8080, 8069, 5050
```

## Structure Ansible
```
projet-fils-rouge/
├── Dockerfile                         # python:3.6-alpine, lit releases.txt via awk
├── releases.txt                       # ODOO_URL, PGADMIN_URL, version (tag image)
├── Jenkinsfile                        # Pipeline CI/CD complet
├── ansible.cfg                        # Config globale Ansible
├── playbook.yml                       # Playbook principal (3 plays)
├── requirements.yml                   # community.docker
├── README.md                          # Guide de reproduction
├── .secrets/                          # Ignoré par git
│   └── projet-fil-rouge-key.pem       # Clé SSH AWS
├── inventaire/
│   ├── generate_inventory.sh          # Lit terraform output → génère hosts.yml
│   └── hosts.yml.example              # Modèle inventaire (hosts.yml ignoré par git)
├── jenkins-tools/
│   ├── Dockerfile                     # Image Jenkins custom (CentOS7)
│   ├── docker-compose.yml             # sadofrazer/jenkins
│   ├── jenkins.conf                   # Config Nginx reverse proxy
│   ├── jenkins-install.sh             # Script installation Jenkins
│   └── init/README-credentials.md    # Guide configuration credentials Jenkins
├── odoo/docker-compose.yml            # Odoo 13 + PostgreSQL
├── pgadmin/
│   ├── docker-compose.yml             # pgAdmin4
│   └── servers.json                   # Préconfiguration connexion BDD
├── templates/index.html               # Site vitrine IC Group
├── static/                            # CSS + images
└── roles/
    ├── odoo_role/                     # Odoo 13 + PostgreSQL via docker-compose
    ├── pgadmin_role/                  # pgAdmin4 + servers.json préconfiguré
    ├── webapp_role/                   # ic-webapp + ODOO_URL/PGADMIN_URL injectées
    └── jenkins_role/                  # Jenkins sadofrazer/jenkins
```

## Pipeline Jenkins — étapes
1. Checkout       — récupération du code
2. Read Version   — lecture version/URLs depuis releases.txt via awk
3. Build          — docker build, tag = version releases.txt
4. Test           — container test-ic-webapp, curl sur port 8085
5. Push           — docker push sur Docker Hub (tag version + latest)
6. Deploy         — ansible-playbook sur les 3 serveurs

## Credentials Jenkins à configurer (1 seule fois)
- docker-hub-credentials : Username/password Docker Hub (alphabalde)
- ansible-ssh-key        : Secret file → .secrets/projet-fil-rouge-key.pem

## Points importants
- IPs dynamiques → destroy/apply à chaque session → relancer generate_inventory.sh
- ic-webapp : ODOO_URL et PGADMIN_URL injectées depuis hostvars dans playbook.yml
- pgadmin_db_host = IP serveur odoo (injecté dynamiquement)
- Stratégie coûts : terraform destroy dès fin de session
- releases.txt : changer version → déclenche rebuild + redéploiement auto

## Commandes clés
```bash
# Déployer infra
cd ~/cursus-devops/projet_fil_rouge_infra/app && terraform apply

# Générer inventaire
cd ~/cursus-devops/projet-fils-rouge && bash inventaire/generate_inventory.sh

# Installer collections Ansible
ansible-galaxy collection install -r requirements.yml

# Déployer toutes les applications
ansible-playbook -i inventaire/hosts.yml playbook.yml

# Détruire infra (fin de session)
cd ~/cursus-devops/projet_fil_rouge_infra/app && terraform destroy
```

## Avancement
- [x] Partie 1 : Conteneurisation Docker — COMPLÈTE
- [x] Partie 2 : CI/CD Jenkins + Ansible — COMPLÈTE (reste : test end-to-end)
- [ ] Partie 3 : Kubernetes (Minikube) — À FAIRE
