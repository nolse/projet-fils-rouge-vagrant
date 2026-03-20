# Projet Fil Rouge — Avancement

## Stack
- Terraform 1.14.5
- AWS us-east-1
- Backend S3 : terraform-backend-balde
- Repo infra  : https://github.com/nolse/projet_fil_rouge_infra
- Repo ansible: https://github.com/nolse/projet-fils-rouge

## IPs (terraform output) — régénérer après chaque apply
- jenkins : dynamique → bash inventaire/generate_inventory.sh
- odoo    : dynamique
- webapp  : dynamique

## Étapes
- [x] Prérequis locaux
- [x] Bucket S3 + versioning
- [x] Git initialisé
- [x] Modules Terraform (security_group, ec2, ebs, eip)
- [x] terraform apply — 3 VMs opérationnelles
- [x] SSH OK sur les 3 serveurs
- [x] Partie 1 : Conteneurisation app vitrine (Docker)
      - [x] Dockerfile (python:3.6-alpine, awk releases.txt)
      - [x] releases.txt (ODOO_URL, PGADMIN_URL, version)
      - [x] ic-webapp:1.0 buildée et pushée → alphabalde/ic-webapp:1.0
      - [x] odoo/docker-compose.yml
      - [x] pgadmin/docker-compose.yml + servers.json
      - [x] jenkins-tools/ (Dockerfile + docker-compose + conf + scripts)
- [x] Partie 2 : Pipeline CI/CD Jenkins + Ansible
      - [x] roles/odoo_role    — Odoo 13 + PostgreSQL
      - [x] roles/pgadmin_role — pgAdmin4 + servers.json préconfiguré
      - [x] roles/webapp_role  — ic-webapp + ODOO_URL/PGADMIN_URL injectées
      - [x] roles/jenkins_role — Jenkins (sadofrazer/jenkins)
      - [x] inventaire/generate_inventory.sh — inventaire dynamique Terraform→Ansible
      - [x] inventaire/hosts.yml.example — modèle pour reproductibilité
      - [x] ansible.cfg
      - [x] playbook.yml — orchestration des 3 plays
      - [x] requirements.yml — community.docker
      - [x] README.md
      - [x] Jenkinsfile — pipeline CI/CD complet
      - [x] jenkins-tools/init/README-credentials.md — guide credentials Jenkins
      - [ ] Configurer credentials Jenkins (docker-hub-credentials + ansible-ssh-key)
      - [ ] Tester le pipeline end-to-end
- [ ] Partie 3 : Kubernetes (Minikube)
      - [ ] Namespace icgroup
      - [ ] Manifests ic-webapp (Deployment + Service)
      - [ ] Manifests Odoo + BDD_Odoo (Deployment + Service + PVC)
      - [ ] Manifests pgAdmin (Deployment + Service)
      - [ ] Secrets Kubernetes (données sensibles)
      - [ ] Labels env=prod sur toutes les ressources
