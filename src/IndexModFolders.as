namespace ModFolders {
    // relative to Skins/Stadium
    // ModSourceFolder@[] folders;
    SkidmarkFiles@[] skids;

    void Load() {
        LoadSkids();
    }

    void LoadSkids() {
        skids.RemoveRange(0, skids.Length);
        skids.InsertLast(SkidmarkFiles(SkidsCache::MainDir + SkidsCache::skidFolders[0]));
        skids.InsertLast(SkidmarkFiles(SkidsCache::MainDir + SkidsCache::skidFolders[1]));
        skids.InsertLast(SkidmarkFiles(SkidsCache::MainDir + SkidsCache::skidFolders[2]));
        skids.InsertLast(SkidmarkFiles(SkidsCache::MainDir + SkidsCache::skidFolders[3]));
    }

    void Reload() {
        Load();
        Notify("Reloaded skids");
    }
}

class ModSourceFolder {
    string path;
    string modName;
    ModSourceFolder(const string &in path) {
        this.path = path.Replace("\\", "/");
        auto parts = this.path.Split("/");
        while (parts[parts.Length - 1] == "") parts.RemoveLast();
        modName = parts[parts.Length - 1];
    }

    string ToString() {
        return modName;
    }

    bool IsSelected(const string &in selectedPath) {
        return path == selectedPath;
    }

    void DrawItem() {
        if (UI::TreeNode(ToString(), UI::TreeNodeFlags::None)) {
            if (UI::Button("Open##"+path)) OpenExplorerPath(path);
            // UI::TextWrapped("todo mod source folder draw item");
            UI::TreePop();
        }
    }
}

class SkidmarkFiles : ModSourceFolder {
    string skidType;
    string[] ddsFiles, prettyNames;

    SkidmarkFiles(const string &in path) {
        super(path);
        auto parts = this.path.Split("/");
        if (parts.Length < 2) throw("Invalid skids path: " + this.path);
        if (parts[parts.Length - 1].Length == 0) parts.RemoveLast();
        // ddsName = parts[parts.Length - 1];
        // prettyName = ddsName.ToLower().EndsWith(".dds") ? ddsName.SubStr(0, ddsName.Length - 4) : ddsName;
        skidType = parts[parts.Length - 1];

        auto files = IO::IndexFolder(this.path, true);
        for (uint i = 0; i < files.Length; i++) {
            auto lower = files[i].ToLower();
            if (lower.EndsWith(".dds") && !lower.EndsWith("smoke.dds")) {
                auto relPath = files[i].Replace(this.path, "");
                while (relPath.StartsWith("/")) relPath = relPath.SubStr(1);
                ddsFiles.InsertLast(relPath);
                prettyNames.InsertLast(relPath.SubStr(0, relPath.Length - 4));
            }
        }
    }

    string ToString() override {
        return skidType + " Skids";
    }

    void Apply(const string &in skidPath) {
        auto source = "Skins/Stadium/Skids/" + skidType + "/" + skidPath;
        auto dest = skidType == "Asphalt" ? SkidType::Asphalt
            : skidType == "Dirt" ? SkidType::Dirt
            : skidType == "Grass" ? SkidType::Grass
            : skidType == "DirtSmoke" ? SkidType::DirtSmoke
            : skidType == "AsphaltSmoke" ? SkidType::AsphaltSmoke
            : SkidType::Unknown;
        SetSkids(source, dest);
    }

    void DrawSkidsPreviewImage(const string &in skidPath) {
        auto pos = UI::GetCursorPos();
        // UI::Dummy(previewSize * vec2(2., 1.));
        UI::SetCursorPos(pos);
        if (skidPath.Length == 0) {
            UI::TextWrapped("No skid selected");
            return;
        }
        auto source = IO::FromUserGameFolder("Skins/Stadium/Skids/" + skidType + "/" + skidPath);
        if (!IO::FileExists(source)) {
            UI::TextWrapped("Missing: " + source);
            return;
        }
        auto @texHandle = textureManager.RequestTexture(source, previewSize.x, previewSize.y);
        if (texHandle is null || texHandle.Texture is null) {
            UI::TextWrapped("Loading... (or error)");
            UI::TextWrapped("Last texture load error: " + IMG::_lastTextureLoadError);
            return;
        }
        UI::Image(texHandle.Texture, previewSize);
        UI::SameLine();
        pos = UI::GetCursorPos();
        auto dl = UI::GetWindowDrawList();
        dl.AddRectFilled(vec4(UI::GetWindowPos() + pos, previewSize), vec4(.5, .5, .5, 1.));
        UI::Image(texHandle.Texture, previewSize);
        UI::SameLine();
        pos = UI::GetCursorPos();
        dl.AddRectFilled(vec4(UI::GetWindowPos() + pos, previewSize), vec4(1.));
        UI::Image(texHandle.Texture, previewSize);
    }

    // void ApplySmoke() {
    //     auto source = "Skins/Stadium/Skids/" + skidType + "/" + "DirtSmoke.dds";
    // }
}

const vec2 previewSize = vec2(256, 256);

IMG::TextureManager textureManager = IMG::TextureManager();
