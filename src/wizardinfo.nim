import parsetoml
import houses
export houses

type WizardInfo* = ref object
  fields*: Table[string, string]

var wizardLookup* = initTable[string, WizardInfo]()

proc loadWizardInfo*(filepath: string) =
  let toml = parseFile(filepath)

  for (wizardName, data) in toml.tableVal.pairs():
    var wizard: WizardInfo = WizardInfo()
    for (key, value) in data.tableVal.pairs():
      wizard.fields[key] = value.stringVal
    wizardLookup[wizardName] = wizard

proc getWizardByName*(name: string): WizardInfo =
  if wizardLookup.hasKey(name):
    return wizardLookup[name]
  return nil

when isMainModule:
  loadWizardInfo("./wizards.toml")
  echo getWizardByName("Prestige").fields["wand"]
  echo getWizardByName("f").fields["house"]

