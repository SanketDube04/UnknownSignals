# Universal IR Remote

A programmable IR remote built on ESP32 that can **learn, store, and re-transmit IR codes from any device** — no cloud, no app, just hardware.

---

## Motivation

Most consumer IR remotes are locked to a single device and protocol. Lose one, and your only options are a replacement or a cheap universal remote with poor reliability.

I wanted to build one remote that could control anything — and more importantly, understand *why* IR communication fails in real conditions.

---

## Features

- Learns IR codes from any existing remote
- Stores codes digitally on the ESP32
- Re-transmits reliably using a transistor-driven IR LED
- Supports NEC protocol + raw timing fallback for unknown protocols
- Button-mapped command replay

---

## Hardware

| Component | Purpose |
|---|---|
| ESP32 | IR decoding, storage, transmission |
| TSOP IR Receiver (38 kHz) | Captures incoming IR signals |
| IR LED | Transmits IR signals |
| NPN Transistor | Drives IR LED with sufficient current |
| Current-limiting resistor | Protects circuit |

### Key Design Decision: Transistor Driver

Early attempts drove the IR LED directly from an ESP32 GPIO pin. This caused:
- Very poor range
- Inconsistent device responses
- Slight pin heating

**Fix:** An NPN transistor was added as a driver stage, allowing the LED to draw the short bursts of high current required for reliable IR transmission without stressing the GPIO.

---

## System Architecture

```
[IR Receiver] → [ESP32: Decode + Store] → [Button Press] → [ESP32: Replay] → [IR LED Driver] → [Device]
```

**Data flow:**
1. TSOP receiver captures incoming IR signal
2. ESP32 decodes protocol and timing
3. Code is stored in memory, linked to a button
4. On button press, ESP32 re-transmits via transistor-driven IR LED

---

## Firmware

The firmware is split into three logical stages:

### 1. IR Capture
- Reads raw signal from TSOP receiver
- Attempts protocol decoding (NEC first)
- Falls back to raw timing storage if protocol is unrecognized

### 2. Storage
- Decoded/raw codes stored in memory
- Each code mapped to a button input

### 3. Transmission
- Reproduces signal at correct carrier frequency (38 kHz)
- Accurate timing reproduction for protocol compliance

---

## What Failed First

This project did not work on the first attempt.

**Attempt 1 — Direct GPIO drive:**
Connected IR LED with a resistor directly to ESP32 GPIO. Result was weak range and inconsistent behavior. Root cause: GPIO pins cannot source enough current for IR transmission.

**Attempt 2 — Reception worked, transmission didn't:**
The TSOP correctly captured signals, but re-transmitting failed on certain devices. Root cause: assumed all IR protocols share the same timing tolerances. They don't.

These failures led to a deeper understanding of IR protocol timing, carrier frequencies, and hardware current requirements.

---

## Tech Stack

`ESP32` · `C++` · `TSOP IR Receiver` · `NPN Transistor Driver` · `IRremoteESP8266`

---

## Future Improvements

- [ ] Persistent storage using EEPROM/SPIFFS (currently RAM-only)
- [ ] Web interface for code management over Wi-Fi
- [ ] Support for more protocols (RC5, RC6, Samsung)
- [ ] Custom PCB design

---

*Built by [Sanket Dube](https://unknownsignals.vercel.app)*
