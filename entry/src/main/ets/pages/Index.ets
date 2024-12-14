import { context } from '../data/context'
import router from '@ohos.router';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  aboutToAppear(): void {
    this.init()
  }

  async init() {
    await context.login()
    router.replaceUrl({
      url: 'pages/Home',
    })
  }

  build() {
    RelativeContainer() {
      Text(this.message)
        .id('Loading')
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
    }
    .height('100%')
    .width('100%')
  }
}