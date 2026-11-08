sub initMoviesModule()
    m.addonBaseUrl = "https://roku-backend-iptv.vercel.app/api/addons"
    m.moviesGroup = m.top.findNode("moviesGroup")
    m.moviesTitleLabel = m.top.findNode("moviesTitleLabel")
    m.movieCatalogHeadingLabel = m.top.findNode("movieCatalogHeadingLabel")
    m.movieCatalogGroup = m.top.findNode("movieCatalogGroup")
    m.movieGridGroup = m.top.findNode("movieGridGroup")
    m.movieStatusLabel = m.top.findNode("movieStatusLabel")
    m.movieInstallHintLabel = m.top.findNode("movieInstallHintLabel")
    m.moviePageLabel = m.top.findNode("moviePageLabel")
    m.movieDetailGroup = m.top.findNode("movieDetailGroup")
    m.movieDetailBackdrop = m.top.findNode("movieDetailBackdrop")
    m.movieDetailPoster = m.top.findNode("movieDetailPoster")
    m.movieDetailTitle = m.top.findNode("movieDetailTitle")
    m.movieDetailMeta = m.top.findNode("movieDetailMeta")
    m.movieDetailDescription = m.top.findNode("movieDetailDescription")
    m.moviePlayBg = m.top.findNode("moviePlayBg")
    m.moviePlayLabel = m.top.findNode("moviePlayLabel")
    m.movieDetailHintLabel = m.top.findNode("movieDetailHintLabel")
    m.movieDetailStatusLabel = m.top.findNode("movieDetailStatusLabel")
    m.movieCatalogs = []
    m.movieItems = []
    m.movieCatalogNodes = []
    m.movieCardNodes = []
    m.movieCatalogIndex = 0
    m.movieItemIndex = 0
    m.movieTop = 0
    m.movieColumns = 4
    m.movieVisibleCards = 8
    m.movieFocusArea = "catalogs"
    m.movieMode = "idle"
    m.currentMovieCatalog = invalid
    m.currentMovieMeta = invalid
    m.movieDirectAddons = []
    m.movieDirectAddonIndex = 0
    m.movieCurrentDirectAddon = invalid
end sub

sub buildMovieUi()
    m.movieCatalogNodes = []
    if m.movieCatalogGroup <> invalid
        for i = 0 to 6
            g = m.movieCatalogGroup.createChild("Group")
            g.translation = [0, i * 58]
            border = g.createChild("Rectangle")
            border.width = 247
            border.height = 50
            border.color = "0xFFFFFF18"
            bg = g.createChild("Rectangle")
            bg.translation = [1, 1]
            bg.width = 245
            bg.height = 48
            bg.color = "0x0F1624FF"
            label = g.createChild("Label")
            label.translation = [16, 10]
            label.width = 215
            label.height = 28
            label.text = ""
            label.color = "0xE2E8F0FF"
            label.font = "font:SmallBoldSystemFont"
            m.movieCatalogNodes.push({group:g, border:border, bg:bg, label:label})
        end for
    end if
    m.movieCardNodes = []
    if m.movieGridGroup <> invalid
        for i = 0 to 7
            col = i mod 4
            row = Int(i / 4)
            g = m.movieGridGroup.createChild("Group")
            g.translation = [col * 205, row * 238]
            border = g.createChild("Rectangle")
            border.width = 186
            border.height = 224
            border.color = "0xFFFFFF18"
            bg = g.createChild("Rectangle")
            bg.translation = [1, 1]
            bg.width = 184
            bg.height = 222
            bg.color = "0x0F1624FF"
            poster = g.createChild("Poster")
            poster.translation = [8, 8]
            poster.width = 170
            poster.height = 170
            poster.uri = "pkg:/images/movies_safe.png"
            poster.loadDisplayMode = "scaleToFill"
            label = g.createChild("Label")
            label.translation = [9, 184]
            label.width = 168
            label.height = 31
            label.text = ""
            label.color = "0xF8FAFCFF"
            label.font = "font:SmallBoldSystemFont"
            label.horizAlign = "center"
            m.movieCardNodes.push({group:g, border:border, bg:bg, poster:poster, label:label})
        end for
    end if
end sub

