use crate::copy_client::{Author, ErrorInfo, LoginResult, MemberInfo};
use crate::database::active::comic_view_log;
use crate::database::cache::{image_cache, web_cache};
use crate::database::download::{
    download_comic, download_comic_chapter, download_comic_group, download_comic_page,
};
use crate::database::properties::property;
use crate::udto::{
    ExportsType, UiCacheImage, UiChapterData, UiComicData, UiComicQuery, UiDownloadComic,
    UiDownloadComicChapter, UiDownloadComicGroup, UiDownloadComicPage, UiLoginState,
    UiPageCollectedComic, UiPageComicChapter, UiPageComicInExplore, UiPageRankItem,
    UiPageUiComicInList, UiPageUiViewLog, UiQueryDownloadComic, UiRegisterResult, UiTags,
    UiViewLog,
};
use crate::utils::{hash_lock, join_paths};
use crate::{downloading, get_image_cache_dir, CLIENT};
use image::EncodableLayout;
use napi_derive_ohos::napi;
use napi_ohos::Result;
use reqwest::Proxy;
use std::future::Future;
use std::time::Duration;

pub(crate) fn map_anyhow<T>(e: T) -> napi_ohos::Error
where
    T: std::fmt::Debug,
{
    napi_ohos::Error::new(napi_ohos::Status::GenericFailure, format!("{:?}", e))
}

#[napi]
pub async fn init(root: String) {
    crate::init_root(&root).await;
    set_proxy(get_proxy().await.unwrap()).await.unwrap();
}

#[napi]
pub async fn save_property(k: String, v: String) -> Result<()> {
    property::save_property(k, v).await.map_err(map_anyhow)
}

#[napi]
pub async fn load_property(k: String) -> Result<String> {
    property::load_property(k).await.map_err(map_anyhow)
}

#[napi]
pub async fn get_proxy() -> Result<String> {
    property::load_property("proxy".to_owned())
        .await
        .map_err(map_anyhow)
}

async fn block_on<T>(f: impl Future<Output = anyhow::Result<T>>) -> napi_ohos::Result<T>
where
    T: Send + Sync + 'static,
{
    f.await.map_err(map_anyhow)
}

#[napi]
pub async fn set_proxy(proxy: String) -> Result<()> {
    block_on(async move {
        CLIENT
            .set_agent(
                if proxy.is_empty() {
                    reqwest::Client::builder()
                } else {
                    reqwest::Client::builder().proxy(Proxy::all(proxy.as_str())?)
                }
                .danger_accept_invalid_certs(true)
                .build()?,
            )
            .await;
        property::save_property("proxy".to_owned(), proxy).await?;
        Ok(())
    })
    .await
}

#[napi]
pub async fn init_login_state() -> Result<UiLoginState> {
    block_on(async {
        let token = property::load_property("token".to_owned()).await?;
        if token.is_empty() {
            Ok(UiLoginState {
                state: 0,
                message: "".to_string(),
                member: Default::default(),
            })
        } else {
            CLIENT.set_token(token).await;
            match CLIENT.member_info().await {
                Ok(member) => Ok(UiLoginState {
                    state: 1,
                    message: "".to_string(),
                    member: Some(member),
                }),
                Err(err) => {
                    match err.info {
                        ErrorInfo::Network(e) => Ok(UiLoginState {
                            state: 2,
                            message: e.to_string(),
                            member: Default::default(),
                        }),
                        ErrorInfo::Message(_) => {
                            // token 已经失效
                            // todo : 用来token过期重新登录
                            // property::load_property("username".to_owned()).await?;
                            // property::load_property("password".to_owned()).await?;
                            property::save_property("token".to_owned(), "".to_owned()).await?;
                            Ok(UiLoginState {
                                state: 0,
                                message: "".to_string(),
                                member: None,
                            })
                        }
                        ErrorInfo::Convert(e) => Ok(UiLoginState {
                            state: 2,
                            message: e.to_string(),
                            member: None,
                        }),
                        ErrorInfo::Other(e) => Ok(UiLoginState {
                            state: 2,
                            message: e.to_string(),
                            member: None,
                        }),
                    }
                }
            }
        }
    })
    .await
}

