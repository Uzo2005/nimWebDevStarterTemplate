include ./server
import prologue/middlewares/staticfile

app.use(staticFileMiddleware(env.getOrDefault("staticDir", "./public"))) 

proc getLandingPage(ctx: Context){.async, gcsafe.} =
    resp getIndexPage()

app.get("/", getLandingPage)

app.run()
