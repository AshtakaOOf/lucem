import std/[os, logging, strutils]
import toml_serialization
import ./[argparser, sugar]

type WindowingBackend* {.pure.} = enum
  X11
  Wayland

func `$`*(backend: WindowingBackend): string {.inline.} =
  case backend
  of WindowingBackend.Wayland: "Wayland"
  of WindowingBackend.X11: "X11"

proc autodetectWindowingBackend*(): WindowingBackend {.inline.} =
  case getEnv("XDG_SESSION_TYPE")
  of "wayland":
    return WindowingBackend.Wayland
  of "x11":
    return WindowingBackend.X11
  else:
    warn "lucem: XDG_SESSION_TYPE was set to \"" & getEnv("XDG_SESSION_TYPE") &
      "\"; defaulting to X11"
    return WindowingBackend.X11

type
  APKConfig* = object
    version*: string = ""

  LucemConfig* = object
    discord_rpc*: bool = true
    notify_server_region*: bool = true
    loading_screen*: bool = true
    polling_delay*: uint = 100

  ClientConfig* = object
    fps*: int = 60
    launcher*: string = ""
    backend: string
    telemetry*: bool = false
    fflags*: string
    apkUpdates*: bool = true

  Tweaks* = object
    oldOof*: bool = false
    moon*: string = ""
    sun*: string = ""
    font*: string = ""

  Config* = object
    apk*: APKConfig
    lucem*: LucemConfig
    tweaks*: Tweaks
    client*: ClientConfig

proc backend*(config: Config): WindowingBackend =
  if config.client.backend.len < 1:
    debug "lucem: backend name was not set, defaulting to autodetection"
    return autodetectWindowingBackend()

  case config.client.backend.toLowerAscii()
  of "wayland", "wl", "waeland":
    return WindowingBackend.Wayland
  of "x11", "xorg", "bloat", "garbage":
    return WindowingBackend.X11
  else:
    warn "lucem: invalid backend name \"" & config.client.backend &
      "\"; using autodetection"
    return autodetectWindowingBackend()

const
  DefaultConfig* =
    """
[lucem]
discord_rpc = true
loading_screen = true
notify_server_region = true
polling_delay = 100

[tweaks]
oldOof = false
font = ""
moon = ""
sun = ""

[client]
fps = 60
apk_updates = true
fflags = """ &
    "\"\"\"\"\"\""

  ConfigLocation* {.strdefine: "LucemConfigLocation".} = "$1/.config/lucem/"

proc save*(config: Config) {.inline.} =
  writeFile(ConfigLocation % [getHomeDir()] / "config.toml", Toml.encode(config))

proc parseConfig*(input: Input): Config {.inline.} =
  discard existsOrCreateDir(ConfigLocation % [getHomeDir()])

  let
    inputFile = input.flag("config-file")
    config = readFile(
      if *inputFile:
        &inputFile
      elif fileExists(ConfigLocation % [getHomeDir()] / "config.toml"):
        ConfigLocation % [getHomeDir()] / "config.toml"
      else:
        warn "lucem: cannot find config file, defaulting to built-in config file."
        writeFile(ConfigLocation % [getHomeDir()] / "config.toml", DefaultConfig)
        ConfigLocation % [getHomeDir()] / "config.toml"
    )

  Toml.decode(config, Config)
