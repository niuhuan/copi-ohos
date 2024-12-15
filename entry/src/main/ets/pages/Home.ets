import { colors, context } from './components/Context'
import { ComicInfo } from './ComicInfo'
import { ComicReader } from './ComicReader'
import { Discovery } from './components/Discovery'
import { materialIconData, materialIconsFontFamily } from './components/MaterialIcons'
import { navStack } from './components/Nav'
import { Rank } from './components/Rank'
import { User } from './components/User'

@Entry
@Component
struct Home {
  @State currentIndex: number = 1
  @State flushPage: number = 1
  private tabController: TabsController = new TabsController()

  aboutToAppear(): void {
    context.addLoginEvent(this.onLoginChange)
  }

  aboutToDisappear(): void {
    context.removeLoginEvent(this.onLoginChange)
  }

  onLoginChange(): void {
    this.flushPage *= -1
  }

  build() {
    Navigation(navStack) {
      this.tabs()
    }.navDestination(this.pageMap)
  }

  @Builder
  pageMap(name: string) {
    if (name == 'pages/ComicInfo') {
      ComicInfo()
    } else if (name == 'pages/ComicReader') {
      ComicReader()
    }
  }

  @Builder
  tabs() {
    Column() {
      Tabs({ barPosition: BarPosition.End, controller: this.tabController, index: this.currentIndex }) {
        TabContent() {
          Column() {
            Rank()
            Blank(1).shadow({
              radius: 3,
              color: '#66666666',
            })
          }
        }.tabBar(this.hotTabMenu())

        TabContent() {
          Column() {
            Discovery()
              .width('100%')
              .height('100%')
            Blank(1).shadow({
              radius: 3,
              color: '#66666666',
            })
          }
        }.tabBar(this.discoverTabMenu())

        TabContent() {
          Column() {
            User()
            Blank(1).shadow({
              radius: 3,
              color: '#66666666',
            })
          }
        }.tabBar(this.bookmarkTabMenu())
      }
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .barHeight(65)
    }.width('100%').height('100%')
  }

  @Builder
  hotTabMenu() {
    this.tabMenu(
      '排行',
      'local_fire_department',
      0
    )
  }

  @Builder
  discoverTabMenu() {
    this.tabMenu(
      '发现',
      'language',
      1
    )
  }

  @Builder
  bookmarkTabMenu() {
    this.tabMenu(
      '个人',
      'face',
      2
    )
  }

  @Builder
  tabMenu(name: string, icon: string, index: number) {
    Flex({
      justifyContent: FlexAlign.Center,
      alignItems: ItemAlign.Center,
      direction: FlexDirection.Column
    }) {
      Blank(1)
      Text(materialIconData(icon))
        .fontFamily(materialIconsFontFamily)
        .fontSize(30)
        .fontColor(index == this.currentIndex ? colors.authorColor : colors.notActive)
      Blank(1)
      Text(name)
        .fontSize(12)
        .fontColor(index == this.currentIndex ? colors.authorColor : colors.notActive)
      Blank(1)
    }.width('100%').height('100%')
  }
}
