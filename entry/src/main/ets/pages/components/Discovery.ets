import { tags, UiTags, explorer, Tag } from 'native'
import { Loading } from './Loading';
import { ComicCardList } from './ComicCardList';
import { ComicListData } from './ComicListData';

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
      this.tags = await tags();
      let newOrdering = new Array<Tag>();
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
        ComicCardList({ listData: this.listData })
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
      color: '#66666666',
    })
  }
}

class ListData extends ComicListData {
  private order: string
  private theme: string
  private top: string

  constructor(order: string, theme: string, top: string) {
    super((offset, limit) => explorer(
      this.order.length == 0 ? null : this.order,
      this.top.length == 0 ? null : this.top,
      this.theme.length == 0 ? null : this.theme,
      offset,
      limit,
    ));
    this.order = order
    this.theme = theme
    this.top = top
  }
}
