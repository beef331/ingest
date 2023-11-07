import owlkettle, owlkettle/adw, slicerator
import frosty/streams as frst
import std/[times, paths, appdirs, dirs, streams, parseutils, files, strformat]
import ingest/[confirmation, trackdata, units, adddialog]

let 
  confDir = getConfigDir() / Path"ingest"
  delDir = confDir / Path"deleted"

discard existsOrCreateDir(confDir)
discard existsOrCreateDir(delDir)

viewable App:
  tracked: seq[Tracked]
  selected: int
  loaded: bool
  input: string

iterator revPairs[T](oa: openArray[T]): (int, T) =
  for i in countdown(oa.high, 0):
    yield (i, oa[i])

proc myDateFormat(t: DateTime): string = t.format("ddd hh:mmtt dd-MMM-yyyy")

proc format(entry: TrackedEntry, unit: Unit, isInterval: bool): string =
  result = fmt"""{entry.amount}{unit} @ {entry.date.myDateformat()}"""
  if isInterval:
    result = fmt"""<b>{result}</b>"""


method view(app: AppState): Widget =
  if not app.loaded:
    var lastViewed = ""
    for path in confDir.walkDir:
      if path.kind == pcFile:
        if path.path.extractFilename().string != "ingest.config":
          try:
            let file = openFileStream(path.path.string, fmRead)
            defer: file.close()
            if path.path.extractFilename().string != "ingest.config":
              try:
                app.tracked.add Tracked()
                thaw(file, app.tracked[^1])
              except CatchableError as e:
                app.tracked.setLen(app.tracked.high)
                echo fmt"Failed reading '{path.path.string}': {e.msg}"
            else:
              file.thaw(app.selected)
          except CatchableError as e:
            echo e.msg
        else:
          lastViewed = path.path.string.readFile()
    for i, tracked in app.tracked.pairs:
      if tracked.name == lastViewed:
        app.selected = i
        break
  
    app.loaded = true


  result = gui:
    Window:
      title = "Ingest"
      HeaderBar {.addTitlebar.}:
        MenuButton {.addRight.}:
          icon = "open-menu"
          style = [ButtonFlat]
          
          PopoverMenu:
            Box {.name: "main".}:
              orient = OrientY
              margin = 4
              spacing = 3
              
              if app.selected >= 0:
                for i, tracked in app.tracked:
                  Box:
                    orient = OrientX
                    ModelButton:
                      sensitive = app.selected != i
                      text = tracked.name
                      proc clicked() =
                        app.selected = i

                    Button {.expand: false.}:
                      icon = "list-remove-symbolic"
                      style = [ButtonDestructive]
                      proc clicked() =
                        let (res, _) = app.open:
                          gui:
                            ConfirmationDialog:
                              message = "Are you sure you want to remove: " & tracked.name & " ?"
                              confirm =  ("Delete", ButtonDestructive)
                              decline = ("Cancel", ButtonFlat)

                        if res.kind == DialogAccept:
                          try:
                            moveFile(confDir / Path(tracked.name), delDir / Path(tracked.name))
                          except CatchableError as e:
                            echo e.msg
                          app.tracked.delete(i)
                          if i >= app.selected:
                            dec app.selected
                            if app.selected == -1:
                              app.selected = app.tracked.high
                          app.selected = clamp(app.selected, -1, app.tracked.high)


              Button:
                icon = "list-add-symbolic"
                style = [ButtonFlat]
                
                proc clicked() =
                  let (res, state) = app.open(gui(AddDialog()))
                  if res.kind == DialogAccept:
                      let tracked = AddDialogState(state).tracked
                      if tracked.name.len > 0:
                        try:
                          app.tracked.add tracked
                          app.tracked[^1].save(confDir)
                          app.selected = app.tracked.high

                        except CatchableError as e:
                          echo e.msg
      Box:
        orient = OrientY
        spacing = 10
        margin = 3
        if app.selected > -1 and app.tracked.len > 0:
          Frame:
            ScrolledWindow:
              ListBox:
                for i, entry in app.tracked[app.selected].entries.revPairs:
                  Box:
                    orient = OrientX
                    Label:
                      useMarkup = entry.isInterval
                      xAlign = 0
                      text =
                        if app.tracked[app.selected].kind == Quantity:
                          entry.format(app.tracked[app.selected].unit, entry.isInterval)
                        else:
                          entry.date.myDateFormat() 

                    Button {.expand: false}:
                      icon = "list-remove-symbolic"
                      style = [ButtonDestructive]
                      proc clicked() =
                        template tracked: untyped = app.tracked[app.selected]
                        let (res, _) = app.open:
                          gui:
                            ConfirmationDialog:
                              message = "Are you sure you want to delete the entry?"
                              confirm = ("Yes", ButtonDestructive)
                              decline = ("Cancel", ButtonFlat)
                        if res.kind == DialogAccept:
                          tracked.entries.delete(i)
                          for ind, entry in tracked.entries.toOpenArray(i, tracked.entries.high).mpairs:
                            if entry.isInterval:
                              var theInd = ind - 1 + i
                              var sum = 0d
                              while theInd >= 0 and not tracked.entries[theInd].isInterval:
                                sum += tracked.entries[theInd].amount
                                dec theInd
                              entry.amount = sum
                              break
                          tracked.save(confDir)
                          if app.selected == -1:
                            app.selected = 0
                          discard app.redraw()
                          return

          Box {.expand: false}:
            orient = OrientX
            if app.tracked[app.selected].kind == Quantity:
              Entry:
                placeholder = "Value"
                text = app.input
                proc changed(s: string) =
                  var f: float
                  let parsed = s.parseFloat(f)
                  if parsed == s.len:
                    app.input = s

                proc activate() =
                  var f: float
                  let parsed = app.input.parseFloat(f)
                  if parsed == app.input.len and f > 0:
                    app.tracked[app.selected].entries.add TrackedEntry(amount: f, date: now())
                    app.tracked[app.selected].save(confDir)
                  app.input = ""

            Button {.expand: false.}:
              text = "Add Interval"
              style = [ButtonSuggested]
              proc clicked() =
                var sum = 0d
                for x in app.tracked[app.selected].entries.revItems:
                  if x.isInterval: break
                  sum += x.amount
                app.tracked[app.selected].entries.add TrackedEntry(amount: sum, isInterval: true, date: now())
                app.tracked[app.selected].save(confDir)
                app.input = ""
      proc close() =
        if app.selected >= 0:
          writeFile(string(confDir / Path"ingest.config"), app.tracked[app.selected].name)

adw.brew(gui(App()))
