import tables, times, os

var fileLookupTable{.threadVar.}:Table[string, Time] 

proc fileWatcherDetectChange*(dir: string): tuple[changed: bool, path: string] {.gcsafe.}=
    for filepath in walkDirRec(dir):
        if fileLookupTable.hasKey(filePath):
            let lastModification = getLastModificationTime(filePath)
            if lastModification != fileLookupTable[filePath]:
                echo "CHANGED : ", filePath
                fileLookupTable[filePath] =  getLastModificationTime(filePath)
                return (changed: true, path: filepath)
            
        else:
            echo "NEW : ", filepath
            fileLookupTable[filePath] =  getLastModificationTime(filePath)
