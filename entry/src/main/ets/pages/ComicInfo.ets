import router from '@ohos.router';
import rust, {
  UiChapterData,
  UiComicChapter,
  UiComicData,
  UiComicInExplore,
  UiComicQuery,
  UiPageComicChapter
} from 'libcopi_rust.so'
import { ComicReader, ComicReaderParam } from './ComicReader';
import { ComicCard } from './components/ComicCard';
import { Error } from './components/Error';
import { Loading } from './components/Loading';
import { navStack } from './components/Nav';


@Entry
@Component
export struct ComicInfo {
  @State exploreComic: UiComicInExplore | null = null
  @State comicLoadingState: number = 0
  @State comicQuery: UiComicQuery | '' = ''
  @State comicData: UiComicData | null = null
  @State chapterDataMap: Map<string, Array<UiComicChapter>> = new Map()

  async init() {
    this.comicLoadingState = 0
    try {
      this.comicQuery = await rust.comicQuery(this.exploreComic!.pathWord)
      this.comicData = await rust.comic(this.exploreComic!.pathWord);
      console.error(`GROUPS : ${this.comicData.groups[0].pathWord}`)
      for (let i = 0; i < this.comicData.groups.length; i++) {
        let group = this.comicData!.groups[i];
        let cl = new Array<UiComicChapter>()
        const limit = 100
        let offset = 0
        while (true) {
          let cc = await rust.comicChapters(this.comicData.comic.pathWord, group.pathWord, limit, offset)
          cl = cl.concat(cc.list)
          offset += limit
          if (cc.limit + cc.offset >= cc.total) {
            break
          }
        }
        this.chapterDataMap[group.pathWord] = cl
      }
      this.comicLoadingState = 1
    } catch (e) {
      this.comicLoadingState = 2
    }
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        if (null != this.exploreComic) {
          ComicCard({ comic: this.exploreComic })
            .flexGrow(0)
            .flexShrink(0)
        }
        if (this.comicLoadingState == 0) {
          this.loading()
        } else if (this.comicLoadingState == 1) {
          this.comic(this.comicData as UiComicData)
        } else {
          this.error()
        }
      }.width('100%').height('100%')
    }
    .title('漫画')
    .onBackPressed(() => {
      return true
    })
    .backButtonIcon($r('sys.symbol.chevron_left'))
    .onReady((c) => {
      this.exploreComic = c.pathInfo.param as UiComicInExplore
      this.init()
    })
    .onBackPressed(() => {
      navStack.pop()
      return true
    })
  }

  @Builder
  comic(comicData: UiComicData) {
    List() {

      ForEach(comicData.groups, (group: rust.Group, groupIdx) => {
        ListItem().margin({ top: 20 })
        if (group.pathWord != 'default')
        ListItem() {
          Text(`${group.name}`)
            .padding({ left: 10 })
        }
        ListItem() {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.chapterDataMap[group.pathWord], (chapter: UiComicChapter, chapterIdx) => {
              Text(chapter.name)
                .fontSize(12)
                .margin(10)
                .padding({
                  left: 18,
                  right: 18,
                  top: 10,
                  bottom: 10,
                })
                .backgroundColor(Color.White)
                .borderRadius(5)
                .shadow({ radius: 3, color: Color.Gray })
                .onClick(() => {
                  navStack.pushPath(new NavPathInfo(
                    "pages/ComicReader",
                    this.comicReaderParam(chapter),
                  ))
                })
            })
          }
        }
      })
    }.width('100%').height('100%')
  }

  comicReaderParam(chapter: UiComicChapter): ComicReaderParam {
    return {
      exploreComic: this.exploreComic!,
      comicData: this.comicData!,
      chapterDataMap: this.chapterDataMap,
      chapter,
    };
  }

  @Builder
  loading() {
    Loading()
      .flexGrow(1)
      .flexShrink(1)
  }

  @Builder
  error() {
    Error({ text: '点击重试' })
      .flexGrow(1)
      .flexShrink(1)
      .onClick(() => {
        this.init()
      })
  }
}
