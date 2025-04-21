import { ComicListData, DataExplore } from "./ComicListData"
import { recommends, rank as nativeRank } from 'native'
import { ComicCardList } from "./ComicCardList"

@Component
@Entry
export struct Rank {
  @State dataList: ComicListData = new RecommendsListData()

  onChange(idx: number) {
    switch (idx) {
      case 0:
        this.dataList = new RecommendsListData()
        break;
      case 1:
        this.dataList = new RankListData("day")
        break;
      case 2:
        this.dataList = new RankListData("week")
        break;
      case 3:
        this.dataList = new RankListData("month")
        break;
      case 4:
        this.dataList = new RankListData("total")
        break;
    }
  }

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
      .onChange((a) => this.onChange(a))

      ComicCardList({ listData: this.dataList })
    }
    .width('100%').height('100%')
  }
}


class RecommendsListData extends ComicListData {
  constructor() {
    super((offset, limit) => recommends(
      offset,
      limit,
    ));
  }
}

class RankListData extends ComicListData {
  constructor(rank: string) {
    super((o, l) => {
      return this.rankLoad(o, l, rank)
    });
  }

  rankLoad(offset: number, limit: number, rank: string): Promise<DataExplore> {
    return nativeRank(rank, offset, limit).then(rankResult => {
      const a: DataExplore = {
        offset: rankResult.offset,
        limit: rankResult.limit,
        list: rankResult.list.map(r => {
          return r.comic
        }),
      };
      return a;
    })
  }
}
