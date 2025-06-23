import { Action, Reducer, StateStore, Store } from "@hadss/state_store";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { initLoginState } from "native";
import { UiLoginState } from "native";
import { loadProperty } from "native";
import { login } from "native";


@ObservedV2
export class LoginStoreModel {
  @Trace public loginInfo: UiLoginState = {
    state: 0,
    message: ""
  };
}

export class LoginStoreActions {
  static preLogin: Action = StateStore.createAction('preLogin');
  static login: Action = StateStore.createAction('login');
}

export const loginStoreReducer: Reducer<LoginStoreModel> = (state: LoginStoreModel, action: Action) => {
  hilog.info(0x0000, 'StateStore', 'actions: %{public}s', action.type);
  switch (action.type) {
    case LoginStoreActions.preLogin.type:
      return async () => {
        state.loginInfo = await initLoginState();
      }
    case LoginStoreActions.login.type:
      return async () => {
        let username = await loadProperty("username");
        let password = await loadProperty("password");
        state.loginInfo = await login(
          username,
          password,
        );
      };
  }
  return null;
}

export const LoginStore: Store<LoginStoreModel> =
  StateStore.createStore('LoginStore', new LoginStoreModel(), loginStoreReducer, []);

