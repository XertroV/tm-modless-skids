void Main(){
    startnew(LoadFonts);
    startnew(SkidsCache::SoftInit);
    startnew(ModFolders::Load);
    while (true) {
        while (!SkidsCache::_skidsCached) yield();
        while (!IsSafeToUpdateSkids()) yield();
        sleep(500);
        if (IsSafeToUpdateSkids()) {
            startnew(ApplySkids);
            break;
        }
    }
}

//remove any hooks
void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
    // we don't want to do this in a playground
    if (IsSafeToUpdateSkids()) {
        RestoreOriginalSkids();
    } else {
        NotifyWarning("Unsafe to restore original skidmarks, skipping");
    }
}

// Must be in main menu so game state is as expected
bool IsSafeToUpdateSkids() {
    auto switcher = GetApp().Switcher;
    return switcher.ModuleStack.Length == 1 && cast<CTrackManiaMenus>(switcher.ModuleStack[0]) !is null;
}

void Render() {
    ExtractProgress::Draw();
}

void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}

const string ModWorkFolder = IO::FromUserGameFolder("Skins/Stadium/ModWork/").Replace("\\", "/");

bool DoesModWorkFolderExist() {
    return IO::FolderExists(ModWorkFolder);
}

void RefreshSkinsUserMedia() {
    cast<CTrackMania>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.Media_RefreshFromDisk(CGameDataFileManagerScript::EMediaType::Skins, 4);
}
