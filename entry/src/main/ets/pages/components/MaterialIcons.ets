import { font } from '@kit.ArkUI'
import { codePoints } from './MaterialIconsCodePoints'

export const materialIconsFontFamily: string = 'Material Icons'

font.registerFont({
  familyName: materialIconsFontFamily,
  familySrc: $rawfile('MaterialIcons-Regular.ttf')
})

const charMap = new Map<string, string>()

const lines = codePoints.split('\n');
lines.forEach(line => {
  if (line.length > 0) {
    const split = line.split(" ");
    if (split.length == 2 && split[1].match(/^[0-9a-zA-Z]{4}$/)) {
      charMap.set(
        split[0],
        String.fromCodePoint(parseInt(split[1], 16)),
      )
    }
  }
});

export function materialIconData(name: string): string {
  return charMap.get(name) ?? '?';
}