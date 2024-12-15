import { ComicListData, DataExplore } from "./ComicListData"
import rust, { UiComicInExplore, UiTags } from 'libcopi_rust.so'
import { ComicCardData } from "./ComicCard"
import { ComicCardList } from "./ComicCardList"

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
      }.tabBar('研发中')
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
    return rust.listComicViewLogs(offset, limit).then(rankResult => {
      const a: DataExplore = {
        offset: rankResult.offset,
        limit: rankResult.limit,
        list: rankResult.list.map(r => {
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