#[napi]
pub async fn login(username: String, password: String) -> Result<UiLoginState> {
    block_on(async {
        let result = CLIENT.login(username.as_str(), password.as_str()).await;
        match result {
            Ok(ok) => {
                CLIENT.set_token(ok.token.clone()).await;
                property::save_property("token".to_owned(), ok.token.clone()).await?;
                property::save_property("username".to_owned(), username).await?;
                property::save_property("password".to_owned(), password).await?;
                let _ = web_cache::clean_web_cache_by_like(format!("COMIC_QUERY$%").as_str()).await;
                Ok(UiLoginState {
                    state: 1,
                    message: "".to_string(),
                    member: Some(member_from_result(ok)),
                })
            }
            Err(err) => match err.info {
                ErrorInfo::Network(err) => Ok(UiLoginState {
                    state: 2,
                    message: err.to_string(),
                    member: None,
                }),
                ErrorInfo::Message(err) => Ok(UiLoginState {
                    state: 2,
                    message: err,
                    member: None,
                }),
                ErrorInfo::Convert(err) => Ok(UiLoginState {
                    state: 2,
                    message: err.to_string(),
                    member: None,
                }),
                ErrorInfo::Other(err) => Ok(UiLoginState {
                    state: 2,
                    message: err.to_string(),
                    member: None,
                }),
            },
        }
    })
    .await
}

fn member_from_result(result: LoginResult) -> MemberInfo {
    MemberInfo {
        user_id: result.user_id,
        username: result.username,
        nickname: result.nickname,
        avatar: result.avatar,
        is_authenticated: result.is_authenticated,
        datetime_created: result.datetime_created,
        b_verify_email: result.b_verify_email,
        email: result.email,
        mobile: result.mobile,
        mobile_region: result.mobile_region,
        point: result.point,
        comic_vip: result.comic_vip,
        comic_vip_end: result.comic_vip_end,
        comic_vip_start: result.comic_vip_start,
        cartoon_vip: result.cartoon_vip,
        cartoon_vip_end: result.cartoon_vip_end,
        cartoon_vip_start: result.cartoon_vip_start,
        ads_vip_end: result.ads_vip_end,
        close_report: result.close_report,
        downloads: result.downloads,
        vip_downloads: result.vip_downloads,
        reward_downloads: result.reward_downloads,
        invite_code: result.invite_code,
        invited: result.invited,
        b_sstv: result.b_sstv,
        scy_answer: result.scy_answer,
        day_downloads_refresh: "".to_owned(),
        day_downloads: 0,
    }
}

#[napi]
pub async fn register(username: String, password: String) -> Result<UiRegisterResult> {
    block_on(async {
        match CLIENT.register(username.as_str(), password.as_str()).await {
            Ok(data) => Ok(UiRegisterResult {
                state: 1,
                message: "".to_string(),
                member: Some(data),
            }),

            Err(err) => match err.info {
                ErrorInfo::Network(err) => Ok(UiRegisterResult {
                    state: 2,
                    message: err.to_string(),
                    member: None,
                }),
                ErrorInfo::Message(err) => Ok(UiRegisterResult {
                    state: 2,
                    message: err,
                    member: None,
                }),
                ErrorInfo::Convert(err) => Ok(UiRegisterResult {
                    state: 2,
                    message: err.to_string(),
                    member: None,
                }),
                ErrorInfo::Other(err) => Ok(UiRegisterResult {
                    state: 2,
                    message: err.to_string(),
                    member: None,
                }),
            },
        }
    })
    .await
}

#[napi]
pub async fn rank(date_type: String, offset: i64, limit: i64) -> Result<UiPageRankItem> {
    let key = format!("COMIC_RANK${}${}${}", date_type, offset, limit);
    block_on(web_cache::cache_first_map(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move {
            CLIENT
                .comic_rank(date_type.as_str(), offset as u64, limit as u64)
                .await
        }),
    ))
    .await
}

#[napi]
pub async fn recommends(offset: i64, limit: i64) -> Result<UiPageUiComicInList> {
    let key = format!("COMIC_RECOMMENDS${}${}", offset, limit);
    block_on(web_cache::cache_first_map(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move { CLIENT.recommends(offset as u64, limit as u64).await }),
    ))
    .await
}

#[napi]
pub async fn comic(path_word: String) -> Result<UiComicData> {
    let key = format!("COMIC${}", path_word);
    web_cache::cache_first_map(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move { CLIENT.comic(path_word.as_str()).await }),
    )
    .await
    .map_err(map_anyhow)
}

