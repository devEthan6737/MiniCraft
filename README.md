# MiniCraft

**Developer:** ether
**Start Date:** January 21, 2026
**Technology:** Godot Engine & GDScript

---

## Overview

MiniCraft is a 2D survival sandbox game. It combines the creative freedom of Minecraft with an increasingly challenging survival experience. During the day, the player must gather and manage resources in order to survive enemy waves that appear at night.

---

## Game Mechanics

### Movement

* **A / D:** Move left and right
* **W or SPACE:** Jump
* **S:** Crouch

Gravity and collision detection are handled using `CharacterBody2D`.

---

### Building and Destruction System

#### Destruction

* Left-clicking on a tile detects the mouse position in world space using `get_global_mouse_position()`.
* This position is converted into map coordinates to remove the corresponding block from the `TileMap`.
* Different block types require different amounts of time to be destroyed.

#### Construction

* Right-clicking places a block on the selected `TileMap` cell, provided the player has blocks available in their inventory.

---

### Day / Night Cycle

* A 5-minute timer alternates between day and night phases.

#### Visual Effects

* `CanvasModulate` nodes are used to gradually modify the scene color from white (day) to dark blue (night).

---

### Difficulty System

* A counter tracks the current day and increments after each completed night.

* When night begins, enemies spawn according to the formula:

  **Enemies spawned = 3 × current day**

* Each night survived reduces the duration of the following day by **30 seconds**.

* After surviving **10 days**, the game is completed.

* Nights do not end until all enemies are defeated.

#### Difficulty Curve

* Each night increases the number of enemies.
* Some enemies may spawn with higher movement speed, while others deal more damage.

---

### Procedural Generation

* Terrain is generated using a simple algorithm:

  * 1 layer of grass
  * 3 layers of dirt
  * 26 or more layers of stone
  * A final layer of darker stone marks the depth limit and is indestructible

* Basic minerals are randomly generated within stone layers.

* The deeper the layer, the higher the probability and value of the minerals.

* On the surface layer, trees and bushes can spawn randomly.

---

### Crafting Table, Furnace, and Chests

* When approaching these blocks and pressing **E**, their respective interfaces open.

#### Crafting Table

* Pressing **E** while not near a furnace or chest opens the crafting table interface.
* Allows crafting of all available items in the game.

#### Furnace

* Press **E** near a furnace to open its interface.
* Allows smelting specific items.
* Each item has its own smelting duration.

#### Chests

* Press **E** near a chest to open its interface.
* Can store up to **4 different items**.

---

### Combat

#### Player Attacks

* Left-clicking in the direction of an enemy performs a basic attack with the currently held item.
* Swords deal increased damage.
* If the enemy is within attack range, it receives damage and a brief cooldown is applied to prevent immediate counter-attacks.

#### Enemies

* Enemies spawn only during the night.
* Their AI follows a simple chase behavior.
* On contact with the player, they reduce the player’s health.

---

### Inventory System

* **Structure:** Simple hotbar system with **5 slots** at the start.

* Can be upgraded up to **9 slots**.

* **Logic:**

  * An `Array` stores block/item IDs and collected quantities.
  * Inventory data communicates with the UI using signals.

---

## User Interface

### HUD

The HUD includes:

* Player health bar
* Active block selector (bottom hotbar)
* Timer showing remaining time until night and the current cycle number

### Menus

* **Main Menu:** Title, “Play” button, and “Exit” button
* **Game Over Screen:** Statistics and restart button
* **Victory Screen:** Statistics and restart button

---

## Technical Aspects

### Core Nodes

* `TileMap` used as the main system for rendering and collisions
* `CharacterBody2D` for both player and enemies
* `Timer` nodes for time cycles and spawn events
* `Camera2D` with smoothing enabled to follow the player

### Data Management

* Tiles use configured collision layers
* No data persistence is planned for this game

### Artificial Intelligence

* Enemy chase algorithm calculates a direction vector toward the player every frame
* After waiting three times longer than usual, enemies will be able to destroy player-built structures that block their path

---
https://etherener.itch.io/minicraft
https://deepwiki.com/devEthan6737/MiniCraft/1-minicraft-overview


