# Directives de documentation HomeLab

Wiki dédié aux procédures manuelles d'installation et de reprise après sinistre du HomeLab.

## ⚠️ Locale obligatoire

**TOUJOURS TRAVAILLER EN FRANÇAIS (`locale: "fr"`)**

- Toutes les pages et recherches Wiki.js utilisent `locale: "fr"` (sauf demande explicite inverse).
- Règle appliquée à tous les outils : `wikijs_create_page`, `wikijs_create_nested_page`, `wikijs_search_pages`, `wikijs_update_page`.

## Principes généraux

1. **Reprise après sinistre d'abord** : documenter chaque étape pour reconstruire from scratch.
2. **Procédures manuelles** : consigner les gestes et commandes, pas uniquement l'automatisation.
3. **Dépendances** : versions, ports, services requis, données critiques à sauvegarder.
4. **Rationnel** : expliquer les choix, pas seulement le résultat.
5. **Runbooks** : démarrage, sauvegarde, restauration, dépannage récurrents.
6. **Diagrammes** : maintenir les vues d'architecture à jour.
7. **DRY** : éviter les doublons ; référencer les pages détaillées existantes (ex. la fiche `quick-reference-proxmox` doit pointer vers `disaster-recovery/proxmox-installation` pour le détail des sauvegardes/maintenance).

## Structure documentaire

- Slugs en kebab-case : `quick-reference-<service>`, `<service>-troubleshooting`, `<service>-setup-homelab`, index en `-index`, pages critiques en `-homelab`.
- Pages racine/index : `homelab-home`, `quick-references-index`, `disaster-recovery-index`, `troubleshooting-index`, `health-checks-monitoring-index`.
- Organisation logique (plat) construite par les liens internes, pas par arborescence.

## Standards par type de page

### Fiches service
```
# Nom du service

## Quick Reference
- Version, ports, dépendances
- Données critiques à sauvegarder
- RTO/RPO cible

## Installation
Étapes manuelles détaillées

## Configuration
Paramétrage manuel + fichiers clés

## Démarrage/Arrêt
Procédures opérationnelles

## Stratégie de sauvegarde
Quoi / où / fréquence / rétention

## Procédure de reprise
Étapes de restauration depuis sauvegarde

## Problèmes courants
Diagnostic et correctifs
```

### Runbooks DR
```
# [Service] Recovery Runbook

## Prérequis
Matériel, réseau, accès, secrets

## Étapes de reprise
1. ...
2. ...

## Validation
Tests de santé et baselines

## Rollback
Que faire si l'étape échoue
```

## Bonnes pratiques d'édition

1. **Rechercher avant de créer** (`wikijs_search_pages`).
2. **Respecter la structure** (`wikijs_create_nested_page` si besoin d'arbo logique).
3. **Toujours `locale: "fr"`** lors des créations/updates.
4. **Lier plutôt que dupliquer** : pointer vers les pages détaillées existantes (ex. installation, sauvegarde, maintenance).
5. **Mises à jour en masse** : `wikijs_bulk_update_project_docs` si impact multi-services.
6. **Synchroniser après changement infra** : `wikijs_sync_file_docs`.

## Priorités de contenu

- Chemins critiques de reprise (ordre de restauration).
- Points uniques de défaillance et dépendances croisées.
- Données et sauvegardes critiques (quoi/où/comment tester).
- Accès et identifiants (emplacement sécurisé).
- Supervision et alertes (comment détecter/valider).
- Tests de reprise périodiques (preuves et résultats).

## Sauvegarde de la documentation

- Documenter l'installation Wiki.js.
- Exporter régulièrement le contenu.
- Conserver une copie locale des runbooks critiques.