#[napi]
pub async fn comic_chapters(
    comic_path_word: String,
    group_path_word: String,
    limit: i64,
    offset: i64,
) -> Result<UiPageComicChapter> {
    let key = format!("COMIC_CHAPTERS${comic_path_word}${group_path_word}${limit}${offset}");
    block_on(web_cache::cache_first_map(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move {
            CLIENT
                .comic_chapter(
                    comic_path_word.as_str(),
                    group_path_word.as_str(),
                    limit as u64,
                    offset as u64,
                )
                .await
        }),
    ))
    .await
}

#[napi]
pub async fn comic_query(path_word: String) -> Result<UiComicQuery> {
    let key = format!("COMIC_QUERY${path_word}");
    block_on(web_cache::cache_first_map(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move { CLIENT.comic_query(path_word.as_str()).await }),
    ))
    .await
}

#[napi]
pub async fn comic_chapter_data(
    comic_path_word: String,
    chapter_uuid: String,
) -> Result<UiChapterData> {
    let key = format!("COMIC_CHAPTER_DATA${comic_path_word}${chapter_uuid}");
    block_on(web_cache::cache_first_map(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move {
            CLIENT
                .comic_chapter_data(comic_path_word.as_str(), chapter_uuid.as_str())
                .await
        }),
    ))
    .await
}

#[napi]
pub async fn tags() -> Result<UiTags> {
    let key = format!("COMIC_TAGS");
    block_on(web_cache::cache_first_map(
        key,
        Duration::from_secs(60 * 60 * 15),
        Box::pin(async move { CLIENT.tags().await }),
    ))
    .await
}

#[napi]
pub async fn explorer(
    ordering: Option<String>,
    top: Option<String>,
    theme: Option<String>,
    offset: i64,
    limit: i64,
) -> Result<UiPageComicInExplore> {
    let key = format!(
        "COMIC_EXPLORER${:?}${:?}${:?}${}${}",
        ordering, top, theme, limit, offset
    );
    block_on(web_cache::cache_first_map(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move {
            CLIENT
                .explore(
                    ordering.as_deref(),
                    top.as_deref(),
                    theme.as_deref(),
                    offset as u64,
                    limit as u64,
                )
                .await
        }),
    ))
    .await
}

#[napi]
pub async fn comic_search(
    q_type: String,
    q: String,
    offset: i64,
    limit: i64,
) -> Result<UiPageUiComicInList> {
    let key = format!("COMIC_SEARCH${}${}${}${}", q_type, q, limit, offset);
    block_on(web_cache::cache_first_map(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move {
            CLIENT
                .comic_search(q_type.as_str(), q.as_str(), offset as u64, limit as u64)
                .await
        }),
    ))
    .await
}

#[napi]
pub async fn view_comic_info(
    comic_path_word: String,
    comic_name: String,
    comic_authors: Vec<Author>,
    comic_cover: String,
) -> Result<()> {
    Ok(comic_view_log::view_info(comic_view_log::Model {
        comic_path_word,
        comic_name,
        comic_authors: serde_json::to_string(&comic_authors).map_err(map_anyhow)?,
        comic_cover,
        ..Default::default()
    })
    .await
    .map_err(map_anyhow)?)
}

#[napi]
pub async fn view_chapter_page(
    comic_path_word: String,
    chapter_uuid: String,
    chapter_name: String,
    chapter_ordered: i64,
    chapter_size: i64,
    chapter_count: i64,
    page_rank: i32,
) -> Result<()> {
    comic_view_log::view_page(comic_view_log::Model {
        comic_path_word,
        chapter_uuid,
        chapter_name,
        chapter_ordered,
        chapter_size,
        chapter_count,
        page_rank,
        ..Default::default()
    })
    .await
    .map_err(map_anyhow)
}

#[napi]
pub async fn find_comic_view_log(path_word: String) -> Result<Option<UiViewLog>> {
    block_on(async move {
        Ok(
            if let Some(model) = comic_view_log::view_log_by_comic_path_word(path_word).await? {
                Some(UiViewLog::from(model))
            } else {
                None
            },
        )
    })
    .await
}

#[napi]
pub async fn list_comic_view_logs(offset: i64, limit: i64) -> Result<UiPageUiViewLog> {
    block_on(async move {
        let count = comic_view_log::count().await?;
        let list = comic_view_log::load_view_logs(offset as u64, limit as u64).await?;
        Ok(UiPageUiViewLog {
            total: count as i64,
            limit,
            offset,
            list: list.into_iter().map(UiViewLog::from).collect(),
        })
    })
    .await
}

