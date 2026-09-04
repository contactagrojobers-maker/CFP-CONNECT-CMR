# Déploiement GitHub, Vercel et Supabase

## 1. GitHub

1. Créer un dépôt nommé `cfp-connect-mvp`.
2. Ne pas ajouter de README ou de `.gitignore` depuis GitHub : ils existent déjà.
3. Depuis ce dossier, associer puis envoyer le dépôt :

```powershell
git remote add origin https://github.com/VOTRE_COMPTE/cfp-connect-mvp.git
git push -u origin main
```

Le dépôt ne contient aucun mot de passe ni aucune clé privée.

## 2. Supabase

1. Créer un nouveau projet Supabase.
2. Ouvrir **SQL Editor**.
3. Copier et exécuter `supabase/schema.sql`.
4. Dans **Storage**, vérifier que les buckets `center-photos` et `accreditations` ont été créés.
5. Copier l’URL du projet et la clé publique `anon` dans un fichier `.env.local`, en utilisant `.env.example` comme modèle.
6. Ne jamais placer la clé `service_role` dans GitHub ou dans le navigateur.

Le schéma prévoit trois rôles : `learner`, `center_manager` et `admin`. L’élévation au rôle administrateur doit être effectuée manuellement dans Supabase par une personne autorisée.

## 3. Vercel

1. Dans Vercel, choisir **Add New → Project**.
2. Importer le dépôt GitHub `cfp-connect-mvp`.
3. Framework : **Other**.
4. Build command : laisser vide.
5. Output directory : `.`.
6. Ajouter les variables `SUPABASE_URL` et `SUPABASE_ANON_KEY` lorsque l’intégration Supabase sera activée dans l’application.
7. Cliquer sur **Deploy**.

Le fichier `vercel.json` redirige les routes de l’application vers `index.html`.

## Important avant un lancement public

- Remplacer ou confirmer toutes les coordonnées de démonstration.
- Vérifier les agréments MINEFOP.
- Configurer le domaine officiel et les adresses de contact.
- Ajouter les mentions légales et la politique de confidentialité.
- Connecter l’interface actuelle à Supabase : le prototype utilise encore `data.js` et le stockage local du navigateur.