sub applyMovieLanguage()
    if m.moviesTitleLabel <> invalid then m.moviesTitleLabel.text = auraText("movies")
    if m.movieCatalogHeadingLabel <> invalid then m.movieCatalogHeadingLabel.text = auraText("movie_catalogs")
    if m.movieInstallHintLabel <> invalid then m.movieInstallHintLabel.text = auraText("movie_install_hint")
    if m.moviePlayLabel <> invalid then m.moviePlayLabel.text = auraText("movie_play")
    if m.movieDetailHintLabel <> invalid then m.movieDetailHintLabel.text = auraText("movie_detail_hint")
end sub

sub openMovies()
    m.appState = "movies"
    m.movieMode = "loading"
    m.movieFocusArea = "catalogs"
    m.movieCatalogIndex = 0
    m.movieItemIndex = 0
    m.movieTop = 0
    m.movieCatalogs = []
    m.movieItems = []
    m.currentMovieCatalog = invalid
    m.currentMovieMeta = invalid
    if m.movieStatusLabel <> invalid then m.movieStatusLabel.text = auraText("movie_loading")
    if m.movieDetailStatusLabel <> invalid then m.movieDetailStatusLabel.text = ""
    updateAllUi()
    requestMovieAddons()
end sub

sub requestMovieAddons()
    m.apiTask = CreateObject("roSGNode", "BackendTask")
    url = m.addonBaseUrl + "?action=list&mac=" + m.deviceMac + "&key=" + m.deviceKey
    m.apiTask.request = {url:url, method:"GET", action:"movie_addons", insecure:false}
    m.apiTask.observeField("response", "onApiResponse")
    m.apiTask.control = "RUN"
end sub

sub finishMovieAddonDiscovery()
    if m.movieCatalogs.count() = 0
        m.movieMode = "grid"
        if m.movieStatusLabel <> invalid then m.movieStatusLabel.text = auraText("movie_no_addons")
        updateMoviesUi()
    else
        m.movieCatalogIndex = 0
        m.movieFocusArea = "catalogs"
        requestMovieCatalog(0)
    end if
end sub

sub requestNextMovieDirectManifest()
    if m.movieDirectAddonIndex >= m.movieDirectAddons.count()
        finishMovieAddonDiscovery()
        return
    end if

    addon = m.movieDirectAddons[m.movieDirectAddonIndex]
    m.movieCurrentDirectAddon = addon

    m.apiTask = CreateObject("roSGNode", "BackendTask")
    m.apiTask.request = {
        url:addon.manifestUrl,
        method:"GET",
        action:"movie_direct_manifest",
        insecure:false,
        userAgent:"AuraTV/1.0 Roku",
        accept:"application/json, text/json;q=0.9, */*;q=0.2"
    }
    m.apiTask.observeField("response", "onApiResponse")
    m.apiTask.control = "RUN"
end sub

sub handleMovieDirectManifest(res as Object)
    addon = m.movieCurrentDirectAddon

    if addon <> invalid and not res.DoesExist("error") and res.data <> invalid
        manifest = res.data

        addonName = "Direct Add-on"
        if manifest.DoesExist("name") and manifest.name <> "" then addonName = manifest.name

        baseUrl = addonBaseFromManifestUrl(addon.manifestUrl)

        if manifest.DoesExist("catalogs")
            for each cat in manifest.catalogs
                if cat <> invalid and cat.DoesExist("type") and cat.type = "movie"
                    catId = ""
                    catName = "Movies"

                    if cat.DoesExist("id") then catId = cat.id
                    if cat.DoesExist("name") and cat.name <> "" then catName = cat.name

                    if catId <> ""
                        m.movieCatalogs.push({
                            addonId:addon.id,
                            addonName:addonName,
                            catalogId:catId,
                            catalogName:catName,
                            mode:"direct",
                            baseUrl:baseUrl
                        })
                    end if
                end if
            end for
        end if
    end if

    m.movieDirectAddonIndex = m.movieDirectAddonIndex + 1

    if m.movieDirectAddonIndex < m.movieDirectAddons.count()
        requestNextMovieDirectManifest()
    else
        finishMovieAddonDiscovery()
    end if
end sub

