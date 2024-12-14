pub mod api;
use crate::database::init_database;
use base64::Engine;
use copy_client::Client;
use lazy_static::lazy_static;
use once_cell::sync::OnceCell;
use std::sync::Arc;
use tokio::runtime;
use tokio::sync::Mutex;
use utils::create_dir_if_not_exists;
use utils::join_paths;
pub mod copy_client;
mod database;
pub mod downloading;
mod exports;
mod udto;
mod utils;

const API_URL: &str = "aHR0cHM6Ly9hcGkubWFuZ2Fjb3B5LmNvbQ==";
// const API_URL_ORIGIN: &str = "aHR0cHM6Ly9hcGkuY29weW1hbmdhLm5ldA==";

fn api_url() -> String {
    String::from_utf8(base64::prelude::BASE64_STANDARD.decode(API_URL).unwrap()).unwrap()
}

lazy_static! {
    pub(crate) static ref CLIENT: Arc<Client> = Arc::new(Client::new(
        reqwest::ClientBuilder::new()
            .danger_accept_invalid_certs(true)
            .connect_timeout(std::time::Duration::from_secs(5))
            .read_timeout(std::time::Duration::from_secs(10))
            .build()
            .unwrap(),
        api_url()
    ));
    static ref INIT_ED: Mutex<bool> = Mutex::new(false);
}

static ROOT: OnceCell<String> = OnceCell::new();
static IMAGE_CACHE_DIR: OnceCell<String> = OnceCell::new();
static DATABASE_DIR: OnceCell<String> = OnceCell::new();
static DOWNLOAD_DIR: OnceCell<String> = OnceCell::new();

pub async fn init_root(path: &str) {
    let mut lock = INIT_ED.lock().await;
    if *lock {
        return;
    }
    *lock = true;
    println!("Init application with root : {}", path);
    ROOT.set(path.to_owned()).unwrap();
    IMAGE_CACHE_DIR
        .set(join_paths(vec![path, "image_cache"]))
        .unwrap();
    DATABASE_DIR
        .set(join_paths(vec![path, "database"]))
        .unwrap();
    DOWNLOAD_DIR
        .set(join_paths(vec![path, "download"]))
        .unwrap();
    create_dir_if_not_exists(ROOT.get().unwrap());
    create_dir_if_not_exists(IMAGE_CACHE_DIR.get().unwrap());
    create_dir_if_not_exists(DATABASE_DIR.get().unwrap());
    create_dir_if_not_exists(DOWNLOAD_DIR.get().unwrap());
    init_database().await;
    *downloading::DOWNLOAD_AND_EXPORT_TO.lock().await =
        database::properties::property::load_property("download_and_export_to".to_owned())
            .await
            .unwrap();
    *downloading::PAUSE_FLAG.lock().await =
        database::properties::property::load_property("download_pause".to_owned())
            .await
            .unwrap()
            == "true";
    tokio::spawn(downloading::start_download());
}

#[allow(dead_code)]
pub(crate) fn get_root() -> &'static String {
    ROOT.get().unwrap()
}

pub(crate) fn get_image_cache_dir() -> &'static String {
    IMAGE_CACHE_DIR.get().unwrap()
}

pub(crate) fn get_database_dir() -> &'static String {
    DATABASE_DIR.get().unwrap()
}

pub(crate) fn get_download_dir() -> &'static String {
    DOWNLOAD_DIR.get().unwrap()
}

#[cfg(not(target_family = "wasm"))]
#[napi_ohos::module_init]
fn init() {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .worker_threads(20)
        .thread_keep_alive(std::time::Duration::from_secs(60))
        .max_blocking_threads(10)
        .build()
        .unwrap();
    napi_ohos::bindgen_prelude::create_custom_tokio_runtime(rt);
}
