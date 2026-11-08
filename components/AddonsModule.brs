
sub initAddonsModule()
    m.addonBaseUrl = "https://roku-backend-iptv.vercel.app/api/addons"

    m.addonsGroup = m.top.findNode("addonsGroup")
    m.addonsTitleLabel = m.top.findNode("addonsTitleLabel")
    m.addonsSubtitleLabel = m.top.findNode("addonsSubtitleLabel")
    m.addonsRowsGroup = m.top.findNode("addonsRowsGroup")
    m.addonsHelpTitleLabel = m.top.findNode("addonsHelpTitleLabel")
    m.addonsHelpBodyLabel = m.top.findNode("addonsHelpBodyLabel")
    m.addonsPortalLabel = m.top.findNode("addonsPortalLabel")
    m.addonsStatusLabel = m.top.findNode("addonsStatusLabel")

    m.addonItems = []
    m.addonRowNodes = []
    m.addonIndex = 0
    m.addonTop = 0
    m.addonDirectQueue = []
    m.addonDirectQueueIndex = 0
    m.addonDirectResolvingIndex = -1
end sub

sub buildAddonsUi()
    m.addonRowNodes = []

    if m.addonsRowsGroup = invalid then return

    for i = 0 to 6
        g = m.addonsRowsGroup.createChild("Group")
        g.translation = [0, i * 58]

        border = g.createChild("Rectangle")
        border.width = 632
        border.height = 52
        border.color = "0xFFFFFF18"

        bg = g.createChild("Rectangle")
        bg.translation = [1, 1]
        bg.width = 630
        bg.height = 50
        bg.color = "0x0F1624FF"

        nameLabel = g.createChild("Label")
        nameLabel.translation = [18, 13]
        nameLabel.width = 380
        nameLabel.height = 24
        nameLabel.text = ""
        nameLabel.color = "0xF8FAFCFF"
        nameLabel.font = "font:SmallBoldSystemFont"

        metaLabel = g.createChild("Label")
        metaLabel.translation = [405, 14]
        metaLabel.width = 205
        metaLabel.height = 22
        metaLabel.text = ""
        metaLabel.horizAlign = "right"
        metaLabel.color = "0x38BDF8FF"
        metaLabel.font = "font:SmallBoldSystemFont"

        m.addonRowNodes.push({
            group:g,
            border:border,
            bg:bg,
            nameLabel:nameLabel,
            metaLabel:metaLabel
        })
    end for
end sub

sub applyAddonsLanguage()
    if m.addonsTitleLabel <> invalid then m.addonsTitleLabel.text = auraText("addons")
    if m.addonsSubtitleLabel <> invalid then m.addonsSubtitleLabel.text = auraText("addons_subtitle")
    if m.addonsHelpTitleLabel <> invalid then m.addonsHelpTitleLabel.text = auraText("addons_help_title")
    if m.addonsHelpBodyLabel <> invalid then m.addonsHelpBodyLabel.text = auraText("addons_help_body")
end sub

sub openAddons()
    m.appState = "addons"
    m.addonIndex = 0
    m.addonTop = 0
    m.addonItems = []

    if m.addonsStatusLabel <> invalid
        m.addonsStatusLabel.text = auraText("addons_loading")
    end if

    updateAllUi()
    requestAddonsList()
end sub

sub requestAddonsList(isBackground = false as Boolean)
    m.apiTask = CreateObject("roSGNode", "BackendTask")
    url = m.addonBaseUrl + "?action=list&mac=" + m.deviceMac + "&key=" + m.deviceKey

    act = "addon_list"
    if isBackground then act = "addon_list_bg"

    m.apiTask.request = {
        url:url,
        method:"GET",
        action:act,
        insecure:false
    }
    m.apiTask.observeField("response", "onApiResponse")
    m.apiTask.control = "RUN"
end sub

