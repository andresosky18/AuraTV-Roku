sub init()
    m.top.functionName = "executeRequest"
end sub

sub executeRequest()
    req = m.top.request
    transfer = CreateObject("roUrlTransfer")
    
    ' Evadir bloqueos de seguridad de servidores IPTV
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    useInsecure = false
    if req.DoesExist("insecure") and req.insecure = true then useInsecure = true
    if useInsecure
        transfer.EnablePeerVerification(false)
        transfer.EnableHostVerification(false)
    else
        transfer.EnablePeerVerification(true)
        transfer.EnableHostVerification(true)
    end if
    
    ' Keep existing IPTV behavior by default.
    ' Direct Add-on requests explicitly use AuraTV/1.0 Roku.
    userAgent = "VLC/3.0.9 LibVLC/3.0.9"
    if req.DoesExist("userAgent") and req.userAgent <> "" then userAgent = req.userAgent
    transfer.AddHeader("User-Agent", userAgent)

    if req.DoesExist("accept") and req.accept <> ""
        transfer.AddHeader("Accept", req.accept)
    end if

    transfer.SetUrl(req.url)

    ' Diagnostic mode is used only for direct Add-on checks.
    ' It preserves the HTTP status/body so AURA TV can distinguish
    ' 403, TLS/network errors, redirects and invalid JSON.
    if req.DoesExist("diagnostic") and req.diagnostic = true
        transfer.RetainBodyOnError(true)
        port = CreateObject("roMessagePort")
        transfer.SetMessagePort(port)

        started = false
        if req.method = "POST"
            transfer.AddHeader("Content-Type", "application/json")
            started = transfer.AsyncPostFromString(FormatJson(req.payload))
        else
            started = transfer.AsyncGetToString()
        end if

        if started
            msg = wait(15000, port)

            if type(msg) = "roUrlEvent"
                code = msg.GetResponseCode()
                body = msg.GetString()
                failure = msg.GetFailureReason()

                if body = invalid then body = ""
                if failure = invalid then failure = ""

                if code >= 200 and code < 300
                    if req.DoesExist("raw") and req.raw = true
                        m.top.response = {
                            action:req.action,
                            rawData:body,
                            httpCode:code
                        }
                    else
                        parsed = ParseJson(body)
                        if parsed <> invalid
                            m.top.response = {
                                action:req.action,
                                data:parsed,
                                httpCode:code
                            }
                        else
                            m.top.response = {
                                action:req.action,
                                error:"Invalid JSON",
                                httpCode:code,
                                bodySnippet:Left(body, 220)
                            }
                        end if
                    end if
                else
                    m.top.response = {
                        action:req.action,
                        error:"HTTP/Network Error",
                        httpCode:code,
                        failureReason:failure,
                        bodySnippet:Left(body, 220)
                    }
                end if
            else
                m.top.response = {
                    action:req.action,
                    error:"Timeout",
                    httpCode:0,
                    failureReason:"No response within 15 seconds"
                }
            end if
        else
            m.top.response = {
                action:req.action,
                error:"Request start failed",
                httpCode:0
            }
        end if

        return
    end if

    resStr = ""
    if req.method = "POST"
        transfer.AddHeader("Content-Type", "application/json")
        resStr = transfer.PostFromString(FormatJson(req.payload))
    else
        resStr = transfer.GetToString()
    end if

    if resStr <> invalid and resStr <> ""
        if req.DoesExist("raw") and req.raw = true
            m.top.response = {action: req.action, rawData: resStr}
        else
            parsed = ParseJson(resStr)
            if parsed <> invalid
                m.top.response = {action: req.action, data: parsed}
            else
                m.top.response = {action: req.action, error: "Invalid JSON"}
            end if
        end if
    else
        m.top.response = {action: req.action, error: "Network Error"}
    end if
end sub