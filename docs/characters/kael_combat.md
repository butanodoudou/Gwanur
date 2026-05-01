# ⚔️ Kael — Lame de Sève

## Concept

Kael ne lance pas de sorts. Il **tisse la magie de la nature directement dans ses coups**.
Ses Brassards de Sève ne sont pas un outil — ils sont une extension de son corps.
Chaque frappe laisse un fil de sève vivant sur l'ennemi. Trois fils, et la nature répond.

> *"Ce n'est pas lui qui contrôle la magie. C'est la magie qui lui permet de continuer."*

---

## Identité

| | |
|---|---|
| **Race** | Demi-elfe (héritage elfique de sa mère Aelindra) |
| **Âge** | 16 ans — regard marqué, maturité précoce |
| **Rôle** | DPS technique / contrôle léger |
| **Style** | Élégant, rapide, précis — jamais brutal |
| **Arme principale** | Brassards de Sève (gauntlets gravés de runes végétales) |
| **Arme secondaire** | Lame courte elfique héritée d'Aldric |

---

## Boucle de Combat — Le Tissage de Sève

Inspiré de The Witcher 3 : timing + positionnement + gestion d'énergie.

```
Attaques rapides      → génèrent des Fils de Sève sur l'ennemi
Attaques chargées     → consomment l'énergie arcanisée pour des effets de nature
Esquives parfaites    → déclenchent des buffs momentanés (régén, vitesse)
```

**Le joueur doit enchaîner timing + positionnement + gestion des fils.**
Spammer sans timing punit — l'énergie se dissipe et Kael se retrouve vulnérable.

---

## Système : Fils de Sève

Chaque frappe de Kael applique un **Fil de Sève** sur la cible.  
À **3 fils accumulés**, un effet élémentaire se déclenche selon l'élément actif :

| Élément | Effet à 3 fils | Lore |
|---|---|---|
| 🌿 **Végétal** | Entrave — racines jaillissent, immobilise 2s | La sève répond à l'appel des Brassards |
| 💨 **Vent** | Repousse violent + stun 1s | L'air elfique est chargé de la mémoire des forêts |
| ✨ **Lumière** | Explosion lumineuse AoE (dégâts + aveuglement) | La magie sacrée de Vaelindra, instable en lui |

**Changer d'élément :** maintenir un bouton dédié + direction (comme les signes du Witcher).

> En coop : Mira peut déclencher les fils accumulés par Kael sur sa propre attaque → **Combo croisé**.

---

## Compétences

### Actives

| Compétence | Description | Coût |
|---|---|---|
| **Frappe de Sève** | Coup chargé qui libère tous les fils accumulés d'un coup | 40 énergie |
| **Pas des Feuilles** | Dash rapide + invulnérabilité courte (0.4s) | 25 stamina |
| **Lame de Racine** | Invoque une lame végétale temporaire — double frappe à distance | 50 énergie |
| **Éclat de Sève** | Explosion AoE autour de lui — purge tous ses fils sur tous les ennemis proches | 60 énergie |

### Passives

| Passive | Effet |
|---|---|
| **Esquive Arcanisée** | Esquive parfaite → +20 énergie instantané |
| **Marquage Profond** | Ennemis avec 2+ fils reçoivent +15% dégâts de toutes sources |
| **Sillage** | Kill → +20% vitesse de déplacement pendant 4s |
| **Résonance** *(débloqué narrativement — Zone 1)* | Les fils persistent 2s de plus sur les ennemis |

---

## Le Twist — La Sève le Consume

> **Sa magie n'est pas stable.**

Kael est demi-elfe. La magie elfique pure de Vaelindra n'était pas faite pour couler dans un corps humain à moitié. Chaque fois qu'il sur-utilise ses Brassards, la sève réagit trop fort.

**Mécaniquement :**

- Une jauge cachée **Surcharge de Sève** monte quand il enchaîne trop de compétences actives sans pause.
- À **50% de surcharge** : effets visuels (marques lumineuses qui pulsent sur les bras).
- À **100%** : les Brassards lâchent une décharge incontrôlée (gros dégâts AoE autour de lui — ennemis ET alliés) puis Kael est étourdi 2s.
- La surcharge redescend naturellement au repos ou via la compétence passive **Équilibre** *(débloquée Zone 3)*.

> *Connexion lore : la magie ancienne s'efface lentement dans Eldenmoor. En Kael, elle brûle au lieu de couler. Ce n't pas un pouvoir — c'est un héritage qui le dévore.*

---

## En Coop avec Mira

| Situation | Synergie |
|---|---|
| Kael applique 3 fils Végétal | Mira frappe → les racines explosent en zone |
| Mira immobilise un ennemi | Kael charge **Frappe de Sève** → dégâts critiques sur cible fixe |
| Mira utilise bombe alchimique | Kael enclenche Lumière → l'explosion est amplifiée par la lumière sacrée |
| Kael en Surcharge critique | Mira peut l'interrompre avec son grappin (tire Kael hors de la zone) |

---

## Personnalité en Combat

- Ne crie pas, ne s'emballe pas.
- Ses lignes de combat sont courtes, posées, parfois poétiques.
- Il observe les ennemis avant de frapper.
- Après un kill difficile : silence. Pas de célébration.

**Exemples de répliques :**
- *"La forêt se souvient."* — en activant Lame de Racine
- *"Trop."* — quand la Surcharge monte
- *"Mira — maintenant."* — en setup combo
- *"Ce n'était pas nécessaire."* — après un combat évitable

---

## Design Visuel

- Armure légère organique — cuir naturel, fibres végétales, pas de métal
- Marques lumineuses sur les avant-bras (les Brassards de Sève) — pulsent selon l'élément actif
- Couleur selon élément : vert sève / blanc vent / or lumière
- Effets de particules : subtils, pas flashy — quelques feuilles, des fils lumineux fins
- À pleine surcharge : les marques deviennent rouges orangées, craquèlent légèrement

---

## Ce qui reste à décider

- [ ] Valeurs exactes de HP / énergie / stamina
- [ ] Nombre de coups pour générer un Fil de Sève (1 ? 2 ?)
- [ ] Arbre de progression — quelles passives débloquées à quel moment narratif
- [ ] Les combos croisés avec Mira — liste complète
- [ ] Effets sonores — ambiance végétale / cristalline / lumineuse
