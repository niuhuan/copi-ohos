import rust from 'libcopi_rust.so'
import { url } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';

@Entry
@Component
export struct CachedImage {
  @Prop source: string
  @Prop useful: string
  @Prop extendsFieldFirst?: string
  @Prop extendsFieldSecond?: string
  @Prop extendsFieldThird?: string
  @Prop borderOptions?: BorderOptions
  @Prop imageWidth?: Length
  @Prop imageHeight?: Length
  @State state: number = 0
  @State pixelMap?: image.PixelMap = undefined

  aboutToAppear(): void {
    this.init()
  }

  async init() {
    try {
      console.error(`load image : ${this.source}`)
      let ci = await rust.cacheImage(
        this.cacheKey(this.source),
        this.source,
        this.useful,
        this.extendsFieldFirst,
        this.extendsFieldSecond,
        this.extendsFieldThird,
      )
      console.error(`absPath : ${this.pixelMap}`)
      const file: fileIo.File = await fileIo.open(ci.absPath, fileIo.OpenMode.READ_ONLY);
      const imageSource: image.ImageSource = image.createImageSource(file.fd);
      const pixelMap = await imageSource.createPixelMap();
      this.pixelMap = pixelMap
      this.state = 1
      console.error("")
    } catch (e) {
      this.state = 2
      console.error(`image error : ${e}`)
    }
  }

  cacheKey(source: string): string {
    let u = url.URL.parseURL(source)
    return u.pathname
  }

  build() {
    Flex() {
      if (this.state == 0) {
        Text('Loading')
      }
      if (this.state == 1) {
        Image(this.pixelMap)
          .border(this.borderOptions)
          .width(this.imageWidth)
          .height(this.imageHeight)
          .objectFit(ImageFit.Cover)
          .renderFit(RenderFit.CENTER)
          .key(this.source)
      }
      if (this.state == 2) {
        Text('Error')
      }
    }
    .width(this.imageWidth)
    .height(this.imageHeight)
  }
}
