module Server exposing (url)

url: String
url =
    {--
        URL of Node.js server. If you want to change this
        you also need to change a few values in server/server.j
    --}
    "http://localhost:3000"