## Reducing code clutter when making HTTP requests
import std/[logging, monotimes]
import pkg/[curly]
import ./meta

var curl = newCurly()
proc httpGet*(url: string): string =
  debug "http: making HTTP/GET request to " & url & "; allocating HttpClient"
  let
    startReq = getMonoTime()
    req = curl.get(url)
    endReq = getMonoTime()

  debug "http: HTTP/GET request to " & url & " took " & $(endReq - startReq)

  req.body
