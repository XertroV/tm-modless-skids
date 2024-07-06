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
        // main setup flow
        if (SkidsCache::Loading || !SkidsCache::IsCached()) {
            DrawSetup_CacheSkids();
        } else {
            DrawMainTabs();
        }
    }
    UI::End();
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
    } else {
        UI::Dummy(vec2(10, 40));
    }
    UI::Separator();
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
    // todo: draw preview?

    UI::BeginDisabled(!IsSafeToUpdateSkids() || Time::Now - lastSkidsAppliedTime < 1000);
    if (UI::Button("Apply Skids")) {
        startnew(ApplySkids);
    }
    UI::SameLine();
    if (UI::Button("Refresh from Disk")) {
        startnew(ModFolders::Reload);
    }
    UI::SameLine();
    UI::BeginDisabled(SkidsCache::Loading);
    if (UI::Button("Check for New Skids")) {
        startnew(SkidsCache::DownloadAllSkids);
    }
    UI::EndDisabled();
    UI::EndDisabled();
    if (!IsSafeToUpdateSkids()) {
        UI::AlignTextToFramePadding();
        UI::Text("Please go back to the main menu to update skids.");
    } else if (Time::Now - lastSkidsAppliedTime < 10000) {
        UI::AlignTextToFramePadding();
        UI::TextWrapped("Skids Updated. They will update in-game when the map changes or you re-enter the map.");
    }
}

string DrawSkidsCombo(SkidmarkFiles@ skids, const string &in selected) {
    string ret = "";
    if (UI::BeginCombo(skids.skidType, selected, UI::ComboFlags::HeightLarge)) {
        if (UI::Selectable("None##none", selected.Length == 0)) {
            UI::EndCombo();
            return "";
        }
        for (uint i = 0; i < skids.ddsFiles.Length; i++) {
            if (UI::Selectable(skids.prettyNames[i], selected == skids.ddsFiles[i])) {
                ret = skids.ddsFiles[i];
            }
        }
        UI::EndCombo();
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
