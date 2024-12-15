import { ComicListData } from "./ComicListData"
import rust, { UiComicInExplore, UiTags } from 'libcopi_rust.so'
import { ComicCardList } from "./ComicCardList"

@Component
@Entry
export struct Rank {

  @State dataList: ComicListData = new RecommendsListData()

  build() {
    Column() {
      Tabs({}) {
        TabContent() {

        }.tabBar('荐')

        TabContent() {

        }.tabBar('天')

        TabContent() {

        }.tabBar('周')

        TabContent() {

        }.tabBar('月')

        TabContent() {

        }.tabBar('总')
      }
      .barHeight(65)
      .height(65)
      ComicCardList({listData: this.dataList})
    }
    .width('100%').height('100%')
  }
}



class RecommendsListData extends ComicListData {
  constructor() {
    super((offset, limit) => rust.recommends(
      offset,
      limit,
    ));
  }
}
