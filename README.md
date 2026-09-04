# CFP Connect 🇨🇲 — MVP

Application web mobile-first pour trouver un métier ou un Centre de Formation Professionnelle au Cameroun. Bertoua constitue la ville pilote.

## Démonstration actuelle

- Recherche par formation et localisation
- 10 fiches CFP de démonstration à Bertoua
- Photos, localisation, agrément, formations et prochaines rentrées
- Contact WhatsApp et téléphone
- Avis et notation
- Revendication ou proposition d’un CFP
- Espaces CFP et administrateur
- Administration directe des centres de démonstration

Les informations des centres doivent être contrôlées avant une publication destinée au grand public.

## Lancer localement

```powershell
npm run preview
```

Puis ouvrir `http://localhost:4173`.

## Mise en ligne

Le dépôt est préparé pour :

- GitHub : hébergement du code source
- Vercel : hébergement du site
- Supabase : base de données, authentification, stockage des photos et sécurité

Consulter [DEPLOYMENT.md](DEPLOYMENT.md) pour la procédure complète. Le prototype utilise encore ses données locales afin de fonctionner immédiatement ; le schéma du futur backend se trouve dans `supabase/schema.sql`.
