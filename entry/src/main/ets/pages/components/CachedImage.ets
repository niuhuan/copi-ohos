import { cacheImage } from 'native'
import { url } from '@kit.ArkTS';
import { image } from '@kit.ImageKit';
import { materialIconData, materialIconsFontFamily } from './MaterialIcons';

@Entry
@Component
export struct CachedImage {
  @Require @Prop source: string
  @Prop useful: string
  @Prop extendsFieldFirst?: string
  @Prop extendsFieldSecond?: string
  @Prop extendsFieldThird?: string
  @Prop borderOptions?: BorderOptions
  @Prop imageWidth?: Length
  @Prop imageHeight?: Length
  @Prop ratio: number | null
  @Prop onSize: OnSize | null = null;
  @State state: number = 0
  @State pixelMap: image.PixelMap | null = null
  @State trueSize: image.Size | null = null
  @State absPath: string | null = null

  aboutToAppear(): void {
    this.init()
  }

  async init() {
    try {
      console.error(`load image : ${this.source}`)
      let ci = await cacheImage(
        this.cacheKey(this.source),
        this.source,
        this.useful ?? '',
        this.extendsFieldFirst ?? '',
        this.extendsFieldSecond ?? '',
        this.extendsFieldThird ?? '',
      )
      this.absPath = `file://${ci.absPath}`
      console.error(this.absPath)
      if (this.onSize != null) {
        this.onSize!.onSize({
          width: ci.imageWidth,
          height: ci.imageHeight,
        })
      }
      this.state = 1
    } catch (e) {
      this.state = 2
      console.error(`image error : ${e} `)
    }
  }

  cacheKey(source: string): string {
    let u = url.URL.parseURL(source)
    return u.pathname
  }

  build() {
    if (this.state == 1) {
      Image(this.absPath)
        .border(this.borderOptions)
        .width(this.imageWidth ?? '')
        .height(this.imageHeight ?? '')
        .aspectRatio(this.ratio)
        .objectFit(ImageFit.Cover)
        .renderFit(RenderFit.CENTER)
    } else {
      Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        if (this.state == 0) {
          Text(materialIconData('download'))
            .fontFamily(materialIconsFontFamily)
            .fontSize(30)
            .fontColor('#666666')
        } else {
          Text(materialIconData('error'))
            .fontFamily(materialIconsFontFamily)
            .fontSize(30)
            .fontColor('#666666')
        }
      }
      .width(this.imageWidth)
      .height(this.imageHeight)
      .aspectRatio(this.ratio)
    }
  }
}

interface OnSize {
  onSize: ((size: image.Size) => void)
}
