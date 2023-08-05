---
layout: post
title: GameCube Adapter Reverse Engineering
categories:
- Projects
- GameCube Controller
tags:
- wii
- gamecube
image:
  path: /assets/img/gc_adapter_reverse_engineering/gc_adapter_reverse_engineering.jpg
  width: 1000
  height: 400
  alt: GameCube adapter
date: 2022-09-05 14:25 -0700
---
## Discrepancies with Emulators

[Dolphin Emulator](https://dolphin-emu.org/), a Wii/GameCube console emulator, [added native support](https://dolphin-emu.org/blog/2015/01/01/dolphin-progress-report-december-2014/) for the official Nintendo GameCube controller adapter back in 2014. This was a huge step forward, allowing GameCube controllers to be used on emulator without the need for a custom driver to make the controller emulate a Xinput or Dinput device. Unfortunately, at the time of writing, the input mechanism in Dolphin does not behave the same as console. I first noticed this issue with an Arduino-based GameCube controller emulator I was working on. I specifically programmed the device to always report the joystick [origin]({% link _posts/2022-09-04-gc-controller-reverse-engineering-part-1.md %}) to the console as (0, 0).

![The origin is incorrect on Dolphin](/assets/img/gc_adapter_reverse_engineering/wrong_origin.png)
_The origin on Dolphin is not (0, 0)_

After sifting through the Dolphin source code, it turned out that the GameCube adapter driver for Dolphin never sends the *origin* command to a controller. Instead, it interprets the first *status* response from the controller as the origin. Why was it done this way? The reason is because the interface that the GameCube adapter exposes to a programmer does not give direct access to sending JoyBus commands. Instead, there is a microcontroller inside the adapter that acts as a man-in-the-middle between the controller's data bus and the USB interface. Clearly, it's possible to send and receive data from the *status* command. But is it possible to do the same for an *origin* command?

## Using the USB Interface

The original reverse engineers of the adapter made a [thread on GBATemp](https://gbatemp.net/threads/wii-u-gamecube-adapter-reverse-engineering-cont.388169/) describing what can be done with the adapter. To summarize, there is a single USB interface descriptor that exposes two USB endpoints: one for writing and one for reading. Commands are written to the *write* endpoint (0x81) and responses (if any) are read from the *read* endpoint (0x02). The commands are not to be confused with JoyBus commands. Remember, there is a man-in-the-middle, so a different set of commands are used to *trigger* JoyBus commands. The command list is described below.

|        Command         | Send Format (write endpoint) | Response  Format (read endpoint)                                                            |
| :--------------------: | :--------------------------- | :------------------------------------------------------------------------------------------ |
|  0x11<br/>Set Rumble   | `[0x11, R1, R2, R3, R4]`     | None                                                                                        |
|    0x12<br/>Origins    | `[0x12]`                     | `[0x22,` <br/> `joyX[0], joyY[0], cX[0], cY[0], L[0], R[0],` <br/> `joyx[1],` ... <br/> `]` |
| 0x13<br/>Start Polling | `[0x13]`                     | None*                                                                                       |
| 0x14<br/>Stop Polling  | `[0x14]`                     | `[0x24, 0x01 if previously polling else 0x00]`                                              |
|  0x15<br/>Hard Reset   | `[0x15]`                     | None. Will not respond further until reinitialized.                                         |
|    0x16<br/>Unknown    | `[0x16, ...]`                | ?                                                                                           |
|    0x17<br/>Unknown    | `[0x17, ...]`                | ?                                                                                           |

\*After polling is started, reading from the *read* endpoint will deliver data in the format  
`[0x21,`  
`status[0], buttons0[0], buttons1[0], joyX[0], joyY[0], cX[0], cY[0], L[0], R[0],`  
`status[1],` ...  
`]`

The `status` field of the polling response contains some information about the controller. Bits 4 and 5 describe the type of controller. Bit 4 is set for a normal controller, and bit 5 is set for a Wavebird controller. This can be used to check if a controller is connected. If no controller is connected, the response for that controller is filled with `0x00`. The meaning of the other bits is unknown. Interestingly, handling controllers is always done with all four at a time as opposed to interacting with a single controller. 

The `buttons` fields contain the state of the buttons for a particular controller. The 2-byte value is described below. The format is almost the same as the JoyBus format, with the exception of the error/origin bits being omitted.

|  Bit  | Description               |
| :---: | :------------------------ |
|  15   | Unused                    |
|  14   | Unused                    |
|  13   | Unused                    |
|  12   | Unused                    |
|  11   | L (1 = pressed)           |
|  10   | R (1 = pressed)           |
|   9   | Z (1 = pressed)           |
|   8   | Start (1 = pressed)       |
|   7   | D-Pad Up (1 = pressed)    |
|   6   | D-Pad Down (1 = pressed)  |
|   5   | D-Pad Right (1 = pressed) |
|   4   | D-Pad Left (1 = pressed)  |
|   3   | Y (1 = pressed)           |
|   2   | X (1 = pressed)           |
|   1   | B (1 = pressed)           |
|   0   | A (1 = pressed)           |

You might have noticed there's an *Origins* command. Great! As far as I could tell, nobody had actually implemented any kind of driver that actually uses the *Origins* command yet. I tried it out myself and was not having much luck. To understand why, we need to take a look at what the adapter is doing under the hood.

## The Hardware State Machine

Let's look into what is actually happening on the JoyBus side. When the adapter is first powered on, it does not communicate with the controllers at all. Communications with the controller only start once the *Start Polling* command has been issued. After this command is sent, the adapter issues an *ID* JoyBus command followed by repeatedly sending the *origin* command. The adapter issues these repeated *origin* commands until a *status* response has been read from the *read* endpoint.

![GameCube adapter sending the origin command repeatedly](/assets/img/gc_adapter_reverse_engineering/origin_train.png)
_GameCube adapter sending the origin command repeatedly_

Great! So the adapter is capable of sending the *origin* command. It's also worth noting that the adapter *always* communicates at a frequency of 1kHz over the JoyBus link, regardless of what the USB driver is set to read at. By default, [your PC is probably polling slower than 1kHz](https://docs.google.com/document/d/1cQ3pbKZm_yUtcLK9ZIXyPzVbTJkvnfxKIyvuFMwzWe0/edit)! The next question is, why am I having difficulty retrieving the origin? And is there a way to trigger it when the adapter is already polling?

The answer is that you cannot reliably read the response from requesting the origins while the adapter is polling. Because the response to any given command to the adapter is received on the *read* endpoint, you may receive a *status* response when you read from the *read* endpoint, or you may receive the response to the command that you wanted to send, due to the asynchronous nature of how polling is implemented on the adapter. This is probably the reason why each response to a command to the adapter comes with a unique byte at the beginning of the response, indicating what command the response is for. Alternatively, a *Stop Polling* command can be issued to make requesting the origins synchronous, then a *Start Polling* command can be reissued after the origins request. This procedure may even be necessary, if the *status* response overwrites the *origin* response.

The answer to my second question is even more complex. After some experimentation, there is no easy way to get the adapter to ask the controller for its origin again once it leaves the repeated *origin* state. This is disappointing because ideally, Dolphin would do this any time a game is started. There is, however, *a* way. The *Hard Reset* command (dubbed by the GBATemp thread as the *Kill* command), was given the description: "Turns off the adapter and requires it to be unplugged and reconnect to begin working again". This is actually not true. This command simply requires the USB interface to be reinitialized before using the adapter again. By sending the *Hard Reset* command and reinitializing the USB interface, controllers will be put back into the repeated *origin* state.


## Conclusion

In summary, utilizing the *origin* command properly is feasible, but non-trivial. To correctly ask for a controller's origin, a driver needs to:

1. Send the *Hard Reset* command to the adapter
2. Reinitialize the USB interface
3. Send a *Start Polling* command (to put the controller into the repeated *origin* state)
4. Send a *Stop Polling* command (and read the response, to be able to synchronously receive the response of the *Origins* command)
5. Send an *Origins* command, and receive the response through the *read* endpoint
6. Send a *Start Polling* command, to resume polling

There may be another way, perhaps utilizing one of the two unknown commands, but this is the only way that I've discovered so far. I'm not sure the Dolphin devs want to put in the effort to achieve this level of accuracy, as it makes the driver a lot more complicated. Their current driver, at the time of writing, assumes the *read* endpoint is only for receiving *status* responses. For most controllers, a *status* response will be equivalent to the *origin* response anyway. There are some niche cases where they aren't though.

I wrote a driver that supports the *Origins* command using Python with [PyUSB](https://github.com/pyusb/pyusb). Feel free to play with it [here](https://github.com/jefflongo/gcadapter-python).
