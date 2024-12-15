import { Author, UiComicInExplore } from 'libcopi_rust.so'
import { colors } from '../../data/context'
import { CachedImage } from './CachedImage'
import { materialIconData, materialIconsFontFamily } from './MaterialIcons'

export interface ComicCardData {
  name: string
  pathWord: string
  author: Array<Author>
  cover: string
  popular: number
  datetimeUpdated?: string
}

@Entry
@Component
export struct ComicCard {
  @Require @Prop comic: ComicCardData

  build() {
    Flex() {
      CachedImage({
        source: this.comic.cover,
        useful: 'COMIC_COVER',
        extendsFieldFirst: this.comic.pathWord,
        borderOptions: { radius: 3.5 },
        imageWidth: 328 / 4,
        imageHeight: 422 / 4,
      })
        .width(328 / 4)
        .height(422 / 4)
        .flexShrink(0)
        .flexGrow(0)
      Blank(10)
      Column() {
        Blank(10)
        Text(`${this.comic.name}\n`)
          .maxLines(2)
          .fontWeight(FontWeight.Bold)
        Blank(10)
        Text(this.comic.author?.map(a => a.name)?.join("、") ?? "")
          .fontSize(14)
          .fontColor(colors.authorColor)
        Blank(10)
        Flex() {
          Text(this.comic.datetimeUpdated)
            .flexGrow(0)
            .flexShrink(0)
          Blank(1)
            .flexGrow(1)
            .flexShrink(1)
          Text(materialIconData('local_fire_department'))
            .fontFamily(materialIconsFontFamily)
            .fontColor(colors.authorColor)
            .fontSize(16)
          Text(` ${this.comic.popular}`)
            .flexGrow(0)
            .flexShrink(0)
            .fontSize(14)
        }
      }
      .flexGrow(1)
      .alignItems(HorizontalAlign.Start)
    }
    .padding({
      top: 8,
      bottom: 8,
      left: 15,
      right: 15
    })
    .border({
      color: '#33666666',
      width: .4,
    })
  }
}
