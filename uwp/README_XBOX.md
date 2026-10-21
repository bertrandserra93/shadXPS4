# shadPS4 pour Xbox One X (Mode Développeur UWP)

Guide complet pour compiler, installer et exécuter shadPS4 sur Xbox One X en mode développeur.

---

## 1. Architecture du portage

* **Interface utilisateur (GUI) :** Mode *Big Picture* natif (ImGui + SDL3 Renderer), pilotable à la manette Xbox.
* **Packaging :** Paquet UWP MSIX x64 ciblant `Windows.Xbox` (build 17763+).
* **Permissions :** 
  * `codeGeneration` : pour l'allocation mémoire exécutable (`PAGE_EXECUTE_READWRITE`).
  * `removableStorage` : pour la détection et la lecture de jeux sur clé USB / disque externe.
* **Compilation :** Pipeline automatisé via GitHub Actions sur serveur Windows Server / MSVC.

---

## 2. Déclencher la compilation sur GitHub Actions

1. Poussez cette branche sur votre fork GitHub de shadPS4 :
   ```bash
   git add .
   git commit -m "feat(xbox): Add Xbox One X UWP packaging and CI workflow"
   git push origin main
   ```
2. Rendez-vous sur votre dépôt GitHub dans l'onglet **Actions**.
3. Sélectionnez le workflow **Xbox UWP Build** et cliquez sur **Run workflow** (ou attendez la fin du build déclenché par le push).
4. Une fois le workflow terminé avec succès, téléchargez l'archive d'artefacts **`shadps4-xbox-uwp-...`**.
5. Décompressez l'archive pour obtenir :
   * `shadps4-xbox-x64.msix` (le paquet de l'application)
   * `shadps4-dev.cer` (le certificat numérique auto-signé)

---

## 3. Configuration de la Xbox One X en Mode Dev

1. Démarrez votre Xbox One X en **Developer Mode** (via l'application *Xbox Dev Mode Activation*).
2. Sur l'écran d'accueil Dev Mode, repérez l'adresse IP et le port du **Device Portal** (ex : `https://192.168.1.50:11443`).
3. Activez l'option d'authentification ou notez vos identifiants si configurés.

---

## 4. Déploiement via le Xbox Device Portal

1. Depuis votre Mac (dans Safari, Chrome ou Firefox), accédez à l'URL :
   ```
   https://<IP_DE_VOTRE_XBOX>:11443
   ```
2. Acceptez l'avertissement de sécurité lié au certificat auto-signé de la console.
3. Dans le menu de gauche, allez dans **Apps**.
4. Sous **Install App** :
   * Cliquez sur **Choose File** et sélectionnez `shadps4-xbox-x64.msix`.
   * Cochez la case pour ajouter un certificat de dépendance, et sélectionnez `shadps4-dev.cer`.
   * Cliquez sur **Deploy**.
5. Une fois le déploiement terminé, l'application apparaît dans la liste des applications installées.

---

## 5. Configuration IMPORTANTE : Passer en mode "Game"

Par défaut, la Xbox alloue les ressources d'une simple application multimédia (~1 Go de RAM et CPU bridé).

1. Dans la liste des applications du Device Portal, localisez **shadPS4 Xbox**.
2. Cliquez dessus et changez le type d'application de **App** à **Game**.
3. Cela débloque les 6 cœurs Jaguar complets et environ 5 Go de mémoire vive GDDR5.

---

## 6. Chargement des jeux

* Formatez une clé USB ou un disque externe au format **NTFS**.
* Déposez vos packages/dossiers de jeux PS4 déchiffrés (format standard avec dossier `eboot.bin` ou `.zar`).
* Branchez le stockage sur l'un des ports USB de la Xbox One X.
* Lancez **shadPS4 Xbox** depuis le menu Dev Mode.
