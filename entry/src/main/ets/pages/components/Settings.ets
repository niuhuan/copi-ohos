import { getApiHost, setApiHost, saveProperty } from "native";
import { colors } from "./Context";
import { materialIconData, materialIconsFontFamily } from "./MaterialIcons";
import { VersionStore, VersionStoreModel, VersionStoreActions } from "./VersionStore";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { loadProperty } from "native";
import { LoginStore, LoginStoreModel, LoginStoreActions } from "./LoginStorage";

@Entry
@ComponentV2
export struct Settings {
  @Local versionState: VersionStoreModel = VersionStore.getState();
  @Local loginStore: LoginStoreModel = LoginStore.getState();
  @Local api: string = "";
  @Local apiIsEditing: boolean = false;
  @Local apiTemp: string = "";
  @Local username: string = "";
  @Local password: string = "";
  @Local usernameIsEditing: boolean = false;
  @Local usernameTemp: string = "";
  @Local passwordIsEditing: boolean = false;
  @Local passwordTemp: string = "";

  async confirmUsernameSet(username: string) {
    await saveProperty("username", username);
    this.username = username;
    this.usernameIsEditing = false;
  }

  async confirmPasswordSet(password: string) {
    await saveProperty("password", password);
    this.password = password;
    this.passwordIsEditing = false;
  }

  async initState() {
    this.api = await getApiHost();
    this.username = await loadProperty("username");
    this.password = await loadProperty("password");
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
      .margin({ top: 16 })
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
        .padding({
          top: 16,
          bottom: 16,
          left: 16,
          right: 16
        })

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

      Divider().strokeWidth(1).color('#F5F5F5').margin({ left: 16, right: 16 });

      // Username
      if (this.usernameIsEditing) {
        Column() {
          Row() {
            Text("用户名")
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ right: 12 })
            TextInput({ placeholder: '请输入用户名', text: this.usernameTemp })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.usernameTemp = value;
              })
          }.padding({ top: 16, bottom: 12, left: 16, right: 16 })
          Row() {
            Button('取消')
              .backgroundColor('#F5F5F5')
              .fontColor('#666666')
              .onClick(() => {
                this.usernameIsEditing = false;
              })
              .margin({ right: 12 })
              .flexGrow(1)
            Button('保存')
              .backgroundColor(colors.authorColor)
              .fontColor(Color.White)
              .onClick(() => {
                if (this.usernameTemp.trim().length > 0) {
                  this.confirmUsernameSet(this.usernameTemp.trim());
                }
              })
              .flexGrow(1)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
      } else {
        Row() {
          Text("用户名")
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ right: 12 })
          Text(this.username)
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
            this.usernameTemp = this.username;
            this.usernameIsEditing = true;
          })
        }
        .width('100%')
        .padding({ top: 16, bottom: 16, left: 16, right: 16 })
      }

      Divider().strokeWidth(1).color('#F5F5F5').margin({ left: 16, right: 16 });

      // Password
      if (this.passwordIsEditing) {
        Column() {
          Row() {
            Text("密码")
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ right: 12 })
            TextInput({ placeholder: '请输入密码', text: this.passwordTemp })
              .type(InputType.Password)
              .layoutWeight(1)
              .onChange((value: string) => {
                this.passwordTemp = value;
              })
          }.padding({ top: 16, bottom: 12, left: 16, right: 16 })
          Row() {
            Button('取消')
              .backgroundColor('#F5F5F5')
              .fontColor('#666666')
              .onClick(() => {
                this.passwordIsEditing = false;
              })
              .margin({ right: 12 })
              .flexGrow(1)
            Button('保存')
              .backgroundColor(colors.authorColor)
              .fontColor(Color.White)
              .onClick(() => {
                if (this.passwordTemp.trim().length > 0) {
                  this.confirmPasswordSet(this.passwordTemp.trim());
                }
              })
              .flexGrow(1)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
      } else {
        Row() {
          Text("密码")
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ right: 12 })
          Text("********")
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
            this.passwordTemp = this.password;
            this.passwordIsEditing = true;
          })
        }
        .width('100%')
        .padding({ top: 16, bottom: 16, left: 16, right: 16 })
      }

      // 登录状态
      Row() {
        Text("登录状态")
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ right: 12 })

        if (this.loginStore.loginInfo.state === -1) {
          Row() {
            LoadingProgress().width(16).height(16).color(colors.authorColor)
            Text("登录中...")
              .fontSize(14)
              .fontColor('#666666')
              .margin({ left: 8 })
          }
        } else if (this.loginStore.loginInfo.state === 1) {
          Text("登录成功")
            .fontSize(14)
            .fontColor(colors.authorColor)
        } else if (this.loginStore.loginInfo.state === 0) {
          Text("未登录")
            .fontSize(14)
            .fontColor('#666666')
        } else {
          Text(`登录失败: ${this.loginStore.loginInfo.message}`)
            .fontSize(14)
            .fontColor('#FF0000')
        }
      }
      .width('100%')
      .padding({ top: 16, bottom: 16, left: 16, right: 16 })

      if (this.loginStore.loginInfo.state !== 1) {
        Button('登录')
          .width('100%')
          .height(40)
          .backgroundColor(this.loginStore.loginInfo.state === -1 ? '#E0E0E0' : colors.authorColor)
          .fontColor(Color.White)
          .enabled(this.loginStore.loginInfo.state !== -1)
          .onClick(() => {
            LoginStore.dispatch(LoginStoreActions.login);
          })
          .margin({ left: 16, right: 16, bottom: 16 })
      }

      // 版本信息卡片
      Column() {
        Row() {
          Text(materialIconData('info'))
            .fontFamily(materialIconsFontFamily)
            .fontSize(24)
            .fontColor(colors.authorColor)
            .margin({ right: 12 })
          Text("版本信息")
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .padding({
          top: 16,
          bottom: 16,
          left: 16,
          right: 16
        })

        Column() {
          Row() {
            Text("当前版本")
              .fontSize(14)
              .fontColor('#666666')
              .flexGrow(1)
            Text(this.versionState.currentVersion)
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .padding({ bottom: 12 })

          Row() {
            Text("最新版本")
              .fontSize(14)
              .fontColor('#666666')
              .flexGrow(1)
            if (this.versionState.loading) {
              LoadingProgress()
                .width(16)
                .height(16)
                .color(colors.authorColor)
            } else {
              Row() {
                Text(this.versionState.newVersion)
                  .fontSize(14)
                  .fontColor(this.versionState.compare > 0 ? colors.authorColor : '#666666')
                if (this.versionState.compare > 0) {
                  Badge({
                    count: 1,
                    position: BadgePosition.RightTop,
                    style: { color: colors.authorColor, fontSize: 12, badgeSize: 16 }
                  })
                }
              }
            }
          }
          .width('100%')
          .padding({ bottom: 16 })
        }
        .padding({ left: 16, right: 16, bottom: 16 })
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