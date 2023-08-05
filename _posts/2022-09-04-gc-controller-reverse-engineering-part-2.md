---
title: GameCube Controller Reverse Engineering (Part 2)
date: 2022-09-04 00:11 -0700
categories: [Projects, GameCube Controller]
tags: [wii, gamecube]
image:
  path: /assets/img/gc_controller_reverse_engineering/gc_controller_reverse_engineering.png
  width: 1000
  height: 400
  alt: GameCube controller protocol
---
This is a continuation to [GameCube Controller Reverse Engineering (Part 1)]({% link _posts/2022-09-04-gc-controller-reverse-engineering-part-1.md %}). Be sure to check that out if you haven't already.

## Decoding the Commands

To validate all of the previous protocol research, I created a protocol decoder for the Saleae Logic 2 software. Feel free to download it and try it [here](https://github.com/jefflongo/GameCubeControllerAnalyzer). Not only did this allow me to annotate commands so I could identify commands at a high level, but the recent addition of [FrameV2](https://support.saleae.com/saleae-api-and-sdk/protocol-analyzer-sdk/framev2-hla-support-analyzer-sdk) support allows me to generate a table of command outputs to easily see the different fields of a command-response frame. The software also allows you to jump to a particular frame by selecting it from the table. The frame table can also be easily searched or exported for further analysis. 

![Annotated commands](/assets/img/gc_controller_reverse_engineering/annotated_commands.png)
_Annotated commands_

![Frame table](/assets/img/gc_controller_reverse_engineering/data_table.png)
_Frame table_

Here are some captures if you want to take a look at them in the Logic 2 software.

- [Console Boot Capture](/assets/files/gc_controller_reverse_engineering/sysmenu_boot.sal)
- [Super Smash Bros. Melee Boot Capture](/assets/files/gc_controller_reverse_engineering/ssbm_boot.sal)

## Designing a Replacement Chip

After I had a solid grasp on the protocol, I wanted to see if I could replace the ASIC on an OEM GameCube controller with a very small carrier PCB containing a microcontroller - the idea being that the carrier PCB would have castellated edges that could solder down directly to the footprint of the ASIC. Before I could do that, I had to figure out the pinout of the existing ASIC. To do that, I found some scans of the OEM PCB on [Acid Mods](https://www.acidmods.com/forum/index.php?topic=42579.0) forum. Unfortunately, the scans weren't very high quality, due to the compression of the forum. I contacted the original poster, RDC, and he was generous enough to send me the original high quality scans. I was able to map out the pinout of all the analog and digital inputs, and also discovered that original ASIC is clocked from a 4MHz oscillator. I added an option to use it on my custom PCB.

| :---------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------: |
| ![OEM PCB top](/assets/img/gc_controller_reverse_engineering/oem_top.jpg) | ![OEM PCB bottom](/assets/img/gc_controller_reverse_engineering/oem_bottom.jpg)) |

Now that I had a pinout, I was able to take a crack at making my own board. My first attempt used [OSHPark](https://oshpark.com/)'s 0.8mm service to make the board as thin as possible. Unfortunately, it was still pretty difficult to solder down, and I didn't get the pitch quite right on the pads.

![First PCB revision](/assets/img/gc_controller_reverse_engineering/chip_replacement_v1.jpg)
_First attempt at the PCB_

For the second attempt, I switched to OSHPark's flexible PCB service. The cost difference was negligible with a PCB so small. This time it fit perfectly. I implemented the controller protocol using an STM32 microcontroller.

![Second PCB Revision](/assets/img/gc_controller_reverse_engineering/chip_replacement_v2.jpg)
_Second attempt at the PCB. Much better!_

And there it was! I had a working GameCube controller (again). Although it isn't any better than a regular controller, it was a very interesting project academically, and it opens up opportunities for creating a full replacement board down the line. There will be more to come.
