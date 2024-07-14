const string PluginName = Meta::ExecutingPlugin().Name;
const string PluginIcon = Icons::Magic;
const string PluginColorString = "\\$a3f";
const string MenuTitle = PluginColorString + PluginIcon + "\\$z " + PluginName + " " + PluginColorString + PluginIcon;
const string WindowTitle = PluginColorString + PluginIcon + "\\$z " + PluginName + "  \\$888 by XertroV";


UI::Font@ g_MonoFont;
UI::Font@ g_BoldFont;
UI::Font@ g_BigFont;
UI::Font@ g_MidFont;
void LoadFonts() {
    @g_BoldFont = UI::LoadFont("DroidSans-Bold.ttf");
    @g_MonoFont = UI::LoadFont("DroidSansMono.ttf");
    @g_BigFont = UI::LoadFont("DroidSans.ttf", 26);
    @g_MidFont = UI::LoadFont("DroidSans.ttf", 20);
}

// show the window immediately upon installation
[Setting hidden]
bool ShowWindow = true;

/** Render function called every frame intended only for menu items in `UI`. */
void RenderMenu() {
    if (UI::MenuItem(MenuTitle, "", ShowWindow)) {
        ShowWindow = !ShowWindow;
    }
}

void RenderInterface() {
    if (!ShowWindow) return;
    UI::SetNextWindowSize(500, 300, UI::Cond::FirstUseEver);
    if (UI::Begin(WindowTitle, ShowWindow, UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize)) {
        DrawInterfaceInner();
    }
    UI::End();
}


[SettingsTab name="Skids" icon="Car"]
void R_S_MainInterfaceAsSettingsTab() {
    DrawInterfaceInner();
}


void DrawInterfaceInner() {
    if (SkidsCache::Loading || !SkidsCache::IsCached()) {
        DrawSetup_CacheSkids();
    } else {
        DrawMainTabs();
    }
}


void DrawSetup_CacheSkids() {
    UX::Heading("Setup: Cache Skid Marks");
    UI::TextWrapped("First, you need to cache the available skid marks.");
    UI::BeginDisabled(SkidsCache::Loading);
    if (UI::Button("Download Skids")) {
        startnew(SkidsCache::DownloadAllSkids);
    }
    UI::EndDisabled();
}

void DrawMainTabs() {
    UI::AlignTextToFramePadding();
    UI::TextWrapped("Choose your skidmarks: \\$888(compatible with mods)");
    DrawSkidsChoices();
    if (DoesModWorkFolderExist()) {
        UI::AlignTextToFramePadding();
        UI::TextWrapped("\\$f80ModWork folder detected!\\$z If your skids don't seem to work, try deleting the ModWork folder at Documents/Trackmania/Skins/Stadium/ModWork");
        if (UI::Button("Open ModWork Folder")) {
            OpenExplorerPath(IO::FromUserGameFolder("Skins/Stadium/ModWork/"));
        }
        UI::TextWrapped("\\$aaaNote: You must delete the entire ModWork folder, not just the contents! (to disable ModWork, that is)");
    } else {
        // UI::Dummy(vec2(10, 40));
    }
    UI::SeparatorText("\\$iWarning");
    UI::AlignTextToFramePadding();
    UI::Text("\\$f80Please do not update / uninstall this plugin outside the main menu!");
}