#[napi]
pub async fn collect_to_account(
    comic_id: String,
    is_collect: bool,
    comic_path_word: String,
) -> Result<()> {
    collect_to_account_move(comic_id, is_collect, comic_path_word).await
}

async fn collect_to_account_move(
    comic_id: String,
    is_collect: bool,
    comic_path_word: String,
) -> Result<()> {
    CLIENT
        .collect(comic_id.as_str(), is_collect)
        .await
        .map_err(map_anyhow)?;
    web_cache::clean_web_cache_by_like("COMIC_COLLECT%")
        .await
        .map_err(map_anyhow)?;
    web_cache::clean_web_cache_by_like(format!("COMIC_QUERY${comic_path_word}").as_str())
        .await
        .map_err(map_anyhow)?;
    Ok(())
}

#[napi]
pub async fn collect_from_account(
    free_type: i64,
    ordering: String,
    offset: i64,
    limit: i64,
) -> Result<UiPageCollectedComic> {
    let key = format!("COMIC_COLLECT${free_type}${ordering}${offset}${limit}$");
    block_on(web_cache::cache_first_map(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move {
            CLIENT
                .collected_comics(free_type, ordering.as_str(), offset as u64, limit as u64)
                .await
        }),
    ))
    .await
}

#[napi]
pub async fn cache_image(
    cache_key: String,
    url: String,
    useful: String,
    extends_field_first: Option<String>,
    extends_field_second: Option<String>,
    extends_field_third: Option<String>,
) -> Result<UiCacheImage> {
    block_on(async {
        let _ = hash_lock(&url).await;
        if let Some(model) = image_cache::load_image_by_cache_key(cache_key.as_str()).await? {
            image_cache::update_cache_time(cache_key.as_str()).await?;
            Ok(UiCacheImage::from(model))
        } else if let Some(model) = download_comic::has_download_cover(cache_key.clone()).await? {
            // check downloads images has the same key
            Ok(UiCacheImage::from(model))
        } else if let Some(model) = download_comic_page::has_download_pic(cache_key.clone()).await?
        {
            // check downloads images has the same key
            Ok(UiCacheImage::from(model))
        } else {
            let local_path = hex::encode(md5::compute(&url).as_slice());
            let abs_path = join_paths(vec![get_image_cache_dir().as_str(), &local_path]);
            let bytes = CLIENT.download_image(url.as_str()).await?;
            let format = image::guess_format(bytes.as_bytes())?;
            let format = if let Some(format) = format.extensions_str().first() {
                format.to_string()
            } else {
                "".to_string()
            };
            let image = image::load_from_memory(&bytes)?;
            let model = image_cache::Model {
                cache_key,
                url,
                useful,
                extends_field_first,
                extends_field_second,
                extends_field_third,
                local_path,
                cache_time: chrono::Local::now().timestamp_millis(),
                image_format: format,
                image_width: image.width(),
                image_height: image.height(),
            };
            let model = image_cache::insert(model.clone()).await?;
            tokio::fs::write(&abs_path, &bytes).await?;
            Ok(UiCacheImage::from(model))
        }
    })
    .await
}

#[napi]
pub async fn clean_cache(time: i64) -> Result<()> {
    block_on(async move {
        let time = chrono::Local::now().timestamp() - time;
        clean_web(time).await?;
        clean_image(time).await?;
        crate::database::cache::vacuum().await?;
        Ok(())
    })
    .await
}

async fn clean_web(time: i64) -> anyhow::Result<()> {
    web_cache::clean_web_cache_by_time(time).await
}

async fn clean_image(time: i64) -> anyhow::Result<()> {
    let dir = get_image_cache_dir();
    loop {
        let caches: Vec<image_cache::Model> = image_cache::take_100_cache(time).await?;
        if caches.is_empty() {
            break;
        }
        for cache in caches {
            let local = join_paths(vec![dir.as_str(), cache.local_path.as_str()]);
            image_cache::delete_by_cache_key(cache.cache_key).await?; // 不管有几条被作用
            let _ = std::fs::remove_file(local); // 不管成功与否
        }
    }
    Ok(())
}

