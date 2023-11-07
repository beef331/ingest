import owlkettle
import std/[times, sequtils]
import "." / [units, trackdata]

viewable AddDialog:
  splitTime: Time
  tracked: Tracked

export AddDialog, AddDialogState

method view*(addDiag: AddDialogState): Widget =
  gui:
    Dialog:
      title = "Add New Tracker"
      defaultSize = (400, 0)
      Box:
        orient = OrientX
        Entry:
          text = addDiag.tracked.name
          placeholder = "New Tracker Name"
          
          proc changed(text: string) =
            addDiag.tracked.name = text

        DropDown:
          items = @[$TrackerKind.low, $TrackerKind.high] 
          selected = ord(addDiag.tracked.kind)
          showArrow = true
          tooltip = "Choose between Quantity or Interval. Quantity keeps track of numeric consumption. Interval only the time."
          proc select(item: int) =
            addDiag.tracked.kind = TrackerKind item

        if addDiag.tracked.kind == Quantity: 
          DropDown {.expand: false.}:
            items = toSeq(succ(None)..UnitKind.high).mapit($it)
            selected = ord(addDiag.tracked.unit.kind) - 1
            showArrow = true
            tooltip = "Specify the unit to use for tracked information."                
            proc select(item: int) =
              if item != -1:
                addDiag.tracked.unit = Unit(kind: UnitKind(item + 1))
          if addDiag.tracked.unit.kind == Custom:
            Entry:
              text = addDiag.tracked.unit.unit
              placeholder = "Unit"
              proc changed(text: string) =
                addDiag.tracked.unit.unit = text

      DialogButton {.addButton.}:
        text = "Add"
        style = [ButtonSuggested]
        res = DialogAccept
        #sensitive = addDiag.tracked.kind == Quantity or (addDiag.tracked.unit.kind != None and $addDiag.tracked.unit != "") # TODO: Implement this

      DialogButton {.addButton.}:
        text = "Cancel"
        style = [ButtonDestructive]
        res = DialogCancel