sub handleAddonsApiResponse(res as Object)
    if res = invalid then return

    if res.action = "addon_direct_manifest"
        handleDirectAddonManifestResponse(res)
        return
    end if

    if res.action = "addon_list_bg"
        if not res.DoesExist("error") and res.data <> invalid and res.data.DoesExist("addons")
            oldIds = ""
            for each a in m.addonItems
                if a <> invalid
                    if a.DoesExist("id") and a.id <> ""
                        oldIds = oldIds + a.id.toStr() + "|"
                    else if a.DoesExist("manifestUrl")
                        oldIds = oldIds + a.manifestUrl.toStr() + "|"
                    end if
                end if
            end for
            newIds = ""
            for each a in res.data.addons
                if a <> invalid
                    if a.DoesExist("id") and a.id <> ""
                        newIds = newIds + a.id.toStr() + "|"
                    else if a.DoesExist("manifestUrl")
                        newIds = newIds + a.manifestUrl.toStr() + "|"
                    end if
                end if
            end for
            if oldIds <> newIds
                res.action = "addon_list"
            else
                return
            end if
        else
            return
        end if
    end if

    if res.action <> "addon_list" then return

    m.addonItems = []
    m.addonIndex = 0
    m.addonTop = 0

    if res.DoesExist("error")
        if m.addonsStatusLabel <> invalid then m.addonsStatusLabel.text = auraText("sync_error")
        updateAddonsUi()
        return
    end if

    if res.data <> invalid and res.data.DoesExist("addons")
        for each addon in res.data.addons
            if addon <> invalid then m.addonItems.push(addon)
        end for
    end if

    m.addonDirectQueue = []
    m.addonDirectQueueIndex = 0

    for i = 0 to m.addonItems.count() - 1
        addon = m.addonItems[i]
        if addon <> invalid and addon.DoesExist("mode")
            if addon.mode = "direct" and addon.DoesExist("manifestUrl") and addon.manifestUrl <> ""
                m.addonDirectQueue.push(i)
            end if
        end if
    end for

    if m.addonItems.count() = 0
        if m.addonsStatusLabel <> invalid then m.addonsStatusLabel.text = auraText("addons_empty")
    else if m.addonDirectQueue.count() > 0
        if m.addonsStatusLabel <> invalid then m.addonsStatusLabel.text = auraText("addon_direct_testing")
    else
        if m.addonsStatusLabel <> invalid then m.addonsStatusLabel.text = auraText("addons_back_hint")
    end if

    updateAddonsUi()

    if m.addonDirectQueue.count() > 0 then requestNextDirectAddonManifest()
end sub

sub requestNextDirectAddonManifest()
    if m.addonDirectQueueIndex >= m.addonDirectQueue.count()
        if m.addonsStatusLabel <> invalid then m.addonsStatusLabel.text = auraText("addons_back_hint")
        updateAddonsUi()
        return
    end if

    idx = m.addonDirectQueue[m.addonDirectQueueIndex]

    if idx < 0 or idx >= m.addonItems.count()
        m.addonDirectQueueIndex = m.addonDirectQueueIndex + 1
        requestNextDirectAddonManifest()
        return
    end if

    addon = m.addonItems[idx]
    m.addonDirectResolvingIndex = idx

    m.apiTask = CreateObject("roSGNode", "BackendTask")
    m.apiTask.request = {
        url:addon.manifestUrl,
        method:"GET",
        action:"addon_direct_manifest",
        insecure:false,
        userAgent:"AuraTV/1.0 Roku",
        accept:"application/json, text/json;q=0.9, */*;q=0.2",
        diagnostic:true
    }
    m.apiTask.observeField("response", "onApiResponse")
    m.apiTask.control = "RUN"
end sub

sub handleDirectAddonManifestResponse(res as Object)
    idx = m.addonDirectResolvingIndex

    if idx >= 0 and idx < m.addonItems.count()
        addon = m.addonItems[idx]

        if res.DoesExist("error") or res.data = invalid
            addon.directClientStatus = "failed"

            codeText = "ERROR"
            if res.DoesExist("httpCode")
                if res.httpCode <> 0 then codeText = res.httpCode.toStr()
            end if

            addon.directClientCode = codeText

            detail = ""
            if res.DoesExist("failureReason") and res.failureReason <> ""
                detail = res.failureReason
            else if res.DoesExist("bodySnippet") and res.bodySnippet <> ""
                detail = res.bodySnippet
            end if

            addon.directClientDetail = detail
        else
            manifest = res.data
            addon.directClientStatus = "ready"

            if manifest.DoesExist("id") then addon.resolvedId = manifest.id
            if manifest.DoesExist("name") and manifest.name <> "" then addon.name = manifest.name
            if manifest.DoesExist("version") then addon.version = manifest.version
            if manifest.DoesExist("types") then addon.types = manifest.types
            if manifest.DoesExist("resources") then addon.resources = manifest.resources
            if manifest.DoesExist("catalogs") then addon.catalogs = manifest.catalogs
        end if

        m.addonItems[idx] = addon
    end if

    m.addonDirectQueueIndex = m.addonDirectQueueIndex + 1

    if m.addonDirectQueueIndex < m.addonDirectQueue.count()
        if m.addonsStatusLabel <> invalid then m.addonsStatusLabel.text = auraText("addon_direct_testing")
        updateAddonsUi()
        requestNextDirectAddonManifest()
    else
        anyReady = false

        for each addon in m.addonItems
            if addon.DoesExist("directClientStatus") and addon.directClientStatus = "ready"
                anyReady = true
            end if
        end for

        if m.addonsStatusLabel <> invalid
            if anyReady
                m.addonsStatusLabel.text = auraText("addon_direct_ready")
            else
                m.addonsStatusLabel.text = auraText("addons_back_hint")
            end if
        end if

        updateAddonsUi()
    end if
