import { IndicatorStatus, IndicatorWidget, LoadingMoreBase } from "@candies/loading_more_list"
import { ComicCard, ComicCardData } from "./ComicCard"
import { Error } from "./Error"
import { Loading } from "./Loading"
import { navStack } from "./Nav"


@Component
@Entry
export struct ComicCardList {
  private scroller: Scroller = new ListScroller()
  @Require @Prop listData: LoadingMoreBase<ComicCardData>

  build() {
    if (this.listData) {
      this.buildList()
    }
  }

  @Builder
  buildList() {
    if (this.listData.indicatorStatus == IndicatorStatus.empty) {
      Text('空空如也')
    } else if (
      this.listData.indicatorStatus == IndicatorStatus.fullScreenError
        || (this.listData.totalCount() == 1 && `${this.listData.getData(0)}` == 'LoadingMoreErrorItem')
    ) {
      Error()
        .width('100%')
        .height('100%')
        .onClick(() => {
          this.listData.refresh(true);
        })
    } else if (this.listData.totalCount() == 1 && this.listData.isLoadingMoreItem(this.listData.getData(0))) {
      Loading()
        .width('100%')
        .height('100%')
    } else {
      this.foreachList()
    }
  }

  @Builder
  foreachList() {
    List({ scroller: this.scroller }) {
      ListItem() {
        Column() {
        }.height(10)
      }

      LazyForEach(this.listData, (item: ComicCardData, index) => {
        ListItem() {
          if (this.listData.isLoadingMoreItem(item)) {
            if (this.listData.getLoadingMoreItemStatus(item)) {
              if (IndicatorStatus.noMoreLoad == this.listData.getLoadingMoreItemStatus(item)) {

              } else {
                IndicatorWidget({
                  indicatorStatus: this.listData.getLoadingMoreItemStatus(item),
                  sourceList: this.listData,
                })
              }
            }
          } else {
            ComicCard({ comic: item })
              .onClick(() => {
                navStack.pushPath(new NavPathInfo('pages/ComicInfo', item))
              })
          }
        }.width('100%')
      },
      )
    }
    .width('100%')
    .height('100%')
    .onReachEnd(() => {
      this.listData.loadMore();
    })
  }
}