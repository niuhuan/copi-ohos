import rust, {
  ChapterImage,
  Comic,
  UiChapterData,
  UiComicChapter,
  UiComicData,
  UiComicInExplore,
  UiComicQuery
} from "libcopi_rust.so"
import { CachedImage } from "./components/CachedImage"
import { Error } from "./components/Error"
import { Loading } from "./components/Loading"
import { image } from '@kit.ImageKit';
import { window } from '@kit.ArkUI';
import { common } from "@kit.AbilityKit";

@Entry
@Component
export struct ComicReader {
  private listScroller: ListScroller = new ListScroller()
  private context = getContext(this) as common.UIAbilityContext;
  @State param: ComicReaderParam | null = null
  @State loadingState: number = 0
  @State data: UiChapterData | null = null
  @State sizeMap: Map<string, image.Size> = new Map()
  @State toolBarHeight: number = 0
  @State fullScreen: boolean = false

  async init() {
    this.loadingState = 0
    try {
      this.data = await rust.comicChapterData(
        this.param!.exploreComic.pathWord,
        this.param!.chapter.uuid,
      )
      this.loadingState = 1
    } catch (e) {
      this.loadingState = 2
    }
    let win = await window.getLastWindow(this.context)
    const avoidAreaType = window.AvoidAreaType.TYPE_SYSTEM;
    const avoidArea = win.getWindowAvoidArea(avoidAreaType);
    const height = avoidArea.topRect.height;
    this.toolBarHeight = height
  }

  build() {
    NavDestination() {
      if (this.param != null) {
        this.content(this.param!)
      }
    }.onReady(context => {
      this.param = context.pathInfo.param! as ComicReaderParam
      this.init()
    })
    .backgroundColor('#000')
    .hideTitleBar(true)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM]) // LayoutSafeAreaEdge
  }

  @Builder
  content(param: ComicReaderParam) {
    if (this.loadingState == 0) {
      Loading()
    } else if (this.loadingState == 1) {
      Stack() {
        this.reader(param, this.data!)
        if (!this.fullScreen) {
          this.barBottom()
        }
        if (this.sliderInValue != undefined) {
          this.sliding()
        }
      }
    } else {
      Error({ text: '点击重试' })
        .flexGrow(1)
        .flexShrink(1)
        .onClick(() => {
          this.init()
        })
    }
  }

  @Builder
  barBottom() {
    Flex() {
      Slider({
        value: this.sliderValue,
        min: 0,
        max: this.data!.chapter.contents.length - 1,
        step: 1,
      })
        .onTouch((e) => {
          if (e.type == TouchType.Down) {
            this.sliderInValue = this.sliderValue
            this.sliderOutValue = this.sliderInValue
          }
          if (e.type == TouchType.Up) {
            console.error(`LEAVE ${this.sliderInValue} ${this.sliderOutValue}`)
            if (this.sliderOutValue != this.sliderInValue) {
              this.sliderValue = this.sliderOutValue
              this.listScroller.scrollToIndex(this.sliderValue + 1)
            }
            this.sliderInValue = undefined
          }
        })
        .onChange((e) => {
          if (this.sliderValue != undefined) {
            this.sliderOutValue = e
          }
        })
    }
    .position({ bottom: 0 })
    .padding({
      top: 10,
      bottom: 25,
      left: 20,
      right: 20
    })
    .backgroundColor('#99000000')

  }

  @Builder
  sliding() {
    Row() {
      Text(`${this.sliderOutValue! + 1} / ${this.data!.chapter.contents.length}`)
        .align(Alignment.Center)
        .alignSelf(ItemAlign.Center)
        .textAlign(TextAlign.Center)
        .fontColor('#FFF')
        .fontWeight(FontWeight.Bold)
        .fontSize(35)
        .borderRadius(8)
        .backgroundColor('#99000000')
        .padding(30)
    }.alignItems(VerticalAlign.Center)
  }

  @State sliderValue: number = 0
  @State sliderInValue: number | undefined = undefined
  @State sliderOutValue: number = 0

  @Builder
  reader(param: ComicReaderParam, data: UiChapterData) {
    List({ scroller: this.listScroller }) {
      ListItem().height(this.toolBarHeight)
      ForEach(
        data.chapter.contents,
        (image: ChapterImage, idx) => {
          ListItem() {
            CachedImage({
              source: image.url,
              useful: 'comic_reader',
              extendsFieldFirst: param.exploreComic.pathWord,
              extendsFieldSecond: param.chapter.groupPathWord,
              extendsFieldThird: param.chapter.uuid,
              onSize: {
                onSize: (size) => this.sizeMap[image.url] = size
              },
              imageWidth: '100%',
              ratio: this.sizeMap[image.url] ? this.sizeMap[image.url]!.width / this.sizeMap[image.url].height : 1,
            })
          }
        }
      )
    }
    .width('100%')
    .height('100%')
    .onScrollIndex((s, e, c) => {
      this.sliderValue = (s < 1 ? 1 : s) - 1
    })
    .onClick(() => {
      this.fullScreen = !this.fullScreen
    })
  }
}

export interface ComicReaderParam {
  exploreComic: UiComicInExplore
  comicData: UiComicData
  chapterDataMap: Map<string, Array<UiComicChapter>>
  chapter: UiComicChapter
}