import { Action, Middleware, MiddlewareStatus, Reducer, StateStore, Store } from "@hadss/state_store";
import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import bundleManager from '@ohos.bundle.bundleManager';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { colors } from "./Context";
import { UIContext } from "@kit.ArkUI";
import { common, Want } from '@kit.AbilityKit';

let uiContext: UIContext;

export function setUiContext(s: UIContext) {
  uiContext = s;
}

interface ReleaseInfo {
  tag_name: string
}

@ObservedV2
export class VersionStoreModel {
  @Trace public loading = false;
  @Trace public currentVersion = '';
  @Trace public newVersion = '';
  @Trace public compare = 0;
}

export class VersionStoreActions {
  static refresh: Action = StateStore.createAction('refresh');
}

let display = false;

export const versionMiddleware: Middleware<VersionStoreModel> = {
  actionType: VersionStoreActions.refresh.type,
  beforeAction: (state: VersionStoreModel, action: Action): Action | MiddlewareStatus => {
    return MiddlewareStatus.NEXT;
  },
  afterAction: (state: VersionStoreModel, action: Action): Action | MiddlewareStatus => {
    hilog.info(0x0000, 'StateStore', '2: %{public}s', JSON.stringify(state));
    if (display) {
      return MiddlewareStatus.NEXT;
    }
    if (state.compare > 0) {
      display = true;
      promptAction.showDialog({
        title: '发现新版本',
        message: `当前版本: ${state.currentVersion}\n最新版本: ${state.newVersion}\n\n是否前往下载？`,
        buttons: [
          {
            text: '取消',
            color: '#666666'
          },
          {
            text: '前往下载',
            color: colors.authorColor
          }
        ]
      }).then((result) => {
        if (result.index === 1) {
          let link = "https://github.com/niuhuan/copi-ohos/releases";
          try {
            (uiContext.getHostContext() as common.UIAbilityContext).startAbility({
              uri: link,
            })
          } catch (e) {
            console.log(e);
          }
        }
      });
    }
    return MiddlewareStatus.NEXT;
  },
}

export const versionStoreReducer: Reducer<VersionStoreModel> = (state: VersionStoreModel, action: Action) => {
  hilog.info(0x0000, 'StateStore', 'actions: %{public}s', action.type);
  switch (action.type) {
    case VersionStoreActions.refresh.type:
      return async () => {
        if (state.loading) {
          return;
        }
        state.loading = true;
        try {
          let bundleInfo =
            await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
          state.currentVersion = bundleInfo.versionName;
          let httpRequest = http.createHttp();
          let response = await httpRequest.request(
            "https://api.github.com/repos/niuhuan/copi-ohos/releases/latest",
            {
              method: http.RequestMethod.GET,
              header: {
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'copi-ohos'
              }
            }
          );
          let releaseInfo: ReleaseInfo = JSON.parse(response.result as string);
          state.newVersion = releaseInfo.tag_name.substring(1);
          state.compare = compareVersions(state.newVersion, state.currentVersion);
          hilog.info(0x0000, 'StateStore', 'end: %{public}s', JSON.stringify(state));
        } catch (e) {
          hilog.info(0x0000, 'StateStore', 'error: %{public}s', JSON.stringify(e));
        } finally {
          state.loading = false;
        }
      }
    default:
      break;
  }
  return null;
};


export const VersionStore: Store<VersionStoreModel> =
  StateStore.createStore('VersionStore', new VersionStoreModel(), versionStoreReducer, [versionMiddleware]);


// 比较版本号，返回1表示version1更新，-1表示version2更新，0表示相同
function compareVersions(version1: string, version2: string): number {
  let v1 = version1.split('.').map(Number);
  let v2 = version2.split('.').map(Number);

  for (let i = 0; i < Math.max(v1.length, v2.length); i++) {
    let num1 = v1[i] || 0;
    let num2 = v2[i] || 0;

    if (num1 > num2) {
      return 1;
    }
    if (num1 < num2) {
      return -1;
    }
  }
  return 0;
}
