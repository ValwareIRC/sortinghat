import
  irc,
  ansi,
  wizardinfo

import
  os,
  nativesockets,
  random,
  strutils,
  strformat

randomize()

const helpText = [
  fmt"{clrOrange}Commands:",
  # fmt"{clrRed}!quiz [house | wand | patronus] {clrDefault}(Take a quiz),",
  fmt"{clrRed}!house [name] {clrDefault}(Get the house of yourself or another wizard),",
  fmt"{clrRed}!wand [name] {clrDefault}(Get the wand of yourself or another wizard),",
].join(" ")

var authPass: string

type
  FormattedResponse = string
  Commands = enum
    cmdNone,
    cmdHelp,
    # cmdQuiz
    cmdHouse
    cmdWand

proc determineCommand(str: string): Commands
proc handleCommand(client: Irc, e: IrcEvent, message: string)
proc handleMsg(client: Irc, e: IrcEvent)

proc handleMsg(client: Irc, e: IrcEvent) =
  echo e.raw
  if e.text == "If you do not change within 1 minute, I will change your nick." and authPass.len > 0:
    client.privmsg("NickServ", fmt"IDENTIFY {authPass}")

  if e.cmd == MPrivMsg:
    let message = e.text
    if message.startsWith('!'):
      client.handleCommand(e, message)

proc determineCommand(str: string): Commands =
  case str:
    of "help", "commands", "h":
      cmdHelp
    # of "quiz":
    #   cmdQuiz
    of "house":
      cmdHouse
    of "wand":
      cmdWand
    else:
      cmdNone

proc retrieveHouse(e: IrcEvent, text: string): string =
  let trimmedText = text.strip()
  let lookupName =
    if trimmedText.len > 0:
      trimmedText.split(Whitespace)[0]
    else:
      e.nick
    
  let wizardInfo = getWizardByName(lookupName)
  if wizardInfo == nil:
    return fmt"No wizard by the name {lookupName} has been found."

  if wizardInfo.fields.hasKey("house"):
    let house = wizardInfo.fields["house"]
    return fmt"{lookupName} is in {house}."
  else:
    return "Wizard has not been sorted into a house."

proc retrieveWand(e: IrcEvent, text: string): string =
  let trimmedText = text.strip()
  let lookupName =
    if trimmedText.len > 0:
      trimmedText.split(Whitespace)[0]
    else:
      e.nick
    
  let wizardInfo = getWizardByName(lookupName)
  if wizardInfo == nil:
    return fmt"No wizard by the name {lookupName} has been found."

  if wizardInfo.fields.hasKey("wand"):
    let wand = wizardInfo.fields["wand"]
    return fmt"{lookupName}'s wand: {wand}."
  else:
    return "Wizard has not been assigned a wand."

proc handleCommand(client: Irc, e: IrcEvent, message: string) =
  ## message:
  ##   The message to parse, e.g. !gh foobar
  let
    split = message.split()
    commandText = if split[0].len > 1: split[0][1 .. ^1] else: ""
    command = determineCommand(commandText)
    text = if split.len < 2: "" else: split[1..^1].join(" ")

  case command:
    of cmdNone:
      discard
    of cmdHelp:
      client.privmsg(e.origin, helpText)
    # of cmdQuiz:
    #   # TODO:
    #   discard
    of cmdHouse:
      let house = retrieveHouse(e, text)
      client.privmsg(e.origin, house)
    of cmdWand:
      let wand = retrieveWand(e, text)
      client.privmsg(e.origin, wand)

when isMainModule:
  # TODO: Can make this all async probably.
  let wizardsFile = getEnv("WIZARDS_FILE", "./wizards.toml")
  echo "LOADING WIZARDS FROM ", wizardsFile
  loadWizardInfo(wizardsFile)
  echo "LOADED ", wizardLookup.len, " WIZARDS"

  let client = newIrc(
    getEnv("IRC_ADDRESS", "irc.irc-nerds.net"),
    port = Port(6697),
    useSsl = true,
    nick = getEnv("IRC_NICK", "SortingHat"),
    joinChans = @["#testing"]
  )
  client.connect()

  authPass = getEnv("IRC_PASSWORD", "")
  if authPass.len > 0:
    client.privmsg("NickServ", fmt"IDENTIFY {authPass}")
    # TODO: https://datatracker.ietf.org/doc/html/rfc4422

  while true:
    var e: IrcEvent
    if client.poll(e):
      # echo e.raw
      case e.typ:
      of EvMsg:
        client.handleMsg e

      # Connection events
      of EvConnected:
        echo $e.typ
      of EvDisconnected, EvTimeout:
        echo $e.typ
        client.reconnect()

