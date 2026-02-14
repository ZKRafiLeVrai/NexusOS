# NexusOS - Questions Fréquentes (FAQ)

## Général

### Qu'est-ce que NexusOS ?
NexusOS est un système d'exploitation 64 bits complet et fonctionnel pour l'architecture x86_64, écrit à des fins éducatives. Il démontre les concepts fondamentaux d'un OS moderne.

### NexusOS est-il prêt pour la production ?
Non. NexusOS est un projet éducatif destiné à l'apprentissage et à l'expérimentation. Il ne doit pas être utilisé dans un environnement de production.

### Quelle est la licence ?
NexusOS est sous licence MIT, ce qui signifie que vous pouvez l'utiliser, le modifier et le distribuer librement.

### Puis-je contribuer ?
Absolument ! Les contributions sont les bienvenues. Consultez [CONTRIBUTING.md](CONTRIBUTING.md) pour plus de détails.

## Installation et compilation

### Quels sont les prérequis pour compiler NexusOS ?
- GCC ou Clang (compilateur C/C++)
- NASM (assembleur)
- GRUB tools (grub-mkrescue)
- Xorriso (pour créer l'ISO)
- Make

Voir [docs/COMPILATION.md](docs/COMPILATION.md) pour plus de détails.

### La compilation échoue avec "command not found"
Assurez-vous que tous les outils requis sont installés :
```bash
sudo apt-get install build-essential nasm grub-pc-bin xorriso
```

### Comment compiler sur macOS ?
Vous devez installer un cross-compiler x86_64-elf-gcc :
```bash
brew install nasm x86_64-elf-gcc xorriso qemu
```
Voir https://wiki.osdev.org/GCC_Cross-Compiler pour plus de détails.

### Puis-je compiler sous Windows ?
Oui, via WSL (Windows Subsystem for Linux). Installez Ubuntu dans WSL et suivez les instructions Linux.

## Exécution

### Comment tester NexusOS ?
Le moyen le plus simple est d'utiliser QEMU :
```bash
make run
```

### QEMU ne démarre pas
Vérifiez que QEMU est installé :
```bash
sudo apt-get install qemu-system-x86
```

### Puis-je tester sur VirtualBox ?
Oui ! Créez une nouvelle VM 64-bit et bootez depuis nexus.iso.

### Puis-je tester sur du matériel réel ?
Techniquement oui, mais ce n'est pas recommandé. NexusOS est expérimental et pourrait ne pas fonctionner sur tout le matériel. Si vous le faites, utilisez du matériel de test.

### L'OS ne boot pas
- Vérifiez que vous bootez en mode BIOS (pas UEFI pour l'instant)
- Assurez-vous que l'ISO est correctement créée
- Consultez les logs QEMU avec `-serial stdio`

## Fonctionnalités

### Quelles fonctionnalités sont implémentées ?
- Boot 64-bit via GRUB
- Gestion mémoire (pagination, allocateur)
- Gestion des interruptions (IDT)
- Drivers : clavier, vidéo VGA, timer, PCI
- Système de fichiers basique (RAM disk)
- Shell interactif
- Planificateur de tâches simple

### Est-ce que NexusOS supporte le réseau ?
Pas encore. C'est dans la roadmap pour les versions futures.

### Y a-t-il une interface graphique ?
Non, actuellement seulement un shell en mode texte. Une GUI est prévue pour les versions futures.

### Puis-je exécuter des programmes Linux ?
Non. NexusOS ne supporte pas encore les binaires ELF standard ni les syscalls Linux.

### Le multitâche fonctionne-t-il ?
Il y a un planificateur de tâches basique, mais le multitâche préemptif n'est pas encore implémenté.

## Développement

### Comment ajouter un nouveau driver ?
1. Créez un dossier dans `kernel/drivers/`
2. Implémentez le driver en C
3. Ajoutez le header dans `kernel/include/`
4. Appelez l'initialisation dans `kernel_main()`
5. Mettez à jour le Makefile

Voir [CONTRIBUTING.md](CONTRIBUTING.md) pour un guide détaillé.

### Comment déboguer le kernel ?
Utilisez QEMU avec GDB :
```bash
# Terminal 1
qemu-system-x86_64 -cdrom nexus.iso -s -S

# Terminal 2
gdb build/nexus.bin
(gdb) target remote localhost:1234
```

### Où puis-je trouver la documentation ?
- [README.md](README.md) : Vue d'ensemble
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) : Architecture technique
- [docs/COMPILATION.md](docs/COMPILATION.md) : Guide de compilation
- [CONTRIBUTING.md](CONTRIBUTING.md) : Guide de contribution

### Comment ajouter une nouvelle commande shell ?
Éditez `userland/shell/shell.c` et ajoutez votre fonction de commande dans `process_command()`.

## Problèmes courants

### "Page fault" au démarrage
- Vérifiez la configuration de pagination dans boot.asm
- Assurez-vous que les tables de pages sont correctement initialisées
- Vérifiez que vous n'accédez pas à de la mémoire non mappée

### "Triple fault" et redémarrage
- Généralement dû à une exception non gérée
- Activez les logs détaillés dans QEMU : `-d int,cpu_reset`
- Vérifiez l'IDT et les handlers d'interruption

### Le clavier ne fonctionne pas
- Vérifiez que les interruptions sont activées (`sti`)
- Assurez-vous que le PIC est correctement configuré
- Vérifiez le handler IRQ1 (interruption 33)

### Fuite mémoire
L'allocateur actuel est un bump allocator qui ne libère pas vraiment la mémoire. Pour un système réel, implémentez un allocateur slab ou buddy.

### Les scancodes du clavier sont incorrects
Le driver utilise le scancode set 1 avec layout US. Pour d'autres layouts, modifiez les tables dans `keyboard.c`.

## Performance

### Pourquoi est-ce lent ?
NexusOS est optimisé pour la simplicité et la clarté du code, pas pour la performance. Des optimisations sont possibles :
- Remplacer le bump allocator
- Optimiser la recherche de pages libres
- Ajouter du cache

### Comment optimiser l'allocation mémoire ?
Implémentez un allocateur slab ou buddy à la place du bump allocator actuel.

## Sécurité

### NexusOS est-il sécurisé ?
Non. Il n'y a actuellement aucune isolation entre utilisateur et kernel, aucune vérification des permissions, etc.

### Comment implémenter la sécurité ?
Pour un OS sécurisé, vous devriez implémenter :
- Ring 3 (mode utilisateur)
- System calls
- Memory protection
- Permissions fichiers
- Sandboxing

## Ressources

### Où puis-je apprendre le développement OS ?
- [OSDev Wiki](https://wiki.osdev.org/) : LA ressource
- [Intel SDM](https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html)
- [OSDev Forum](https://forum.osdev.org/)
- [/r/osdev](https://www.reddit.com/r/osdev/)

### Quels livres recommandez-vous ?
- "Operating Systems: Three Easy Pieces" (OSTEP)
- "Modern Operating Systems" by Andrew Tanenbaum
- "Operating System Concepts" by Silberschatz

### Y a-t-il une communauté ?
Oui ! Rejoignez :
- [OSDev Discord](https://discord.gg/RnCtsqD)
- [OSDev Forum](https://forum.osdev.org/)
- [Reddit /r/osdev](https://www.reddit.com/r/osdev/)

## Roadmap

### Quelles sont les prochaines fonctionnalités ?
Voir la roadmap dans [README.md](README.md#roadmap).

Priorités :
1. Support ACPI
2. Vrai multitâche préemptif
3. Drivers réseau
4. Système de fichiers ext2/FAT32
5. Interface graphique

### Puis-je suggérer des fonctionnalités ?
Oui ! Ouvrez une issue sur GitHub avec le tag "feature request".

## Contact

### Comment obtenir de l'aide ?
- Ouvrez une issue sur GitHub
- Consultez la documentation
- Demandez sur le forum OSDev

### J'ai trouvé un bug, que faire ?
Ouvrez une issue sur GitHub avec :
- Description du bug
- Étapes pour reproduire
- Logs/captures d'écran
- Votre environnement (OS, version QEMU, etc.)

---

**Cette FAQ sera mise à jour régulièrement. Si votre question n'est pas listée, n'hésitez pas à ouvrir une issue !**
