import { getApiHost, setApiHost } from "native";
import { colors } from "./Context";
import { materialIconData, materialIconsFontFamily } from "./MaterialIcons";

@Entry
@Component
export struct Settings {
  @State api: string = "";
  @State apiIsEditing: boolean = false;
  @State apiTemp: string = "";

  async initState() {
    this.api = await getApiHost();
  }

  async confirmApiSet(host: string) {
    await setApiHost(host);
    this.api = host;
    this.apiIsEditing = false;
  }

  aboutToAppear(): void {
    this.initState()
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text("网络和账户")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(colors.authorColor)
      }
      .width('100%')
      .height(20)
      .margin({top: 16})
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // API设置卡片
      Column() {
        Row() {
          Text(materialIconData('api'))
            .fontFamily(materialIconsFontFamily)
            .fontSize(24)
            .fontColor(colors.authorColor)
            .margin({ right: 12 })
          Text("API设置")
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .padding({ top: 16, bottom: 16, left: 16, right: 16 })

        if (this.apiIsEditing) {
          // 编辑模式
          Column() {
            TextInput({ placeholder: '请输入API地址', text: this.apiTemp })
              .width('100%')
              .height(40)
              .margin({ bottom: 12 })
              .onChange((value: string) => {
                this.apiTemp = value;
              })
            
            Row() {
              Button('取消')
                .backgroundColor('#F5F5F5')
                .fontColor('#666666')
                .onClick(() => {
                  this.apiIsEditing = false;
                  this.apiTemp = this.api;
                })
                .margin({ right: 12 })
                .flexGrow(1)
              
              Button('保存')
                .backgroundColor(colors.authorColor)
                .fontColor(Color.White)
                .onClick(() => {
                  if (this.apiTemp.trim().length > 0) {
                    this.confirmApiSet(this.apiTemp.trim());
                  }
                })
                .flexGrow(1)
            }
            .width('100%')
          }
          .padding({ left: 16, right: 16, bottom: 16 })
        } else {
          // 显示模式
          Row() {
            Text(this.api)
              .fontSize(14)
              .fontColor('#666666')
              .flexGrow(1)
            
            Button() {
              Row() {
                Text(materialIconData('edit'))
                  .fontFamily(materialIconsFontFamily)
                  .fontSize(16)
                  .fontColor(colors.authorColor)
                Text('编辑')
                  .fontSize(14)
                  .fontColor(colors.authorColor)
                  .margin({ left: 4 })
              }
            }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.apiTemp = this.api;
              this.apiIsEditing = true;
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(8)
      .margin({ top: 16, left: 16, right: 16 })
      .shadow({
        radius: 4,
        color: '#0000000A',
        offsetY: 2
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}