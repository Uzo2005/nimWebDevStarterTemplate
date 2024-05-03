import macros, os, sequtils, strutils
import nimja

const templateDir* = readfile(".env").splitLines
    .mapIt(it.split("=").mapit(it.strip))
    .filterit(it[0] == "SRC_DIR")[0][1]

macro declarePageBuilders() =
    result = newStmtList()
    for file in walkDir(templateDir / "views"):
        let fileInfo = file.path.splitFile
        if fileInfo.ext == ".nimja":
            let page = fileInfo.name
            result.add newProc(
                newNimNode(nnkPostfix).add(ident("*"), ident("get" & page & "Page")),
                params = [getTypeInst(string)],
                pragmas = newNimNode(nnkPragma).add(
                        ident("nimcall"), ident("exportc"), ident("dynlib"), ident("gcsafe")
                    ),
                body = newCall(
                    ident "compileTemplateFile",
                    newLit getScriptDir() / templateDir / "views" / page & ".nimja",
                ),
            )

declarePageBuilders()

# expandMacros:
#     declarePageBuilders()

