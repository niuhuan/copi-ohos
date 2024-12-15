const hexChars = "0123456789abcdef"

export class Uuid {
  public static v4(): string {
    return Uuid.v4Instance().toString();
  }

  public static v4Instance(): UuidV4 {
    return new UuidV4();
  }
}

// DATA:
// RANDOM 128 bytes
// AND calculate
// POSITION & 0x 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 | 0x 06 07 08 09 10 11 12 13 14 15
//     DATA & 0x FF FF FF FF FF FF 4F FF BF FF FF FF FF FF FF FF | 0x 40 00 80 00 00 00 00 00 00 00
// STR-FORMAT: 8-4-4-4-12
class UuidV4 extends Uuid {
  private data: Uint8Array

  constructor() {
    super();
    this.data = this.generate()
  }

  generate(): Uint8Array {
    let buffer = new ArrayBuffer(16);
    const view = new DataView(buffer);
    for (let i = 0; i < 4; i++) {
      view.setUint32(4 * i, (Math.random() * 0xFFFFFFFFFF) ^ 0xFFFFFFFF)
    }
    view.setUint8(6, view.getUint8(6) & 0x4F | 0x40)
    view.setUint8(8, view.getUint8(8) & 0xBF | 0x80)
    return new Uint8Array(buffer);
  }

  toString(): string {
    let hex = "";
    for (let i = 0; i < this.data.length; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        hex += '-'
      }
      const byte = this.data[i];
      hex += hexChars.charAt((byte >> 4) & 0x0f) + hexChars.charAt(byte & 0x0f)
    }
    return hex;
  }
}
