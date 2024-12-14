import rust, { UiComicInExplore, UiTags } from 'libcopi_rust.so'
import { IndicatorWidget, LoadingMoreBase, } from '@candies/loading_more_list'
import { Loading } from './Loading';
import { ComicCard } from './ComicCard';
import { navStack } from './Nav';


@Entry
@Component
export struct Discovery {
  @State listData: ListData = new ListData('', '', '');
  @State tagsState: number = 0
  @State tags: UiTags = {
    ordering: [],
    theme: [],
    top: []
  }
  @State ordering: number = 0
  @State theme: number = 0
  @State top: number = 0

  resetListData() {
    this.listData = new ListData(
      this.tags.ordering[this.ordering].pathWord,
      this.tags.theme[this.theme].pathWord,
      this.tags.top[this.top].pathWord,
    )
  }

  aboutToAppear(): void {
    this.init()
  }

  async init() {
    try {
      this.tags = await rust.tags();
      let newOrdering = new Array<rust.Tag>();
      this.tags.ordering.forEach(o => {
        newOrdering.push({
          name: `${o.name}-倒序`,
          pathWord: `-${o.pathWord}`,
        })
        newOrdering.push(o)
      });
      this.tags.ordering = newOrdering
      this.tags.theme.unshift({
        name: '全部',
        pathWord: '',
        count: 0,
        initials: 0,
      })
      this.tags.top.unshift({
        name: '全部',
        pathWord: '',
      })
      this.tagsState = 1
      this.resetListData()
    } catch (e) {
      this.tagsState = 2
    }
  }

  build() {
    if (this.tagsState == 0) {
      Loading()
    } else if (this.tagsState == 1) {
      Flex({ direction: FlexDirection.Column }) {
        this.tagsSelector()
        this.buildList()
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  tagsSelector() {
    Flex() {
      Select([
        ...this.tags.ordering.map((t) => {
          return {
            value: t.name,
          } as SelectOption
        }),
      ])
        .selected(this.ordering)
        .value(this.tags.ordering[this.ordering].name)
        .onSelect((idx, value) => {
          this.ordering = idx
          this.resetListData()
        })
        .flexGrow(1)
        .flexShrink(1)
      Select([
        ...this.tags.theme.map((t) => {
          return {
            value: t.name,
          } as SelectOption
        }),
      ])
        .selected(this.theme)
        .value(this.tags.theme[this.theme].name)
        .onSelect((idx, value) => {
          this.theme = idx
          this.resetListData()
        })
        .flexGrow(1)
        .flexShrink(1)
      Select([
        ...this.tags.top.map((t) => {
          return {
            value: t.name,
          } as SelectOption
        }),
      ])
        .selected(this.top)
        .value(this.tags.top[this.top].name)
        .onSelect((idx, value) => {
          this.top = idx
          this.resetListData()
        })
        .flexGrow(1)
        .flexShrink(1)
    }
    .flexGrow(0)
    .flexShrink(0)
    .padding({
      top: 10,
      bottom: 10,
    })
    .shadow({
      radius: 3,
    })
  }

  @Builder
  buildList() {
    List() {
      ListItem() {
        Column() {
        }.height(10)
      }

      ForEach(this.listData, (item: UiComicInExplore, index) => {
        ListItem() {
          if (this.listData.isLoadingMoreItem(item)) {
            IndicatorWidget({
              indicatorStatus: this.listData.getLoadingMoreItemStatus(item),
              sourceList: this.listData,
            })
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
    .onReachEnd(() => {
      this.listData.loadMore();
    })
  }
}

class ListData extends LoadingMoreBase<UiComicInExplore> {
  private order: string
  private theme: string
  private top: string

  constructor(order: string, theme: string, top: string) {
    super();
    this.order = order
    this.theme = theme
    this.top = top
  }

  hasMore = true
  offset = 0
  limit = 20
  list = new Array<UiComicInExplore>()

  public async refresh(notifyStateChanged: boolean = false): Promise<boolean> {
    this.offset = 0
    this.hasMore = true
    return super.refresh(notifyStateChanged);
  }

  async loadData(isLoadMoreAction: boolean): Promise<boolean> {
    try {
      let data = await rust.explorer(
        this.order.length == 0 ? null : this.order,
        this.top.length == 0 ? null : this.top,
        this.theme.length == 0 ? null : this.theme,
        this.offset,
        this.limit,
      )
      this.offset += this.limit
      this.hasMore = data.list.length > 0
      this.addAll(data.list)
    } catch (e) {
      console.error(`FETCH ERROR : ${e}}`)
      throw e as Error
    }
    return true
  }
}