void DrawSkidsChoices() {
    if (ModFolders::skids.Length < 3) return;
    S_SkidsAsphaltPath = DrawSkidsCombo(ModFolders::skids[0], S_SkidsAsphaltPath);
    S_SkidsDirtPath = DrawSkidsCombo(ModFolders::skids[1], S_SkidsDirtPath);
    S_SkidsGrassPath = DrawSkidsCombo(ModFolders::skids[2], S_SkidsGrassPath);
    S_DisableAsphaltSmoke = UI::Checkbox("Disable Asphalt Smoke?", S_DisableAsphaltSmoke);
    S_DisableDirtSmoke = UI::Checkbox("Disable Dirt Smoke?", S_DisableDirtSmoke);
    S_DisableDirtMask = UI::Checkbox("Disable Dirt Mask?", S_DisableDirtMask);

    bool disableAll = !IsSafeToUpdateSkids() || Time::Now - lastSkidsAppliedTime < 1000;

    UI::BeginDisabled(disableAll);
    if (UI::Button("Apply Skids")) {
        startnew(ApplySkids);
    }
    UI::SameLine();
    UI::BeginDisabled(SkidsCache::Loading);
    if (UI::Button("Check for New Skids")) {
        startnew(SkidsCache::DownloadAllSkids);
    }
    UI::EndDisabled();
    UI::EndDisabled();

    UI::SetNextItemOpen(true, UI::Cond::FirstUseEver);
    if (UI::CollapsingHeader("Preview##skid-dds")) {
        UI::BeginTabBar("skids-tabs");

        if (UI::BeginTabItem("Asphalt")) {
            ModFolders::skids[0].DrawSkidsPreviewImage(S_SkidsAsphaltPath);
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Dirt")) {
            ModFolders::skids[1].DrawSkidsPreviewImage(S_SkidsDirtPath);
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Grass")) {
            ModFolders::skids[2].DrawSkidsPreviewImage(S_SkidsGrassPath);
            UI::EndTabItem();
        }

        UI::EndTabBar();
    }

    UI::SeparatorText("Status");

    if (!IsSafeToUpdateSkids()) {
        UI::AlignTextToFramePadding();
        UI::Text("Please go back to the main menu to update skids.");
    } else if (Time::Now - lastSkidsAppliedTime < 10000) {
        UI::AlignTextToFramePadding();
        UI::TextWrapped("Skids Updated. They will update in-game when the map changes or you re-enter the map.");
    } else {
        UI::AlignTextToFramePadding();
        UI::TextWrapped("\\$888...");
    }

    UI::SeparatorText("On-Disk");

    if (UI::Button("Refresh from Disk")) {
        startnew(ModFolders::Reload);
    }
    UI::SameLine();
    if (UI::Button(Icons::FolderO + " Browse")) {
        OpenExplorerPath(SkidsCache::MainDir);
    }
}

string DrawSkidsCombo(SkidmarkFiles@ skids, const string &in selected) {
    string ret = selected;
    int selectedIx = -1;
    bool isSelected;
    if (UI::BeginCombo("##cb."+skids.skidType, ret, UI::ComboFlags::HeightLarge)) {
        if (UI::Selectable("None##none", ret.Length == 0)) {
            UI::EndCombo();
            return "";
        }
        for (uint i = 0; i < skids.ddsFiles.Length; i++) {
            isSelected = ret == skids.ddsFiles[i];
            if (isSelected) selectedIx = i;
            if (UI::Selectable(skids.prettyNames[i], isSelected)) {
                ret = skids.ddsFiles[i];
                selectedIx = i;
            }
        }
        UI::EndCombo();
    } else {
        selectedIx = skids.ddsFiles.Find(ret);
    }
    UI::SameLine();
    if (UI::Button(Icons::ChevronLeft + "##prv."+skids.skidType)) {
        selectedIx = (selectedIx - 1 + skids.ddsFiles.Length) % skids.ddsFiles.Length;
    }
    UI::SameLine();
    if (UI::Button(Icons::ChevronRight + "##nxt."+skids.skidType)) {
        selectedIx = (selectedIx + 1) % skids.ddsFiles.Length;
    }
    UI::SameLine();
    UI::Text(skids.skidType);

    if (selectedIx >= 0) {
        ret = skids.ddsFiles[selectedIx];
    }
    return ret.Length == 0 ? selected : ret;
}

namespace UX {
    void Heading(const string &in msg) {
        UI::PushFont(g_BigFont);
        UI::Text(msg);
        UI::PopFont();
    }
}
