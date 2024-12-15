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
import { navStack } from "./components/Nav";

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
  @State sliderValue: number = 0
  @State sliderInValue: number | undefined = undefined
  @State sliderOutValue: number = 0

  async init() {
    this.loadingState = 0
    let win = await window.getLastWindow(this.context)
    const avoidAreaType = window.AvoidAreaType.TYPE_SYSTEM;
    const avoidArea = win.getWindowAvoidArea(avoidAreaType);
    const height = avoidArea.topRect.height;
    this.toolBarHeight = height
    try {
      this.data = await rust.comicChapterData(
        this.param!.exploreComic.pathWord,
        this.param!.chapter.uuid,
      )
      await rust.viewChapterPage(
        this.param!.comicData.comic.pathWord,
        this.param!.chapter.uuid,
        this.param!.chapter.name,
        this.param!.chapter.ordered,
        this.param!.chapter.size,
        this.param!.chapter.count,
        0
      )
      this.loadingState = 1
    } catch (e) {
      this.loadingState = 2
    }
  }

  setChapter(chapter: UiComicChapter) {
    this.loadingState = 0
    this.listScroller.scrollTo({ xOffset: 0, yOffset: 0 })
    this.param!.chapter = chapter
    this.data = null
    this.sizeMap.clear()
    this.sliderValue = 0
    this.sliderInValue = undefined
    this.init()
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
          this.barTop()
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
  barTop() {
    Flex() {
      Text() {
        SymbolSpan($r('sys.symbol.arrow_left'))
          .fontSize(20)
      }.fontColor('#fff')
      .onClick(() => {
        navStack.pop()
      })
    }.position({ top: 0 })
    .padding({
      top: 45,
      bottom: 25,
      left: 30,
      right: 20
    })
    .backgroundColor('#99000000')
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
      ListItem() {
        Column() {
          Text(' 下一章 ')
            .padding(40)
            .fontSize(35)
            .fontColor('#fff')
            .backgroundColor('#66999999')
            .align(Alignment.Center)
            .alignSelf(ItemAlign.Center)
            .onClick(() => this.nextChapter())
        }.alignItems(HorizontalAlign.Center)
        .width('100%')
      }

      ListItem().height(this.toolBarHeight)
    }
    .width('100%')
    .height('100%')
    .onScrollIndex((s, e, c) => {
      if (this.data != null) {
        if (s < 1) {
          this.sliderValue = 0
        } else if (s >= this.data!.chapter.contents.length) {
          this.sliderValue = this.data!.chapter.contents.length - 1
        } else {
          this.sliderValue = s - 1
        }
      }
    })
    .onClick(() => {
      this.fullScreen = !this.fullScreen
    })
  }

  nextChapter() {
    const next = this.nextChapterValue();
    if (next) {
      this.setChapter(next)
    }
  }

  nextChapterValue(): UiComicChapter | null {
    let acc = false
    for (let i = 0; i < this.param!.comicData.groups.length; i++) {
      let g = this.param!.comicData.groups[i]!;
      let cs: Array<UiComicChapter> = this.param!.chapterDataMap[g.pathWord]!;
      for (let j = 0; j < cs.length; j++) {
        let c = cs[j]!;
        if (acc) {
          return c
        }
        if (c.uuid == this.param!.chapter.uuid) {
          acc = true
        }
      }
    }
    return null
  }
}

export interface ComicReaderParam {
  exploreComic: UiComicInExplore
  comicData: UiComicData
  chapterDataMap: Map<string, Array<UiComicChapter>>
  chapter: UiComicChapter
}