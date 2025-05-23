import { getApiHost, setApiHost } from "native";

@Entry
@Component
export struct Settings {
  @State api: String = "";

  async initState() {
    this.api = await getApiHost();
  }

  async confirmApiSet(host: string) {
    await setApiHost(host);
    this.api = host;
  }

  aboutToAppear(): void {
    this.initState()
  }

  build() {
  }
}