# Audit de securite - 2026-05-19

## Methodologie

Audit effectue avec 4 commandes Git scannant l'historique complet du repo :

1. Recherche d'Access Keys AWS (pattern AKIA[0-9A-Z]{16})
2. Recherche de mots-cles sensibles (password, secret, api_key, token, private_key)
3. Verification des fichiers sensibles commites (.env, .pem, .key, .crt)
4. Inventaire complet des fichiers presents

## Resultats

- OK Aucune Access Key AWS detectee
- ATTENTION Mots-cles password presents uniquement dans docker-compose.yml (valeur de demo webmon_pwd, GF_SECURITY_ADMIN_PASSWORD admin)
- OK Aucun fichier .env, .pem, .key, .crt dans l'historique
- OK .gitignore couvre les patterns sensibles (.env, .pem, .key, secrets/)

## Justification des valeurs sensibles

Les credentials PostgreSQL (webmon_pwd) et Grafana (admin/admin) sont volontairement hardcodes dans docker-compose.yml.

Justification :
- Perimetre local (machine de developpement), pas de production
- Valeurs de demo connues de toute l'equipe, sans risque reel
- En production, les credentials seraient injectes via :
  - Variables d'environnement provenant d'un fichier .env non commite
  - OU un secret manager (HashiCorp Vault, AWS Secrets Manager, Docker Secrets)
  - Le code applicatif les recupererait au runtime via les env vars

## Mesures de protection

- .gitignore exclut : .env, *.pem, *.key, *.crt, secrets/
- .gitattributes force LF sur scripts bash (evite les casses Windows/Linux)
- Branch protection sur main : aucun push direct, PR obligatoires avec 1 reviewer

## Conclusion

Le repo est propre. Les seules valeurs "sensibles" sont des credentials de demo locale documentes comme tels.