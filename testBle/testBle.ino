#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890ab"
#define CHARACTERISTIC_UUID "abcdefab-1234-1234-1234-abcdefabcdef"

BLECharacteristic *pCharacteristic;
bool deviceConnected = false;

// ---------------- PARSER ----------------
void parseCommand(String cmd) {

  cmd.trim();

  int commaIndex = cmd.indexOf(',');

  if (commaIndex == -1) {
    Serial.println("⚠️ ERROR formato inválido");
    return;
  }

  String dpad = cmd.substring(0, commaIndex);
  String btn  = cmd.substring(commaIndex + 1);

  Serial.print("DPAD: ");
  Serial.print(dpad);
  Serial.print(" | BTN: ");
  Serial.println(btn);
}

// ---------------- SERVER CALLBACK ----------------
class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("✅ BLE Conectado");
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("❌ BLE Desconectado");
    pServer->startAdvertising();
  }
};

// ---------------- WRITE CALLBACK ----------------
class MyCallbacks: public BLECharacteristicCallbacks {

  void onWrite(BLECharacteristic *pCharacteristic) {

    String rx = pCharacteristic->getValue();
    if (rx.length() == 0) return;

    String data = String(rx.c_str());

    // 🔥 Procesa directamente por paquete recibido
    for (int i = 0; i < data.length(); i++) {
      char c = data[i];

      if (c == '#') {
        parseCommand(data);
      }
    }
  }
};

// ---------------- SETUP ----------------
void setup() {
  Serial.begin(115200);

  BLEDevice::init("ESP32_BLE_receiver");

  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_WRITE_NR |
    BLECharacteristic::PROPERTY_NOTIFY
  );

  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->start();

  Serial.println("🚀 BLE STREAM LISTO");
}

// ---------------- LOOP ----------------
void loop() {
  delay(10);
}