function addonBaseFromManifestUrl(manifestUrl as String) as String
    base = manifestUrl
    q = Instr(0, base, "?")
    if q >= 0 then base = Left(base, q)

    lower = LCase(base)
    marker = "/manifest.json"
    p = Instr(0, lower, marker)

    if p >= 0 then base = Left(base, p)

    while Len(base) > 0 and Right(base, 1) = "/"
        base = Left(base, Len(base) - 1)
    end while

    return base
end function

function addonPathPart(value as Dynamic) as String
    if value = invalid then return ""
    return value.toStr().EncodeUriComponent()
end function

sub requestMovieCatalog(index as Integer)
    if index < 0 or index >= m.movieCatalogs.count() then return
    m.movieCatalogIndex = index
    m.currentMovieCatalog = m.movieCatalogs[index]
    m.movieMode = "loading"
    if m.movieStatusLabel <> invalid then m.movieStatusLabel.text = auraText("movie_loading")
    updateMoviesUi()
    c = m.currentMovieCatalog

    if c.DoesExist("mode") and c.mode = "direct"
        url = c.baseUrl + "/catalog/movie/" + addonPathPart(c.catalogId) + ".json"
        m.apiTask = CreateObject("roSGNode", "BackendTask")
        m.apiTask.request = {
            url:url,
            method:"GET",
            action:"movie_direct_catalog",
            insecure:false,
            userAgent:"AuraTV/1.0 Roku",
            accept:"application/json, text/json;q=0.9, */*;q=0.2"
        }
    else
        url = m.addonBaseUrl + "?action=catalog&mac=" + m.deviceMac + "&key=" + m.deviceKey
        url = url + "&addonId=" + c.addonId + "&type=movie&catalogId=" + c.catalogId
        m.apiTask = CreateObject("roSGNode", "BackendTask")
        m.apiTask.request = {url:url, method:"GET", action:"movie_catalog", insecure:false}
    end if
    m.apiTask.observeField("response", "onApiResponse")
    m.apiTask.control = "RUN"
end sub

sub requestMovieMeta()
    if m.movieItemIndex < 0 or m.movieItemIndex >= m.movieItems.count() then return
    if m.currentMovieCatalog = invalid then return
    item = m.movieItems[m.movieItemIndex]
    if item = invalid or not item.DoesExist("id") then return
    m.movieMode = "loading_detail"
    if m.movieStatusLabel <> invalid then m.movieStatusLabel.text = auraText("movie_loading_detail")
    updateMoviesUi()
    c = m.currentMovieCatalog

    if c.DoesExist("mode") and c.mode = "direct"
        url = c.baseUrl + "/meta/movie/" + addonPathPart(item.id) + ".json"
        m.apiTask = CreateObject("roSGNode", "BackendTask")
        m.apiTask.request = {
            url:url,
            method:"GET",
            action:"movie_direct_meta",
            insecure:false,
            userAgent:"AuraTV/1.0 Roku",
            accept:"application/json, text/json;q=0.9, */*;q=0.2"
        }
    else
        url = m.addonBaseUrl + "?action=meta&mac=" + m.deviceMac + "&key=" + m.deviceKey
        url = url + "&addonId=" + c.addonId + "&type=movie&id=" + item.id
        m.apiTask = CreateObject("roSGNode", "BackendTask")
        m.apiTask.request = {url:url, method:"GET", action:"movie_meta", insecure:false}
    end if
    m.apiTask.observeField("response", "onApiResponse")
    m.apiTask.control = "RUN"
end sub

