import router from '@ohos.router';
import { LoginStore, LoginStoreActions } from './components/LoginStorage';

@Entry
@Component
struct Index {
  @State message: string = 'Loading';

  aboutToAppear(): void {
    this.init()
  }

  async init() {
    LoginStore.dispatch(LoginStoreActions.preLogin);
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