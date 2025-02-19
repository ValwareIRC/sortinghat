import
  irc,
  re,
  ansi,
  houses,
  wizardinfo,
  quizsessions,
  sortingquiz

import
  os,
  nativesockets,
  strutils,
  strformat

const helpText = [
  fmt"{clrOrange}Commands:",
  fmt"{clrRed}!quiz house {clrDefault}(Take a quiz),",
  fmt"{clrRed}!house [name] {clrDefault}(Get the house of yourself or another wizard),",
  fmt"{clrRed}!wand [name] {clrDefault}(Get the wand of yourself or another wizard),",
  fmt"{clrRed}!g {clrDefault}(List students in the Gryffindor house),",
  fmt"{clrRed}!h {clrDefault}(List students in the Hufflepuff house),",
  fmt"{clrRed}!r {clrDefault}(List students in the Ravenclaw house),",
  fmt"{clrRed}!s {clrDefault}(List students in the Slytherin house),",
].join(" ")

let
  regexIntegerOnly = re"^[0-9]+$"
  isBotUserCommandRegex = re"^<.*?> "


var authPass: string
var relayBot: string

type
  FormattedResponse = string
  Commands = enum
    cmdNone
    cmdHelp
    cmdQuiz
    cmdHouse
    cmdWand
    cmdGryffindor
    cmdHufflePuff
    cmdRavenclaw
    cmdSlytherin

proc determineCommand(str: string): Commands
proc handleCommand(client: Irc, e: IrcEvent, nick, message: string)
proc handleMsg(client: Irc, e: IrcEvent)
proc answerQuizQuestion(client: Irc, e: IrcEvent, nick: string, index: int)

proc handleMsg(client: Irc, e: IrcEvent) =
  echo e.raw
  if e.text == "If you do not change within 1 minute, I will change your nick." and authPass.len > 0 and e.nick == "NickServ":
    client.privmsg("NickServ", fmt"IDENTIFY {authPass}")

  if e.cmd == MPrivMsg:
    var
      nick = e.nick
      message = e.text

    if e.text.match(isBotUserCommandRegex) and nick == relayBot:
      let split = e.text.split("> ", 1)
      nick = split[0][1..^1]
      message = split[1]

    if message.startsWith('!'):
      client.handleCommand(e, nick, message)
    elif message.match(regexIntegerOnly):
      # User may be answering a quiz question.
      answerQuizQuestion(client, e, nick, parseInt(message) - 1)

proc determineCommand(str: string): Commands =
  case str:
    of "help", "commands":
      cmdHelp
    of "quiz":
      cmdQuiz
    of "house":
      cmdHouse
    of "wand":
      cmdWand
    of "g":
      cmdGryffindor
    of "h":
      cmdHufflePuff
    of "r":
      cmdRavenclaw
    of "s":
      cmdSlytherin
    else:
      cmdNone

proc retrieveHouse(e: IrcEvent, nick, text: string): string =
  let trimmedText = text.strip()
  let lookupName =
    if trimmedText.len > 0:
      trimmedText.split(Whitespace)[0]
    else:
      nick
    
  let wizardInfo = getWizardByName(lookupName)
  if wizardInfo == nil:
    return fmt"No wizard by the name {lookupName} has been found."

  if wizardInfo.fields.hasKey("house"):
    let house = wizardInfo.fields["house"]
    return fmt"{lookupName} is in {house}."
  else:
    return "Wizard has not been sorted into a house."

proc retrieveWand(e: IrcEvent, nick, text: string): string =
  let trimmedText = text.strip()
  let lookupName =
    if trimmedText.len > 0:
      trimmedText.split(Whitespace)[0]
    else:
      nick
    
  let wizardInfo = getWizardByName(lookupName)
  if wizardInfo == nil:
    return fmt"No wizard by the name {lookupName} has been found."

  if wizardInfo.fields.hasKey("wand"):
    let wand = wizardInfo.fields["wand"]
    return fmt"{lookupName}'s wand: {wand}."
  else:
    return "Wizard has not been assigned a wand."

proc sendNextQuizQuestion(client: Irc, e: IrcEvent, nick: string) =
  let session = getSession(nick)
  let question = session.getCurrentQuestion()
  client.privmsg(e.origin, fmt"{nick}: {clrYellow}{question.question}")
  for i, answer in question.answers:
    client.privmsg(e.origin, fmt"{clrYellow}[{i + 1}] {clrDefault}{answer}")

proc handleQuiz(client: Irc, e: IrcEvent, nick, text: string) =
  try:
    startHouseQuiz(nick)
    sendNextQuizQuestion(client, e, nick)
  except Exception as err:
    client.privmsg(e.origin, fmt"{clrRed}{err.msg}")

proc answerQuizQuestion(client: Irc, e: IrcEvent, nick: string, index: int) =
  try:
    let session = getSession(nick)
    if session != nil:
      session.answerCurrentQuestion(index)
      if session.isFinished:
        let house = $session.determineHouse()
        client.privmsg(e.origin, fmt"{nick} has been placed in House {house}!")
        closeQuiz(nick)
        saveWizardHouse(nick, house)
      else:
        client.sendNextQuizQuestion(e, nick)
  except Exception as err:
    client.privmsg(e.origin, fmt"{clrRed}{err.msg}")

template getHouseColor(house: House): Color =
  case house:
    of Gryffindor:
      clrRed
    of Hufflepuff:
      clrYellow
    of Ravenclaw:
      clrBlue
    of Slytherin:
      clrGreen

proc handleCommand(client: Irc, e: IrcEvent, nick, message: string) =
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
    of cmdQuiz:
      let wizardInfo = getWizardByName(nick)
      if wizardInfo != nil and wizardInfo.fields.hasKey("house"):
        let house = wizardInfo.fields["house"]
        client.privmsg(e.origin, fmt"{nick} is already in house {house}")
      else:
        client.handleQuiz(e, nick, text)
    of cmdHouse:
      let house = retrieveHouse(e, nick, text)
      client.privmsg(e.origin, house)
    of cmdWand:
      let wand = retrieveWand(e, nick, text)
      client.privmsg(e.origin, wand)
    of cmdGryffindor, cmdHufflePuff, cmdRavenclaw, cmdSlytherin:
      let
        houseName = ($command)[3 .. ($command).high]
        house = parseEnum[House](houseName)
        wizards = getWizardsByHouse(house)
        houseColor = getHouseColor(house)

      if wizards.len == 0:
        client.privmsg(e.origin, fmt"No wizards in house {houseColor}{houseName}")
      else:
        let
          wizardsJoined = wizards.join(", ")
          message = fmt"Wizards in house {houseColor}{house}: {wizardsJoined}"
        client.privmsg(e.origin, message)

when isMainModule:
  # TODO: Can make this all async probably.
  let wizardsFile = getEnv("WIZARDS_FILE", "./wizards.json")
  echo "LOADING WIZARDS FROM ", wizardsFile
  loadWizardInfo(wizardsFile)
  echo "LOADED ", wizardLookup.len, " WIZARDS"

  let client = newIrc(
    getEnv("IRC_ADDRESS", "irc.irc-nerds.net"),
    port = Port(6697),
    useSsl = true,
    nick = getEnv("IRC_NICK", "SortingHat"),
    joinChans = @["#Hogwarts", "#testing"]
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