end sub

sub updateAddonsUi()
    if m.addonsGroup = invalid then return
    if m.appState <> "addons" then return

    applyAddonsLanguage()

    if m.addonIndex < m.addonTop then m.addonTop = m.addonIndex
    if m.addonIndex >= m.addonTop + 7 then m.addonTop = m.addonIndex - 6
    if m.addonTop < 0 then m.addonTop = 0

    for i = 0 to m.addonRowNodes.count() - 1
        node = m.addonRowNodes[i]
        idx = m.addonTop + i

        if idx < m.addonItems.count()
            node.group.visible = true
            addon = m.addonItems[idx]

            addonName = "Add-on"
            if addon.DoesExist("name") and addon.name <> "" then addonName = addon.name
            node.nameLabel.text = addonName

            meta = ""
            if addon.DoesExist("version") and addon.version <> "" then meta = "v" + addon.version

            if addon.DoesExist("types")
                typesText = ""
                for each t in addon.types
                    if typesText <> "" then typesText = typesText + " · "
                    typesText = typesText + t
                end for
                if typesText <> ""
                    if meta <> "" then meta = meta + "  "
                    meta = meta + typesText
                end if
            end if

            if addon.DoesExist("mode") and addon.mode = "direct"
                if addon.DoesExist("directClientStatus")
                    if addon.directClientStatus = "ready"
                        meta = "DIRECT  OK"
                    else if addon.directClientStatus = "failed"
                        meta = "DIRECT  ERROR"
                        if addon.DoesExist("directClientCode") and addon.directClientCode <> ""
                            meta = "DIRECT  " + addon.directClientCode
                        end if
                    else
                        meta = "DIRECT  ..."
                    end if
                else
                    meta = "DIRECT  ..."
                end if
            end if

            node.metaLabel.text = meta

            if idx = m.addonIndex
                if node.border <> invalid then node.border.color = "0x38BDF8FF"
                node.bg.color = "0xFFFFFFFF"
                node.nameLabel.color = "0x090D16FF"
                node.metaLabel.color = "0x0284C7FF"
            else
                if node.border <> invalid then node.border.color = "0xFFFFFF18"
                node.bg.color = "0x0F1624FF"
                node.nameLabel.color = "0xF8FAFCFF"
                node.metaLabel.color = "0x38BDF8FF"
            end if
        else
            node.group.visible = false
        end if
    end for

    if m.addonsStatusLabel <> invalid and m.addonIndex >= 0 and m.addonIndex < m.addonItems.count()
        selectedAddon = m.addonItems[m.addonIndex]

        if selectedAddon.DoesExist("mode") and selectedAddon.mode = "direct"
            if selectedAddon.DoesExist("directClientStatus") and selectedAddon.directClientStatus = "failed"
                codeText = "ERROR"
                if selectedAddon.DoesExist("directClientCode") then codeText = selectedAddon.directClientCode

                statusText = "Direct test: " + codeText

                if selectedAddon.DoesExist("directClientDetail") and selectedAddon.directClientDetail <> ""
                    detail = selectedAddon.directClientDetail
                    if Len(detail) > 90 then detail = Left(detail, 90) + "..."
                    statusText = statusText + "  ·  " + detail
                end if

                m.addonsStatusLabel.text = statusText
            end if
        end if
    end if
end sub

function handleAddonsKey(key as String) as Boolean
    if key = "back"
        backToLauncher()
        return true
    end if

    if key = "up"
        if m.addonIndex > 0
            m.addonIndex = m.addonIndex - 1
            updateAddonsUi()
        end if
        return true
    end if

    if key = "down"
        if m.addonIndex < m.addonItems.count() - 1
            m.addonIndex = m.addonIndex + 1
            updateAddonsUi()
        end if
        return true
    end if

    if key = "OK"
        if m.addonsStatusLabel <> invalid then m.addonsStatusLabel.text = auraText("addons_loading")
        requestAddonsList()
        return true
    end if

    return true
end function