sub requestMovieStream()
    if m.currentMovieMeta = invalid then return
    if m.currentMovieCatalog = invalid then return
    if not m.currentMovieMeta.DoesExist("id") then return
    if m.movieDetailStatusLabel <> invalid then m.movieDetailStatusLabel.text = auraText("movie_loading_stream")
    c = m.currentMovieCatalog

    if c.DoesExist("mode") and c.mode = "direct"
        url = c.baseUrl + "/stream/movie/" + addonPathPart(m.currentMovieMeta.id) + ".json"
        m.apiTask = CreateObject("roSGNode", "BackendTask")
        m.apiTask.request = {
            url:url,
            method:"GET",
            action:"movie_direct_streams",
            insecure:false,
            userAgent:"AuraTV/1.0 Roku",
            accept:"application/json, text/json;q=0.9, */*;q=0.2"
        }
    else
        url = m.addonBaseUrl + "?action=streams&mac=" + m.deviceMac + "&key=" + m.deviceKey
        url = url + "&addonId=" + c.addonId + "&type=movie&id=" + m.currentMovieMeta.id
        m.apiTask = CreateObject("roSGNode", "BackendTask")
        m.apiTask.request = {url:url, method:"GET", action:"movie_streams", insecure:false}
    end if
    m.apiTask.observeField("response", "onApiResponse")
    m.apiTask.control = "RUN"
end sub

sub handleMovieApiResponse(res as Object)
    if res = invalid then return

    if res.action = "movie_direct_manifest"
        handleMovieDirectManifest(res)
        return
    end if

    if res.action = "movie_direct_catalog"
        res.action = "movie_catalog"
    else if res.action = "movie_direct_meta"
        res.action = "movie_meta"
    else if res.action = "movie_direct_streams"
        res.action = "movie_streams"
    end if
    if res.action = "movie_addons"
        m.movieCatalogs = []
        if res.DoesExist("error")
            m.movieMode = "grid"
            if m.movieStatusLabel <> invalid then m.movieStatusLabel.text = auraText("sync_error")
            updateMoviesUi()
            return
        end if
        if res.data <> invalid and res.data.DoesExist("addons")
            for each addon in res.data.addons
                addonId = ""
                addonName = "Add-on"
                if addon.DoesExist("id") then addonId = addon.id
                if addon.DoesExist("name") then addonName = addon.name
                if addon.DoesExist("catalogs")
                    for each cat in addon.catalogs
                        if cat <> invalid and cat.DoesExist("type") and cat.type = "movie"
                            catId = ""
                            catName = "Movies"
                            if cat.DoesExist("id") then catId = cat.id
                            if cat.DoesExist("name") and cat.name <> "" then catName = cat.name
                            if addonId <> "" and catId <> ""
                                m.movieCatalogs.push({addonId:addonId, addonName:addonName, catalogId:catId, catalogName:catName})
                            end if
                        end if
                    end for
                end if
            end for
        end if
        m.movieDirectAddons = []
        m.movieDirectAddonIndex = 0

        if res.data <> invalid and res.data.DoesExist("addons")
            for each addon in res.data.addons
                if addon <> invalid and addon.DoesExist("mode")
                    if addon.mode = "direct" and addon.DoesExist("manifestUrl") and addon.manifestUrl <> ""
                        m.movieDirectAddons.push(addon)
                    end if
                end if
            end for
        end if

        if m.movieDirectAddons.count() > 0
            if m.movieStatusLabel <> invalid then m.movieStatusLabel.text = auraText("movie_direct_loading")
            requestNextMovieDirectManifest()
        else
            finishMovieAddonDiscovery()
        end if
        return
    end if
    if res.action = "movie_catalog"
        m.movieItems = []
        m.movieItemIndex = 0
        m.movieTop = 0
        m.movieMode = "grid"
        if res.DoesExist("error")
            if m.movieStatusLabel <> invalid then m.movieStatusLabel.text = auraText("sync_error")
            updateMoviesUi()
            return
        end if
        if res.data <> invalid and res.data.DoesExist("metas")
            for each meta in res.data.metas
                if meta <> invalid then m.movieItems.push(meta)
            end for
        end if
        if m.movieItems.count() = 0
            if m.movieStatusLabel <> invalid then m.movieStatusLabel.text = auraText("movie_no_items")
        else
            if m.currentMovieCatalog <> invalid and m.movieStatusLabel <> invalid
                m.movieStatusLabel.text = m.currentMovieCatalog.addonName + "  ·  " + m.currentMovieCatalog.catalogName
            end if
            m.movieFocusArea = "grid"
        end if
        updateMoviesUi()
        return
    end if
    if res.action = "movie_meta"
        if res.DoesExist("error")
            m.movieMode = "grid"
            if m.movieStatusLabel <> invalid then m.movieStatusLabel.text = auraText("sync_error")
            updateMoviesUi()
            return
        end if
        if res.data <> invalid and res.data.DoesExist("meta")
            m.currentMovieMeta = res.data.meta
            m.movieMode = "detail"
            renderMovieDetail()
            updateMoviesUi()
        else
            m.movieMode = "grid"
            updateMoviesUi()
        end if
        return
    end if
    if res.action = "movie_streams"
        playableUrl = ""
        if not res.DoesExist("error") and res.data <> invalid and res.data.DoesExist("streams")
            for each stream in res.data.streams
                if playableUrl = "" and stream <> invalid
                    canPlay = false

                    if stream.DoesExist("playable")
                        canPlay = stream.playable
                    else if stream.DoesExist("url") and stream.url <> ""
                        lowerUrl = LCase(stream.url)
                        if Left(lowerUrl, 7) = "http://" or Left(lowerUrl, 8) = "https://"
                            canPlay = true
                        end if
                    end if

                    if canPlay and stream.DoesExist("url") and stream.url <> ""
                        playableUrl = stream.url
                    end if
                end if
            end for
        end if
        if playableUrl = ""
            if m.movieDetailStatusLabel <> invalid then m.movieDetailStatusLabel.text = auraText("movie_no_stream")
        else
            movieName = "Movie"
            if m.currentMovieMeta <> invalid and m.currentMovieMeta.DoesExist("name") then movieName = m.currentMovieMeta.name
            movieItem = {num:0, name:movieName, url:playableUrl}
            openPlayerPreview(movieItem)
            openPlayerFull()
        end if
        return
    end if
