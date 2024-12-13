import { UiLoginState } from 'libcopi_rust.so'
import rust from 'libcopi_rust.so'
import { HashMap } from '@kit.ArkTS'

class Context {
  private _loginEvent: Array<() => void> = []
  private _loginState: UiLoginState = {
    state: 0,
    message: ''
  }

  public get loginState(): UiLoginState {
    return this._loginState
  }

  public set loginState(loginState: UiLoginState) {
    this._loginState = loginState
  }

  public addLoginEvent(fn: () => void) {
    this._loginEvent.push(fn);
  }

  public removeLoginEvent(fn: () => void) {
    this._loginEvent = this._loginEvent.filter(f => f == fn);
  }

  public async login() {
    context.loginState = await rust.initLoginState();
    this._loginEvent.forEach(fn => fn())
  }

  Context() {
  }
}

export let context = new Context()

interface Colors {
  authorColor: string
  notActive: string
}

export let colors: Colors = {
  authorColor: "#F48FB1",
  notActive: "#999999"
}
