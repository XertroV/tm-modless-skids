namespace SkidsCache {
    const string MainDir = IO::FromUserGameFolder("Skins/Stadium/Skids/").Replace("\\", "/");
    const string IndexFile_v1 = MainDir + "index.txt";
    const string IndexFile = MainDir + "index_v2.txt";
    string[]@ skidsIndex = {};
    bool restartRequired = false;

    // const string baseURL = "https://s3.us-east-1.wasabisys.com/xert/Skids/";
    const string baseURL = "https://assets.xk.io/Skids/";
    const string indexURL = baseURL + "index_v2.txt";
    const string[] skidFolders = {"Asphalt", "Dirt", "Grass", "Other"};

    void SoftInit() {
        _skidsCached = IsCached();
    }

    bool _skidsCached = IO::FolderExists(MainDir);
    int _skidsCachedLastCheck = -1000;
    bool IsCached() {
        if (_skidsCached) return true;
        if (Loading) return false;
        if (Time::Now - _skidsCachedLastCheck >= 1000) {
            _skidsCached = IO::FolderExists(MainDir);
        }
        return _skidsCached;
    }

    bool isSilentUpdate = false;
    bool isDownloadingSkids = false;
    bool get_Loading() {
        return isDownloadingSkids;
    }

    // mostly for coros
    void DownloadAllSkids() {
        DownloadAllSkids(false);
    }

    void DownloadAllSkids(bool silentUpdate) {
        // IO::DeleteFolder(MainDir, true);
        isSilentUpdate = silentUpdate;
        isDownloadingSkids = true;
        @skidsIndex = UpdateIndexFile();
        yield();
        DownloadAllMissing(skidsIndex);
        isDownloadingSkids = false;
    }

    string[]@ UpdateIndexFile() {
        ExtractProgress::Add(1, "Update Skids");
        auto req = Net::HttpGet(indexURL);
        while (!req.Finished()) yield();
        if (req.ResponseCode() != 200) {
            auto msg = "Failed to download skids index file. " + req.ResponseCode() + ", " + req.String();
            NotifyError(msg);
            isDownloadingSkids = false;
            ExtractProgress::Error(msg);
            throw("Error downloading index file!");
        }
        ExtractProgress::Done();
        // if (!IO::FolderExists(MainDir)) {
        //     restartRequired = true;
        // }
        IO::CreateFolder(MainDir);
        for (int i = 0; i < skidFolders.Length; i++) {
            IO::CreateFolder(MainDir + skidFolders[i]);
        }

        auto resp = req.String();
        auto lines = resp.Split("\n");
        IO::File ixf(IndexFile, IO::FileMode::Write);
        ixf.Write(resp);
        trace('updated index file at: ' + IndexFile);
        ixf.Close();
        return lines;
    }

    void DownloadAllMissing(string[]@ files) {
        ExtractProgress::Add(files.Length);
        Meta::PluginCoroutine@[] coros;
        for (uint i = 0; i < files.Length; i++) {
            if (files[i].Length == 0) {
                ExtractProgress::SubOne();
                continue;
            }
            auto path = MainDir + files[i];
            if (!IO::FileExists(path)) {
                trace("Missing: " + path);
                coros.InsertLast(startnew(DownloadSkids, files[i]));
            } else {
                ExtractProgress::Done();
            }
            yield();
        }
        await(coros);
        startnew(RefreshSkinsUserMedia);
        startnew(ModFolders::Reload);
    }

    void DownloadSkids(const string &in skidPath) {
        try {
            string url = baseURL + skidPath;
            auto req = Net::HttpGet(url);
            while (!req.Finished()) yield();
            if (req.ResponseCode() != 200) {
                auto msg = "Failed to download skids file. " + url + " / " + req.ResponseCode() + ", " + req.String();
                NotifyError(msg);
                throw("Error downloading skid file! " + url);
            }
            IO::File skid(MainDir + skidPath, IO::FileMode::Write);
            skid.Write(req.Buffer());
            ExtractProgress::Done();
        } catch {
            ExtractProgress::Error(getExceptionInfo());
        }
    }

    void CheckUpdateSkidsVersions() {
        // check for version updates going from most recent version to least

        // v1 -> v2
        // we are on v1 if index.txt exists but v2 doesn't
        bool v1IndexExists = IO::FileExists(IndexFile_v1);
        bool v2IndexExists = IO::FileExists(IndexFile);

        if (v1IndexExists && !v2IndexExists) {
            RunUpdateSkids_V1_to_V2();
            return;
        }
    }


    void RunUpdateSkids_V1_to_V2() {
        print("Updating skids on disk from v1 to v2");
        string[] toDel = {
            "Blue_Thick.dds",
            "Green_Thick.dds",
            "Orange_Thick.dds",
            "Pink_Thick.dds",
            "Purple_Thick.dds",
            "Red_Thick.dds",
            "That_Ski_Freak_V1.dds",
            "That_Ski_Freak_V2.dds",
            "That_Ski_Freak_V3.dds",
            "ChromaGreen.dds",
            "EvoBorder.dds"
        };
        string[] types = {'Asphalt', 'Dirt', 'Grass'};
        for (uint i = 0; i < types.Length; i++) {
            for (uint j = 0; j < toDel.Length; j++) {
                string path = MainDir + types[i] + '/' + toDel[j];
                if (!IO::FileExists(path)) {
                    trace("Missing: " + path);
                    continue;
                }
                IO::Delete(path);
                trace("Deleted: " + path);
            }
        }
        print("Done updating skids on disk from v1 to v2 (deletes some skids we want to replace)");
    }
}