end sub

sub updateMoviesUi()
    if m.moviesGroup = invalid or m.appState <> "movies" then return
    applyMovieLanguage()
    if m.movieDetailGroup <> invalid then m.movieDetailGroup.visible = (m.movieMode = "detail")
    catalogTop = 0
    if m.movieCatalogIndex > 6 then catalogTop = m.movieCatalogIndex - 6
    for i = 0 to m.movieCatalogNodes.count() - 1
        node = m.movieCatalogNodes[i]
        idx = catalogTop + i
        if idx < m.movieCatalogs.count()
            node.group.visible = true
            item = m.movieCatalogs[idx]
            node.label.text = item.catalogName
            if m.movieFocusArea = "catalogs" and idx = m.movieCatalogIndex and m.movieMode <> "detail"
                if node.border <> invalid then node.border.color = "0x38BDF8FF"
                node.bg.color = "0xFFFFFFFF"
                node.label.color = "0x090D16FF"
            else
                if node.border <> invalid then node.border.color = "0xFFFFFF18"
                node.bg.color = "0x0F1624FF"
                node.label.color = "0xE2E8F0FF"
            end if
        else
            node.group.visible = false
        end if
    end for
    if m.movieItemIndex < m.movieTop then m.movieTop = m.movieItemIndex
    if m.movieItemIndex >= m.movieTop + m.movieVisibleCards then m.movieTop = m.movieItemIndex - m.movieVisibleCards + 1
    if m.movieTop < 0 then m.movieTop = 0
    for i = 0 to m.movieCardNodes.count() - 1
        node = m.movieCardNodes[i]
        idx = m.movieTop + i
        if idx < m.movieItems.count()
            node.group.visible = true
            item = m.movieItems[idx]
            movieName = "Movie"
            if item.DoesExist("name") and item.name <> "" then movieName = item.name
            node.label.text = movieName
            posterUrl = "pkg:/images/movies_safe.png"
            if item.DoesExist("poster") and item.poster <> "" then posterUrl = item.poster
            node.poster.uri = posterUrl
            if m.movieFocusArea = "grid" and idx = m.movieItemIndex and m.movieMode <> "detail"
                if node.border <> invalid then node.border.color = "0x38BDF8FF"
                node.bg.color = "0xFFFFFFFF"
                node.label.color = "0x090D16FF"
            else
                if node.border <> invalid then node.border.color = "0xFFFFFF18"
                node.bg.color = "0x0F1624FF"
                node.label.color = "0xF8FAFCFF"
            end if
        else
            node.group.visible = false
        end if
    end for
    if m.moviePageLabel <> invalid
        if m.movieItems.count() > 0
            m.moviePageLabel.text = (m.movieItemIndex + 1).toStr() + " / " + m.movieItems.count().toStr()
        else
            m.moviePageLabel.text = ""
        end if
    end if
