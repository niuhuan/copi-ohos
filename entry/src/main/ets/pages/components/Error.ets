@Entry
@Component
export struct Error {
  @Prop text: string

  build() {
    Column() {
      Text('Error')
      if (this.text != null && this.text.length > 0) {
        Blank()
          .height(20)
        Text(this.text)
      }
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}