namespace SkidsCache {
    const string MainDir = IO::FromUserGameFolder("Skins/Stadium/Skids/").Replace("\\", "/");
    const string IndexFile = MainDir + "index.txt";
    string[]@ skidsIndex = {};
    bool restartRequired = false;

    const string baseURL = "https://s3.us-east-1.wasabisys.com/xert/Skids/";
    const string indexURL = baseURL + "index.txt";
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
}