#[napi]
pub async fn delete_download_comic(comic_path_word: String) -> Result<()> {
    block_on(downloading::delete_download_comic(comic_path_word)).await
}

#[napi]
pub async fn append_download(data: UiQueryDownloadComic) -> Result<()> {
    block_on(downloading::append_download(data.clone())).await
}

#[napi]
pub async fn in_download_chapter_uuid(comic_path_word: String) -> Result<Vec<String>> {
    block_on(download_comic_chapter::in_download_chapter_uuid(
        comic_path_word,
    ))
    .await
}

#[napi]
pub async fn reset_fail_downloads() -> Result<()> {
    block_on(downloading::reset_fail_downloads()).await
}

#[napi]
pub async fn download_comics() -> Result<Vec<UiDownloadComic>> {
    Ok(block_on(download_comic::all())
        .await?
        .into_iter()
        .map(UiDownloadComic::from)
        .collect())
}

#[napi]
pub async fn download_comic_groups(comic_path_word: String) -> Result<Vec<UiDownloadComicGroup>> {
    let coll = download_comic_group::find_by_comic_path_word(comic_path_word.as_str())
        .await
        .map_err(map_anyhow)?;
    Ok(coll.into_iter().map(UiDownloadComicGroup::from).collect())
}

#[napi]
pub async fn download_comic_chapters(
    comic_path_word: String,
) -> Result<Vec<UiDownloadComicChapter>> {
    Ok(block_on(download_comic_chapter::find_by_comic_path_word(
        comic_path_word.as_str(),
    ))
    .await?
    .into_iter()
    .map(UiDownloadComicChapter::from)
    .collect())
}

#[napi]
pub async fn download_comic_pages(
    comic_path_word: String,
    chapter_uuid: String,
) -> Result<Vec<UiDownloadComicPage>> {
    Ok(block_on(
        download_comic_page::find_by_comic_path_word_and_chapter_uuid(
            comic_path_word.as_str(),
            chapter_uuid.as_str(),
        ),
    )
    .await?
    .into_iter()
    .map(UiDownloadComicPage::from)
    .collect())
}

#[napi]
pub async fn download_is_pause() -> Result<bool> {
    Ok(downloading::download_is_pause().await)
}

#[napi]
pub async fn download_set_pause(pause: bool) -> Result<()> {
    Ok(downloading::download_set_pause(pause).await)
}

#[napi]
pub async fn http_get(url: String) -> Result<String> {
    block_on(http_get_inner(url)).await
}

async fn http_get_inner(url: String) -> anyhow::Result<String> {
    Ok(reqwest::ClientBuilder::new()
        .user_agent("kobi")
        .build()?
        .get(url)
        .send()
        .await?
        .error_for_status()?
        .text()
        .await?)
}

pub fn desktop_root() -> Result<String> {
    #[cfg(target_os = "windows")]
    {
        use anyhow::Context;
        Ok(join_paths(vec![
            std::env::current_exe()
                .map_err(map_anyhow)?
                .parent()
                .with_context(|| "error")
                .map_err(map_anyhow)?
                .to_str()
                .with_context(|| "error")
                .map_err(map_anyhow)?,
            "data",
        ]))
    }
    #[cfg(target_os = "macos")]
    {
        use anyhow::Context;
        let home = std::env::var_os("HOME")
            .with_context(|| "error")
            .map_err(map_anyhow)?
            .to_str()
            .with_context(|| "error")
            .map_err(map_anyhow)?
            .to_string();
        Ok(join_paths(vec![
            home.as_str(),
            "Library",
            "Application Support",
            "opensource",
            "kobi",
        ]))
    }
    #[cfg(target_os = "linux")]
    {
        use anyhow::Context;
        let home = std::env::var_os("HOME")
            .with_context(|| "error")
            .map_err(crate::api::api::map_anyhow)?
            .to_str()
            .with_context(|| "error")
            .map_err(crate::api::api::map_anyhow)?
            .to_string();
        Ok(join_paths(vec![home.as_str(), ".opensource", "kobi"]))
    }
    #[cfg(not(any(target_os = "linux", target_os = "windows", target_os = "macos")))]
    panic!("未支持的平台")
}

#[napi]
pub async fn exports(
    uuid_list: Vec<String>,
    export_to_folder: String,
    exports_type: String,
) -> Result<()> {
    block_on(crate::exports::exports(
        uuid_list,
        export_to_folder,
        exports_type,
    ))
    .await
}
