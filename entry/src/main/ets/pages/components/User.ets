import { ComicListData, DataExplore } from "./ComicListData"
import { ComicCardData } from "./ComicCard"
import { ComicCardList } from "./ComicCardList"
import { listComicViewLogs } from 'native'
import { Settings } from "./Settings"

@Component
@Entry
export struct User {
  @State listData: HistoryListData = new HistoryListData()

  onChange(idx: number) {
    switch (idx) {
    }
  }

  build() {
    Tabs({}) {
      TabContent() {
        ComicCardList({ listData: this.listData })
      }.tabBar('历史记录')

      TabContent() {
        Settings()
      }.tabBar('设置')
    }
    .width('100%').height('100%')
  }
}


class HistoryListData extends ComicListData {
  constructor() {
    super((o, l) => {
      return this.listComicViewLogs(o, l)
    });
  }

  listComicViewLogs(offset: number, limit: number): Promise<DataExplore> {
    return listComicViewLogs(offset, limit).then(rustResult => {
      const a: DataExplore = {
        offset: rustResult.offset,
        limit: rustResult.limit,
        list: rustResult.list.map(r => {
          let b: ComicCardData = {
            name: r.comicName,
            pathWord: r.comicPathWord,
            author: JSON.parse(r.comicAuthors),
            cover: r.comicCover,
            popular: 0,
          }
          return b
        }),
      };
      return a;
    })
  }
}
