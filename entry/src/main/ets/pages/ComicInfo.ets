import router from '@ohos.router';
import {
  UiChapterData,
  UiComicChapter,
  UiComicData,
  UiComicInExplore,
  UiComicQuery,
  UiPageComicChapter,
  UiViewLog,
  comicQuery,
  comic,
  comicChapters,
  findComicViewLog,
  Group,
  viewComicInfo,
} from 'native'
import { ComicReader, ComicReaderParam } from './ComicReader';
import { ComicCard } from './components/ComicCard';
import { Error } from './components/Error';
import { Loading } from './components/Loading';
import { navEvents, navNamesJoin, navStack } from './components/Nav';
import { Uuid } from './components/Uuid';


@Entry
@Component
export struct ComicInfo {
  @State exploreComic: UiComicInExplore | null = null
  @State comicLoadingState: number = 0
  @State comicQuery: UiComicQuery | '' = ''
  @State comicData: UiComicData | null = null
  @State chapterDataMap: Map<string, Array<UiComicChapter>> = new Map()
  @State viewLog: UiViewLog | null = null
  @State namesJoin: string = ''
  @State uuid: string = ''

  async reloadViewLog() {
    if (this.comicData != null) {
      this.viewLog = await findComicViewLog(this.comicData.comic.pathWord);
    }
  }

  aboutToAppear(): void {
    this.namesJoin = navNamesJoin()
    this.uuid = Uuid.v4()
    navEvents.set(this.uuid, (nj) => {
      if (nj == this.namesJoin) {
        this.reloadViewLog()
      }
    })
  }

  aboutToDisappear(): void {
    navEvents.delete(this.uuid)
  }

  async init() {
    this.comicLoadingState = 0
    try {
      this.comicQuery = await comicQuery(this.exploreComic!.pathWord)
      this.comicData = await comic(this.exploreComic!.pathWord);
      console.error(`GROUPS : ${this.comicData.groups[0].pathWord}`)
      for (let i = 0; i < this.comicData.groups.length; i++) {
        let group = this.comicData!.groups[i];
        let cl = new Array<UiComicChapter>()
        const limit = 100
        let offset = 0
        while (true) {
          let cc = await comicChapters(this.comicData.comic.pathWord, group.pathWord, limit, offset)
          cl = cl.concat(cc.list)
          offset += limit
          if (cc.limit + cc.offset >= cc.total) {
            break
          }
        }
        this.chapterDataMap[group.pathWord] = cl
      }
      this.viewLog = await findComicViewLog(this.comicData.comic.pathWord);
      await viewComicInfo(
        this.comicData.comic.pathWord,
        this.comicData.comic.name,
        this.comicData.comic.author,
        this.comicData.comic.cover,
      )
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
      ListItem().margin({ top: 20 })
      ListItem() {
        if (this.viewLog != null && this.viewLog.chapterUuid.length > 0) {
          Flex({ justifyContent: FlexAlign.Center }) {
            this.continueButton()
          }
        }
      }

      ListItem() {
        Flex({ justifyContent: FlexAlign.Center }) {
          this.firstChapterButton()
        }
      }

      ForEach(comicData.groups, (group: Group, groupIdx) => {
        ListItem().margin({ top: 20 })
        if (group.pathWord != 'default')
        ListItem() {
          Text(`${group.name}`)
            .padding({ left: 10 })
        }
        ListItem() {
          Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceEvenly }) {
            ForEach(this.chapterDataMap[group.pathWord], (chapter: UiComicChapter, chapterIdx) => {
              this.chapterButton(chapter)
            })
          }
        }
      })
    }.width('100%').height('100%')
  }

  @Builder
  continueButton() {
    if (this.continueChapter() != null) {
      this.chapterButton(this.continueChapter()!, `从 ${this.viewLog!.chapterName} 继续观看`)
    }
  }

  @Builder
  firstChapterButton() {
    if (this.firstChapter() != null) {
      this.chapterButton(this.firstChapter()!, '从头开始看')
    }
  }

  firstChapter(): UiComicChapter | null {
    for (let i = 0; i < this.comicData!.groups.length; i++) {
      const g = this.comicData!.groups[i]!;
      const cs: Array<UiComicChapter> = this.chapterDataMap[g.pathWord]!;
      for (let j = 0; j < cs.length; j++) {
        return cs[j];
      }
    }
    return null
  }

  continueChapter(): UiComicChapter | null {
    for (let i = 0; i < this.comicData!.groups.length; i++) {
      const g = this.comicData!.groups[i]!;
      const cs: Array<UiComicChapter> = this.chapterDataMap[g.pathWord]!;
      for (let j = 0; j < cs.length; j++) {
        if (cs[j]?.uuid == this.viewLog?.chapterUuid) {
          return cs[j];
        }
      }
    }
    return null
  }

  @Builder
  chapterButton(chapter: UiComicChapter, text?: string) {
    Text(text ?? chapter.name)
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
