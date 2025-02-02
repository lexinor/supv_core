local GetCurrentResourceName <const>, PerformHttpRequest <const>, GetResourceMetadata <const>, print <const> = GetCurrentResourceName, PerformHttpRequest, GetResourceMetadata, print
local version <const> = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)

local function findPattern(text, pattern, start, END)
    return string.sub(text, string.find(text, pattern, start), END)
end

local function Check(url, checker, error, types, link, lang, timer, webhook)
    if #url < 10 and not version and not types then return end

    local message <const> = {
        ['fr'] = {
            needUpate = "^3Veuillez mettre à jour la ressource %s\n^3votre version : ^1%s ^7->^3 nouvelle version : ^2%s\n^3liens : ^4%s",
            error = "^1Impossible de vérifier la version du script"
        },

        ['en'] = {
            needUpate = "^3Update this resource %s\n^3your version : ^1%s ^7->^4 new version : ^2%s\n^3link : ^4%s",
            error = "^1Impossible to check version of script"
        }
    }

    local tr

    if lang and not message[lang] then tr = 'en' elseif lang and message[lang] then tr = lang end

    local Checker = checker or message[tr].needUpate or message['en'].needUpate
    local Error = error or message[tr].error or message['en'].error

    CreateThread(function()
        Wait(timer or 3000)

        PerformHttpRequest(url, function(code, res, headers)
            if code == 200 then
                local _gv = {}
                if types == 'json' then
                    _gv = json.decode(res)
                elseif types == 'lua' then
                    local chuck = res
                    if not _gv.version then
                        local str = findPattern(chuck, "version '", 1, 0)
                        print(str)
                        local v = string.gsub(findPattern(str, "'...'", 1), "'", '')
                        _gv.version = string.gsub(v, ',', '.')
                    end
                    if not _gv.link then _gv.link = link end
                    if not _gv.script then _gv.script = GetCurrentResourceName() end
                end

                if _gv.version == version then return end
                if _gv.version ~= version then
                    if _gv.msg then
                        Checker = Checker.."\n^3changelog : \n^7%s"
                    end
                    print('^9---------------------------------------------------------')
                    print(Checker:format(_gv.script, version, _gv.version, _gv.link, _gv.msg))
                    print('^9---------------------------------------------------------')

                    local webhooks = type(webhook) == 'table' and #webhook > 0 and webhook
                    if not webhooks then return end
    
                    for i = 1, #webhooks do
                        local w = webhooks[i]
                        if #w.link > 0 then
                            if _gv.msg then
                                _gv.msg = "```md\n".._gv.msg.."\n```"
                            end
                            supv.webhook.embed(w.link, {
                                title = ("__**%s :**__ *v%s -> v%s*"):format(_gv.script, version, _gv.version),
                                description = ("%s\n*- __link:__ %s*"):format(_gv.msg or '', _gv.link)
                            }, w.name or 'supv_core')
                        end
                    end
                end
            else
                print(Error)
            end
        end)
    end)
end

return {
    check = Check
}