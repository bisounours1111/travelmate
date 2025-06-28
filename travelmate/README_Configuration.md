# TravelMate - Configuration Complète

## 🚀 Configuration de l'Application

### 1. Configuration Stripe

L'application utilise Stripe pour les paiements. Voici les étapes de configuration :

#### 1.1 Clés Stripe

- **Clé publique** : Déjà configurée dans `AppDelegate.swift`
- **Clé secrète** : À configurer dans votre backend

#### 1.2 Backend Stripe

Vous devez créer un backend pour gérer les Payment Intents. Voici un exemple avec Node.js :

```javascript
// server.js
const express = require("express");
const stripe = require("stripe")("sk_test_votre_cle_secrete");

const app = express();
app.use(express.json());

app.post("/create-payment-intent", async (req, res) => {
  try {
    const { amount, currency = "eur" } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.json({
      client_secret: paymentIntent.client_secret,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => {
  console.log("Server running on port 3000");
});
```

#### 1.3 Configuration iOS

- Ajoutez `Stripe` à votre `Podfile` :

```ruby
pod 'Stripe'
```

- Exécutez `pod install`

### 2. Configuration Supabase

#### 2.1 Tables de Base de Données

Exécutez le script SQL dans `Config/SupabaseTables.sql` dans votre dashboard Supabase.

#### 2.2 Variables d'Environnement

Assurez-vous que vos variables Supabase sont configurées dans `SupabaseConfig.swift`.

### 3. Fonctionnalités Implémentées

#### 3.1 Système de Favoris

- ✅ Ajout/Suppression de favoris
- ✅ Vue des favoris dans le profil
- ✅ Boutons favoris sur toutes les destinations
- ✅ Synchronisation avec Supabase

#### 3.2 Système de Réservations

- ✅ Création de réservations
- ✅ Sélection de dates et nombre de personnes
- ✅ Calcul automatique des prix
- ✅ Intégration Stripe pour les paiements
- ✅ Gestion des statuts de réservation

#### 3.3 Interface de Paiement

- ✅ Formulaire de carte de crédit sécurisé
- ✅ Validation des données
- ✅ Intégration complète avec Stripe
- ✅ Gestion des erreurs de paiement

### 4. Structure des Données

#### 4.1 Table `favorites`

```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key -> auth.users)
- destination_id: UUID (Foreign Key -> destinations)
- created_at: TIMESTAMP
```

#### 4.2 Table `reservations`

```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key -> auth.users)
- destination_id: UUID (Foreign Key -> destinations)
- start_date: TIMESTAMP
- end_date: TIMESTAMP
- number_of_people: INTEGER
- total_price: DECIMAL(10,2)
- status: VARCHAR(20) ['pending', 'confirmed', 'cancelled', 'completed']
- stripe_payment_intent_id: VARCHAR(255)
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

### 5. Services Principaux

#### 5.1 `FavoriteService`

- `fetchFavorites(for userId: String)`
- `addToFavorites(userId: String, destinationId: String)`
- `removeFromFavorites(userId: String, destinationId: String)`
- `isFavorite(userId: String, destinationId: String)`

#### 5.2 `ReservationService`

- `fetchReservations(for userId: String)`
- `createReservation(...)`
- `confirmReservation(reservationId: String, paymentIntentId: String)`
- `cancelReservation(reservationId: String)`
- `getReservation(by id: String)`

#### 5.3 `StripePaymentService`

- `createPaymentIntent(amount: Int, currency: String)`
- `processPayment(clientSecret: String, paymentMethodId: String)`
- `resetPaymentStatus()`

### 6. Vues Principales

#### 6.1 `StripePaymentView`

- Interface de paiement complète
- Validation des cartes de crédit
- Intégration Stripe
- Gestion des erreurs

#### 6.2 `ProfileView`

- Onglets pour Réservations, Favoris, Paramètres
- Gestion des réservations
- Vue des favoris
- Paramètres utilisateur

#### 6.3 `DestinationDetailView`

- Bouton favori
- Bouton de réservation
- Intégration avec les services

### 7. Sécurité

#### 7.1 Row Level Security (RLS)

- Politiques de sécurité sur toutes les tables
- Utilisateurs ne peuvent voir que leurs propres données
- Protection contre les accès non autorisés

#### 7.2 Validation des Données

- Validation côté client et serveur
- Vérification des montants et dates
- Protection contre les injections SQL

### 8. Déploiement

#### 8.1 Prérequis

- Compte Stripe configuré
- Projet Supabase configuré
- Backend pour les Payment Intents

#### 8.2 Étapes

1. Exécuter le script SQL dans Supabase
2. Configurer les variables d'environnement
3. Déployer le backend Stripe
4. Tester les paiements en mode test
5. Passer en production

### 9. Tests

#### 9.1 Cartes de Test Stripe

- **Succès** : `4242 4242 4242 4242`
- **Échec** : `4000 0000 0000 0002`
- **3D Secure** : `4000 0025 0000 3155`

#### 9.2 Test des Fonctionnalités

- Création de favoris
- Création de réservations
- Processus de paiement
- Gestion des erreurs

### 10. Support

Pour toute question ou problème :

1. Vérifiez les logs de l'application
2. Consultez la documentation Stripe
3. Vérifiez la configuration Supabase
4. Testez avec les cartes de test

---

**Note** : Cette configuration permet une expérience utilisateur complète avec gestion des favoris, réservations et paiements sécurisés via Stripe.
