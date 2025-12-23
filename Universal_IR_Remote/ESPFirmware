#include <Arduino.h>
#include <IRremote.h>
#include <Preferences.h>
#include <BluetoothSerial.h>

#define IR_RECV_PIN 15
#define IR_SEND_PIN 4

BluetoothSerial BT;
Preferences prefs;

bool isLearning = false;
int learningButtonId = -1;

// =====================================================
// Convert Protocol Enum → String
// =====================================================
String protocolToString(decode_type_t proto) {
  switch (proto) {
    case NEC: return "NEC";
    case ONKYO: return "ONKYO";
    case SONY: return "SONY";
    case SAMSUNG: return "SAMSUNG";
    case LG: return "LG";
    case PANASONIC: return "PANASONIC";
    default: return "UNKNOWN";
  }
}

// =====================================================
// Convert String → Protocol Enum
// =====================================================
decode_type_t stringToProtocol(String s) {
  s.toUpperCase();
  if (s == "NEC") return NEC;
  if (s == "ONKYO") return ONKYO;
  if (s == "SONY") return SONY;
  if (s == "SAMSUNG") return SAMSUNG;
  if (s == "LG") return LG;
  if (s == "PANASONIC") return PANASONIC;
  return UNKNOWN;
}

// =====================================================
// Setup
// =====================================================
void setup() {
  Serial.begin(115200);
  BT.begin("MY_IR_REMOTE");

  pinMode(IR_SEND_PIN, OUTPUT);
  digitalWrite(IR_SEND_PIN, LOW);

  IrReceiver.begin(IR_RECV_PIN, ENABLE_LED_FEEDBACK);
  IrSender.begin(IR_SEND_PIN, ENABLE_LED_FEEDBACK);

  prefs.begin("irlearn", false);

  Serial.println("=== UPGRADED PHASE 2 READY ===");
  Serial.println("Supports NEC, Onkyo, etc. Repeat-filter fixed.");
}

// =====================================================
// Process Bluetooth Commands
// =====================================================
void handleCommand(String cmd) {
  cmd.trim();
  int colon = cmd.indexOf(':');
  if (colon == -1) return;

  String action = cmd.substring(0, colon);
  int id = cmd.substring(colon + 1).toInt();

  // ---------------- LEARN ----------------
  if (action == "LEARN") {
    isLearning = true;
    learningButtonId = id;

    BT.println("LEARNING_START");
    Serial.println("Learning Mode for Button " + String(id));
    
    // Clear any buffered IR data to prevent instant triggering
    if (IrReceiver.decode()) {
      IrReceiver.resume();
    }
    return;
  }

  // ---------------- SEND ----------------
  if (action == "SEND") {

    String key = "btn_" + String(id);
    String stored = prefs.getString(key.c_str(), "");

    if (stored == "") {
      BT.println("ERROR_NOT_LEARNED");
      return;
    }

    // Split stored record
    int p1 = stored.indexOf(',');
    int p2 = stored.indexOf(',', p1 + 1);
    int p3 = stored.indexOf(',', p2 + 1);

    String protoStr  = stored.substring(0, p1);
    String addrStr   = stored.substring(p1 + 1, p2);
    String cmdStr    = stored.substring(p2 + 1, p3);
    int bits         = stored.substring(p3 + 1).toInt();

    decode_type_t proto = stringToProtocol(protoStr);
    uint32_t address = strtoul(addrStr.c_str(), NULL, 16);
    uint32_t command = strtoul(cmdStr.c_str(), NULL, 16);

    Serial.println("Sending: " + stored);

    switch (proto) {
      case NEC:
        IrSender.sendNEC(address, command, 0);
        break;

      case ONKYO:
        IrSender.sendOnkyo(address, command, 0);
        break;

      default:
        IrSender.sendNEC(address, command, 0);
        break;
    }

    BT.println("SEND_OK");
  }
}

// =====================================================
// Main Loop
// =====================================================
void loop() {

  // Handle Bluetooth input
  if (BT.available()) {
    String cmd = BT.readStringUntil('\n');
    handleCommand(cmd);
  }

  // Handle Learning Mode
  if (isLearning && IrReceiver.decode()) {

    auto &data = IrReceiver.decodedIRData;

    // ---------------- IGNORE NEC REPEAT ----------------
    if (data.flags & IRDATA_FLAGS_IS_REPEAT) {
      Serial.println("Ignored NEC Repeat Frame");
      IrReceiver.resume();
      return;
    }

    String proto = protocolToString(data.protocol);

    uint32_t address = data.address;
    uint32_t command = data.command;
    uint8_t bits = data.numberOfBits;

    // Build storage string
    char record[64];
    sprintf(record, "%s,0x%X,0x%X,%d",
            proto.c_str(), address, command, bits);

    // Save to preferences
    String key = "btn_" + String(learningButtonId);
    prefs.putString(key.c_str(), record);

    // Feedback
    Serial.println("LEARNED: " + String(record));
    BT.println(String("LEARNED:") + record);

    IrReceiver.resume();
    isLearning = false;
  }
}
