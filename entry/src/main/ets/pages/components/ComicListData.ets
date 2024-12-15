import { LoadingMoreBase } from '@candies/loading_more_list';
import { ComicCardData } from './ComicCard';

export interface DataExplore {
  offset: number,
  limit: number,
  list: Array<ComicCardData>,
}

export type DataExplorer = (offset: number, limit: number) => Promise<DataExplore>

export class ComicListData extends LoadingMoreBase<ComicCardData> {

  hasMore = true

  private offset = 0
  private limit = 20
  private fn: DataExplorer

  constructor(fn: DataExplorer) {
    super();
    this.fn = fn
  }

  public async refresh(notifyStateChanged: boolean = false): Promise<boolean> {
    this.offset = 0
    this.hasMore = true
    return super.refresh(notifyStateChanged);
  }

  async loadData(isLoadMoreAction: boolean): Promise<boolean> {
    try {
      let data = await this.fn(
        this.offset,
        this.limit,
      )
      this.offset += this.limit
      this.hasMore = data.list.length > 0
      this.addAll(data.list)
      return true
    } catch (e) {
      console.error(`FETCH ERROR : ${e}}`)
      return false
    }
  }
}

