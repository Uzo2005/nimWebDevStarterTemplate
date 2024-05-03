import prologue
import macros, os

let 
    env = loadPrologueEnv(".env")
    settings = newSettings(appName = env.getOrDefault("appName", "<AppName>"),
                         debug = env.getOrDefault("debugMode", true), 
                         port = Port env.getOrDefault("port", 2005),
                         secretKey = env.getOrDefault("secretKey", "<SecretKey>")
    )

var app = newApp(settings = settings)

when not defined(release): #devmode
    from ./templates import templateDir
    import ./utils/fileWatcher
    import dynlib, strutils

    discard execShellCmd("nim c --app:lib templates.nim") #to ensure we have the latest state immediately

    const templateLibPath = "./" & DynlibFormat % "templates"
    var templateLibHandle = loadLib(templateLibPath)

    if templateLibHandle.isNil:
        echo "ERROR: could not load the templates dynamic library at ", templateLibPath
        quit(1)

    macro getRouteHandlersFromDynamicLibrary(libHandle: untyped) =
        result = newNimNode(nnkVarSection)
        for file in walkDir(templateDir / "views"):
            let fileInfo = file.path.splitFile
            if fileInfo.ext == ".nimja":
                let page = fileInfo.name
                result.add newNimNode(nnkIdentDefs).add(
                    ident "get" & page & "Page",
                    newEmptyNode(),
                    newNimNode(nnkCast).add(
                        newNimNode(nnkProcTy).add(
                            newNimNode(nnkFormalParams).add(ident "string"),
                            newNimNode(nnkPragma).add(ident "nimcall", ident "gcsafe"),
                        ),
                        newCall(
                            ident "checkedSymAddr", libHandle, newLit "get" & page & "Page"
                        ),
                    ),
                )

    getRouteHandlersFromDynamicLibrary(templateLibHandle)

    macro reinitialiseRouteHandlersFromDynamicLibrary(libHandle: untyped) =
        result = newStmtList()
        for file in walkDir(templateDir / "views"):
            let fileInfo = file.path.splitFile
            if fileInfo.ext == ".nimja":
                let page = fileInfo.name
                result.add newNimNode(nnkAsgn).add(
                    ident "get" & page & "Page",
                    newNimNode(nnkCast).add(
                        newNimNode(nnkProcTy).add(
                            newNimNode(nnkFormalParams).add(ident "string"),
                            newNimNode(nnkPragma).add(ident "nimcall", ident "gcsafe"),
                        ),
                        newCall(
                            ident "checkedSymAddr", libHandle, newLit "get" & page & "Page"
                        ),
                    ),
                )

    template reloadTemplatesLib(lib: var LibHandle, libPath: string) =
        unloadLib(lib)
        discard execShellCmd("nim c --app:lib templates.nim")
        lib = loadLib(libpath)
        if lib.isNil:
            echo "could not load the templates dynamic library at ", libpath
            quit(1)
        
        reinitialiseRouteHandlersFromDynamicLibrary(lib)

    proc reloadTemplatesMiddleware(): HandlerAsync =
        result = proc(ctx: Context) {.async, gcsafe.} =
            if fileWatcherDetectChange(getProjectPath()/templateDir).changed:
                reloadTemplatesLib(templateLibHandle, templateLibPath)
                
            await switch(ctx)

    app.use(reloadTemplatesMiddleware())

    # import prologue/websocket

    # proc refreshOnUpdate(ctx: Context) {.async.} =
    #     var ws = await newWebsocket(ctx)
    #     await ws.send("Websocket Is Ready")

    #     while ws.readyState == Open:
    #         if fileWatcherDetectChange(getProjectPath()/templateDir).changed:
    #             reloadTemplatesLib(templateLibHandle, templateLibPath)
    #             await ws.send("1")

    # app.get("/refreshOnUpdate", refreshOnUpdate)

else: #release mode
    import ./templates