end sub

sub renderMovieDetail()
    if m.currentMovieMeta = invalid then return
    meta = m.currentMovieMeta
    movieName = ""
    if meta.DoesExist("name") then movieName = meta.name
    if m.movieDetailTitle <> invalid then m.movieDetailTitle.text = movieName
    posterUrl = "pkg:/images/movies_safe.png"
    if meta.DoesExist("poster") and meta.poster <> "" then posterUrl = meta.poster
    if m.movieDetailPoster <> invalid then m.movieDetailPoster.uri = posterUrl
    if m.movieDetailBackdrop <> invalid
        if meta.DoesExist("background") and meta.background <> ""
            m.movieDetailBackdrop.uri = meta.background
        else
            m.movieDetailBackdrop.uri = ""
        end if
    end if
    description = ""
    if meta.DoesExist("description") then description = meta.description
    if description = "" then description = movieName
    if m.movieDetailDescription <> invalid then m.movieDetailDescription.text = description
    metaLine = ""
    if meta.DoesExist("releaseInfo") and meta.releaseInfo <> "" then metaLine = meta.releaseInfo
    if meta.DoesExist("runtime") and meta.runtime <> ""
        if metaLine <> "" then metaLine = metaLine + "  ·  "
        metaLine = metaLine + meta.runtime
    end if
    if meta.DoesExist("imdbRating") and meta.imdbRating <> ""
        if metaLine <> "" then metaLine = metaLine + "  ·  "
        metaLine = metaLine + "IMDb " + meta.imdbRating
    end if
    if m.movieDetailMeta <> invalid then m.movieDetailMeta.text = metaLine
    if m.movieDetailStatusLabel <> invalid then m.movieDetailStatusLabel.text = ""
end sub

sub moveMovieGrid(delta as Integer)
    if m.movieItems.count() = 0 then return
    target = m.movieItemIndex + delta
    if target < 0 then target = 0
    if target >= m.movieItems.count() then target = m.movieItems.count() - 1
    m.movieItemIndex = target
    updateMoviesUi()
end sub

function handleMoviesKey(key as String) as Boolean
    if key = "back"
        if m.movieMode = "detail"
            m.movieMode = "grid"
            if m.movieDetailStatusLabel <> invalid then m.movieDetailStatusLabel.text = ""
            updateMoviesUi()
        else
            backToLauncher()
        end if
        return true
    end if
    if m.movieMode = "detail"
        if key = "OK" then requestMovieStream()
        return true
    end if
    if m.movieMode = "loading" or m.movieMode = "loading_detail" then return true
    if m.movieFocusArea = "catalogs"
        if key = "up"
            if m.movieCatalogIndex > 0
                m.movieCatalogIndex = m.movieCatalogIndex - 1
                requestMovieCatalog(m.movieCatalogIndex)
            end if
        else if key = "down"
            if m.movieCatalogIndex < m.movieCatalogs.count() - 1
                m.movieCatalogIndex = m.movieCatalogIndex + 1
                requestMovieCatalog(m.movieCatalogIndex)
            end if
        else if key = "right"
            if m.movieItems.count() > 0
                m.movieFocusArea = "grid"
                updateMoviesUi()
            end if
        else if key = "OK"
            if m.movieCatalogs.count() > 0 then requestMovieCatalog(m.movieCatalogIndex)
        end if
        return true
    end if
    if m.movieFocusArea = "grid"
        if key = "left"
            if m.movieItemIndex mod m.movieColumns = 0
                m.movieFocusArea = "catalogs"
                updateMoviesUi()
            else
                moveMovieGrid(-1)
            end if
        else if key = "right"
            if m.movieItemIndex mod m.movieColumns < m.movieColumns - 1 then moveMovieGrid(1)
        else if key = "up"
            moveMovieGrid(-m.movieColumns)
        else if key = "down"
            moveMovieGrid(m.movieColumns)
        else if key = "OK"
            requestMovieMeta()
        end if
        return true
    end if
    return true
end function
