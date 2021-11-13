import json
import houses
export houses

type WizardInfo* = ref object
  fields*: Table[string, string]

var
  wizardInfoFilePath: string
  wizardLookup* = initTable[string, WizardInfo]()

proc loadWizardInfo*(filepath: string) =
  wizardInfoFilePath = filepath

  let
    rawJson = readFile(wizardInfoFilePath)
    json = parseJson(rawJson)

  let wizards = json["wizards"]
  for wizard in wizards.getElems():
    var info: WizardInfo = WizardInfo()
    for name, attributes in wizard.pairs:
      for key, value in attributes.pairs():
        let valueAsString = $value
        info.fields[key] = valueAsString[1..<valueAsString.high]
      wizardLookup[name] = info

proc getWizardByName*(name: string): WizardInfo =
  if wizardLookup.hasKey(name):
    return wizardLookup[name]
  return nil

proc wizardLookupStateToJson(): JsonNode =
  ## Saves current wizardLookup state to the current wizardInfoFile.
  result = newJObject()
  let wizardsArray = newJArray()

  for wizardName, info in wizardLookup.pairs():
    let 
      wizard = newJObject()
      wizardInfoJson = newJObject()

    for key, value in info.fields.pairs():
      wizardInfoJson.fields[key] = newJString(value)

    wizard[wizardName] = wizardInfoJson
    wizardsArray.add(wizard)

  result["wizards"] = wizardsArray

proc saveWizardLookupStateToFile*() =
  let jsonState = wizardLookupStateToJson()
  writeFile(wizardInfoFilePath, $jsonState)

proc saveWizardHouse*(name, house: string) =
  if wizardLookup.hasKey(name):
    var info = wizardLookup[name]
    info.fields["house"] = house
  else:
    var info = WizardInfo()
    info.fields["house"] = house
    wizardLookup[name] = info
  
  saveWizardLookupStateToFile()

