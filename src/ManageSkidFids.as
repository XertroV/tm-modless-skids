dictionary origSkids;

// "Skins/Stadium/Skids/Asphalt/PurpleBorder.dds"

// "GameData/Stadium/Media/Texture CarFx/Image/CarAsphaltMarks.dds"
// "GameData/Stadium/Media/Texture CarFx/Image/CarDirtMarks.dds"
// "GameData/Stadium/Media/Texture CarFx/Image/CarGrassMarks.dds"
// "GameData/Vehicles/Media/Texture/Image/AsphaltMarks.dds"
// "GameData/Vehicles/Media/Texture/Image/IceMarks_A.dds"
// "GameData/Vehicles/Media/Texture/Image/SandMarks.dds" -- same size as asphalt/dirt
// "GameData/Vehicles/Media/Texture/Image/SnowMarks.dds" -- same size as asphalt/dirt
// "GameData/Vehicles/Media/Texture/Image/WetWheelsMarks.dds" -- same size as asphalt/dirt

// "GameData/Stadium/Media/Texture CarFx/Image/CarDirtSmoke.dds"
// "GameData/Vehicles/Media/Texture/Image/AsphaltSmoke.dds"
// "GameData/Vehicles/Media/Texture/Image/DirtSmoke.dds"
// "GameData/Vehicles/Media/Texture/Image/DirtSmokeHovering.dds"
// "GameData/Vehicles/Media/Texture/Image/SandSmoke.dds"
// "GameData/Vehicles/Media/Texture/Image/SnowSmoke.dds"

enum SkidType {
    Asphalt, Dirt, Grass, Sand, Snow, WetWheels, Ice,
    Unknown
}

void SetSkids(const string &in loadPath, SkidType type) {
    string fidPath = type == SkidType::Asphalt ? "GameData/Stadium/Media/Texture CarFx/Image/CarAsphaltMarks.dds"
        : type == SkidType::Dirt ? "GameData/Stadium/Media/Texture CarFx/Image/CarDirtMarks.dds"
        : type == SkidType::Grass ? "GameData/Stadium/Media/Texture CarFx/Image/CarGrassMarks.dds"
        : ""
        ;
    if (fidPath.Length == 0) {
        throw("unknown skid type: " + tostring(type));
    }
    SetTextureSkids(loadPath, fidPath);
}

void SetTextureSkids(const string &in loadPath, const string &in gameFidPathToReplace) {
    auto gbSkid = Fids::GetUser(loadPath);
    // auto gbSkid = Fids::GetUser("Skins/Stadium/Skids/Asphalt/BlackBorder.dds");
    if (gbSkid is null || gbSkid.ByteSize == 0) {
        NotifyError("Could not load skids .dds file from: " + loadPath);
        return;
    }

    if (gbSkid.Nod is null) {
        Fids::Preload(gbSkid);
        gbSkid.Nod.MwAddRef();
    }

    auto skidsGameFid = Fids::GetGame(gameFidPathToReplace);

    if (skidsGameFid.Nod is null) {
        Fids::Preload(skidsGameFid);
        skidsGameFid.Nod.MwAddRef();
    }

    if (!origSkids.Exists(gameFidPathToReplace)) {
        @origSkids[gameFidPathToReplace] = cast<CPlugFileDds>(skidsGameFid.Nod);
    }

    SetFidNod(skidsGameFid, gbSkid.Nod);
    dev_log("set " + gameFidPathToReplace + " to " + loadPath);
}

void SetFidNod(CSystemFidFile@ fid, CMwNod@ nod) {
    Dev::SetOffset(fid, GetOffset(fid, "Nod"), nod);
}


void RestoreOriginalSkids() {
    auto fidPaths = origSkids.GetKeys();
    for (uint i = 0; i < fidPaths.Length; i++) {
        auto fidPath = fidPaths[i];
        CMwNod@ nod = cast<CMwNod>(origSkids[fidPath]);
        auto fid = Fids::GetGame(fidPath);
        SetFidNod(fid, nod);
        dev_log("reset " + fidPath + " to original");
    }
    origSkids.DeleteAll();
}


void ApplySkids() {
    Fids::UpdateTree(Fids::GetUserFolder("Skins/Stadium/Skids"));
    // restore original so we unset stuff if the player unsets them
    RestoreOriginalSkids();
    if (S_SkidsAsphaltPath.Length > 0) ModFolders::skids[0].Apply(S_SkidsAsphaltPath);
    if (S_SkidsDirtPath.Length > 0) ModFolders::skids[1].Apply(S_SkidsDirtPath);
    if (S_SkidsGrassPath.Length > 0) ModFolders::skids[2].Apply(S_SkidsGrassPath);
    bool anySkids = S_SkidsAsphaltPath.Length > 0 || S_SkidsDirtPath.Length > 0 || S_SkidsGrassPath.Length > 0;
    if (anySkids) {
        Notify("Updated Skidmarks. They will be visible when the map changes or you re-enter the map.");
        lastSkidsAppliedTime = Time::Now;
        Meta::SaveSettings();
    }
}


uint lastSkidsAppliedTime;


void dev_log(const string &in msg) {
#if DEV
    print("[DEV] " + msg);
#endif
}
