version     = "0.1.0"
author      = "Cletus Igwe"
description = "Project Description"
license     = "MIT"

requires "nim >= 2.0.2"

when not(defined(release)): 
    requires "websocketx>=0.1.2" #so the browser can automatically refresh on update

task buildCss, "Build The Css File With Tailwind":
    when defined(release):
        exec "tailwindcss -i tailwind.css -o public/styles.css"
    else:
        exec "tailwindcss -i tailwind.css -o public/styles.css --watch"

task runServer, "Run The Webserver":
    when defined(release):
        exec "nim c -d:release project.nim"
    else:
        exec "nim r project.nim"