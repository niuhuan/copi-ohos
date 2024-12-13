import { colors, context } from '../data/context'
import { Discovery } from './components/Discovery'
import { materialIconData, materialIconsFontFamily } from './components/MaterialIcons'

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
    Column() {
      Tabs({ barPosition: BarPosition.End, controller: this.tabController, index: this.currentIndex }) {
        TabContent() {
          Text('hot')
        }.tabBar(this.hotTabMenu())

        TabContent() {
          Discovery()
            .width('100%')
            .height('100%')
        }.tabBar(this.discoverTabMenu())

        TabContent() {
          Text('user')
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
