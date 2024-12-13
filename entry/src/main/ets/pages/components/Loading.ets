@Entry
@Component
export struct Loading {
  build() {
    Column() {
      Progress({
        type: ProgressType.Ring,
        value: 50,
      }).style({ strokeWidth: 20, status: ProgressStatus.LOADING })
      Blank()
        .height(20)
      Text("登录中")
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}