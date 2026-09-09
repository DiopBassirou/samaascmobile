# ðŸ“± SAMA ASC - Application Mobile (Flutter)

L'application mobile **SAMA ASC** permet aux PrÃ©sidents, TrÃ©soriers, Coachs, et Supporters de gÃ©rer et suivre leur Ã©quipe de football locale (NavÃ©tane).

Cette application a Ã©tÃ© dÃ©veloppÃ©e en **Flutter** avec un respect strict du **Clean Architecture**, en Ã©vitant toute valeur en dur et en favorisant un code modulaire, prÃªt Ã  Ã©voluer vers des plateformes Android, iOS, et Web.

## âœ¨ Design Premium
L'application met en avant une esthÃ©tique **Glassmorphism** moderne avec des arriÃ¨re-plans sombres, des dÃ©gradÃ©s Ã©lÃ©gants (Deep Blue/Teal), et des micro-animations pour maximiser l'engagement utilisateur.

## ðŸ—ï¸ Architecture du Code (MVVM)

Le code source est structurÃ© dans le dossier lib/ selon le modÃ¨le MVVM (Model-View-ViewModel via Provider) :

- core/constants/ : Aucune URL ou route n'est en dur dans l'UI. Elles sont gÃ©rÃ©es ici (pi_routes.dart, pp_routes.dart).
- models/ : ModÃ¨les de donnÃ©es typÃ©s.
- services/ : La couche d'accÃ¨s rÃ©seau (Appels HTTP vers Laravel, interception des erreurs).
- providers/ : Gestion d'Ã©tat locale avec Provider (ex: uth_provider.dart, inance_provider.dart).
- ui/screens/ : Interfaces graphiques dÃ©coupÃ©es par domaine mÃ©tier :
  - dmin/ : Panel de validation Super Admin.
  - uth/ : Splash et Login avec stockage hors ligne du Token via SharedPreferences.
  - coach/ : DÃ©finition du 11 partant de l'Ã©quipe.
  - competition/ : Tableau des classements de la poule.
  - inance/ : Bilan du trÃ©sorier et bouton pour **TÃ©lÃ©charger le PDF** gÃ©nÃ©rÃ© par l'API.
  - supporter/ : Listes de matchs et interface de notation via Sliders.

## ðŸš€ Installation & Lancement

### PrÃ©requis
- Flutter SDK (version >= 3.x)
- Android Studio (avec Ã©mulateur Android) ou Xcode (pour iOS)

### Configuration

1. **Cloner le projet** (ou ouvrir le dossier sama_asc_mobile).
2. **Installer les packages** :
   `ash
   flutter pub get
   `
3. **Variables d'environnement (.env)** :
   Le projet utilise lutter_dotenv pour cacher l'adresse de l'API. 
   Ã€ la racine de l'application, crÃ©ez (ou modifiez) le fichier .env :
   `env
   # Si vous utilisez l'Ã©mulateur Android vers un Laravel local :
   API_BASE_URL=http://10.0.2.2:8000/api
   
   # Si vous dÃ©ployez le backend en ligne :
   # API_BASE_URL=https://mon-domaine-sama-asc.com/api
   `

### Lancement

- Lancer sur l'Ã©mulateur ou le Web :
   `ash
   flutter run
   `

## ðŸ”” FonctionnalitÃ©s Futures
- ImplÃ©mentation officielle des **Notifications Push (Firebase Cloud Messaging)**. Les notifications sont pour le moment simulÃ©es dans l'application (Mock via UI) en attendant les accÃ¨s au projet Google Cloud / Firebase.
