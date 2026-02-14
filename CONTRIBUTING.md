# Guide de contribution

Merci de votre intérêt pour NexusOS ! Ce document explique comment contribuer au projet.

## Code de conduite

- Soyez respectueux et professionnel
- Accueillez les nouveaux contributeurs
- Acceptez les critiques constructives
- Concentrez-vous sur ce qui est le mieux pour la communauté

## Comment contribuer

### Signaler des bugs

Avant de signaler un bug :
1. Vérifiez qu'il n'a pas déjà été signalé
2. Assurez-vous que vous utilisez la dernière version
3. Testez sur QEMU et/ou VirtualBox

Dans le rapport de bug, incluez :
- Version de NexusOS
- Plateforme de test (QEMU, VirtualBox, matériel)
- Étapes pour reproduire
- Comportement attendu vs réel
- Logs/captures d'écran si pertinent

### Proposer des fonctionnalités

1. Ouvrez une issue pour discuter de la fonctionnalité
2. Expliquez le cas d'usage
3. Proposez une implémentation si possible

### Soumettre des Pull Requests

#### Workflow

1. **Fork** le projet
2. **Clone** votre fork
   ```bash
   git clone https://github.com/votreusername/nexusos.git
   cd nexusos
   ```
3. **Créer une branche**
   ```bash
   git checkout -b feature/ma-fonctionnalite
   ```
4. **Faire les modifications**
   - Suivez le style de code
   - Ajoutez des tests si applicable
   - Mettez à jour la documentation
5. **Commit**
   ```bash
   git commit -m "feat: ajouter support USB"
   ```
6. **Push**
   ```bash
   git push origin feature/ma-fonctionnalite
   ```
7. **Ouvrir une Pull Request**

#### Guidelines de commit

Format des messages :
```
type(scope): description courte

Description détaillée optionnelle

Fixes #123
```

Types :
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `docs`: Documentation
- `style`: Formatage, pas de changement de code
- `refactor`: Refactoring
- `test`: Ajout/modification de tests
- `chore`: Maintenance

Exemples :
```
feat(keyboard): ajouter support pour layout français
fix(memory): corriger fuite mémoire dans kmalloc
docs(readme): mettre à jour les instructions d'installation
```

## Style de code

### C/C++

- **Indentation** : 4 espaces (pas de tabs)
- **Accolades** : K&R style
  ```c
  if (condition) {
      // code
  } else {
      // code
  }
  ```
- **Nommage** :
  - Fonctions : `snake_case`
  - Variables : `snake_case`
  - Constantes : `UPPER_CASE`
  - Types : `snake_case_t`
  - Structures : `struct snake_case`

- **Headers** :
  - Include guards : `#ifndef KERNEL_MODULE_H`
  - Ordre : system headers, puis headers locaux
  - `extern "C"` pour compatibilité C++

### Assembleur

- **Indentation** : 4 espaces
- **Labels** : snake_case
- **Commentaires** : expliquer le "pourquoi", pas le "quoi"

### Documentation

- Commenter les fonctions complexes
- Utiliser des commentaires clairs et concis
- Documenter les structures de données
- Expliquer les algorithmes non-évidents

Exemple :
```c
/**
 * Alloue une page physique de mémoire
 * 
 * @return Pointeur vers la page allouée, ou NULL si échec
 */
void* pmm_alloc_page(void);
```

## Structure d'une contribution typique

### Nouveau driver

1. Créer le dossier : `kernel/drivers/mondriver/`
2. Créer les fichiers :
   - `mondriver.c` (implémentation)
   - `kernel/include/mondriver.h` (interface)
3. Mettre à jour le Makefile
4. Ajouter l'initialisation dans `kernel_main()`
5. Documenter dans `README.md`
6. Tester

### Nouvelle fonctionnalité kernel

1. Identifier le module concerné
2. Créer une branche
3. Implémenter la fonctionnalité
4. Tester exhaustivement
5. Documenter
6. Soumettre la PR

## Tests

### Tests manuels

Testez au minimum sur :
- QEMU (BIOS et UEFI)
- Une machine virtuelle (VirtualBox ou VMware)

### Checklist avant PR

- [ ] Le code compile sans warnings
- [ ] Le kernel boot correctement
- [ ] Les fonctionnalités existantes fonctionnent
- [ ] La nouvelle fonctionnalité fonctionne comme prévu
- [ ] Le code est commenté
- [ ] La documentation est à jour
- [ ] Les commits suivent le format

## Architecture et design

### Principes

- **Modularité** : Code séparé en modules distincts
- **Simplicité** : Préférer les solutions simples
- **Performance** : Optimiser les chemins critiques
- **Sécurité** : Valider les entrées, gérer les erreurs
- **Documentation** : Code autodocumenté

### Patterns à suivre

- Utiliser l'allocateur kernel pour la mémoire dynamique
- Gérer proprement les erreurs (codes de retour)
- Libérer les ressources (pas de fuites)
- Éviter les dépendances circulaires

### À éviter

- Code spaghetti
- Macros complexes
- Optimisations prématurées
- Code dupliqué

## Ressources

### Documentation

- [OSDev Wiki](https://wiki.osdev.org/)
- [Intel SDM](https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html)
- [AMD64 Manual](https://www.amd.com/en/support/tech-docs)

### Communauté

- [OSDev Forum](https://forum.osdev.org/)
- [Reddit /r/osdev](https://www.reddit.com/r/osdev/)
- [Discord OSDev](https://discord.gg/RnCtsqD)

## Questions ?

- Ouvrez une issue sur GitHub
- Rejoignez notre Discord
- Consultez la FAQ

Merci de contribuer à NexusOS ! 🚀
