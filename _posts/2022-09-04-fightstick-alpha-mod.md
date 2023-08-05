---
layout: post
title: Adding a Removable Cable to the FightStick Alpha
date: 2022-09-04 09:57 -0700
categories:
- Projects
- Mods
tags:
- hardware
- 3d-printing
image:
  path: /assets/img/fightstick-alpha-mod/fightstick-alpha-mod.jpg
  width: 1000
  height: 400
  alt: Removable cable
---

## Motivation

Back when *Street Fighter V* came out, I decided I wanted to learn how to play. I quickly learned that most players of Street Fighter, or fighting games in general, play on an arcade-style controller (colloquially referred to as fight sticks). I ended up purchasing a entry-level *FightStick Alpha* from MadCatz. After swapping out the stick and buttons, it was a pretty good stick. My only gripe with it was that the long USB cable was tethered to the stick, making it annoying to travel with or pack up. On a slow day at home, with the power of a 3D printer and a soldering iron, I decided to see if I could replace the cable with a port for a removable cable.

## Cable Holder Mechanism

The stock cable was soldered to the PCB in the case. The cable exits the case and is held in place by a plastic piece that's screwed into the case. The problem is, the connector for the removable cable would need to be on the outside of the case. So I needed a way to affix the connector on the outside of the case while having the connector wired to the PCB on the inside of the case. Wanting to avoid using glue, I decided to see if I could create a 3D model of the original plastic piece that held in the cable, and add a mounting point for a connector to it.

![3D model](/assets/img/fightstick-alpha-mod/3d_model.jpg)
_3D model of the cable holder_

![Printed piece vs stock piece](/assets/img/fightstick-alpha-mod/printed_vs_stock.jpg)
_3D printed cable holder with USB-C connector (left) vs. stock cable holder (right)_

## Assembly

After I measured everything out with a caliper and recreated the stock cable holder in Fusion 360, I added screwposts for a USB-C breakout board that I had laying around. I positioned the connector such that it would be exposed to the outside of the case without exposing too much of the PCB, to hide the wiring. After soldering some wires from the main PCB for D+, D-, 5V, and ground, the assembly was ready to go.

![Full assembly](/assets/img/fightstick-alpha-mod/assembly.jpg)
_Full assembly_

Everything screwed in and fit nicely when compared to the original cable holder. It's difficult to even tell that there's a 3D printed piece at all! The connector is relatively well hidden on the bottom of the stick. Now when I want to play, I just grab a USB-C to A cable and I'm good to go.

![Connector view from the outside](/assets/img/fightstick-alpha-mod/outside.png)
_Connector view from the outside_
