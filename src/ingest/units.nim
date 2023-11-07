type
  UnitKind* = enum
    None
    Custom
    
    KiloGram = "Kg"

    MilliLitre = "ml"
    Litre = "L"


    MilliMetre = "mm"
    CentiMetre = "cm"
    Metre = "m"
    KiloMetre = "Km"
    
    Lb = "lb"

    Inch = "\""

    Foot = "'"

  Unit* = object
    case kind*: UnitKind
    of Custom:
      unit*: string
    else: discard


proc `$`*(unit: Unit): string =
  case unit.kind
  of Custom:
    unit.unit
  else:
    $unit.kind

