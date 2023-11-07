import units
import frosty/streams as frst
import std/[times, streams, paths]

type
  TrackerKind* = enum
    Quantity
    Interval
  TrackedEntry* = object
    amount*: float
    isInterval*: bool
    date*: DateTime

  Tracked* = object
    kind*: TrackerKind
    name*: string
    unit*: Unit
    entries*: seq[TrackedEntry]


proc save*(tracked: Tracked, confDir: Path) =
  let file = openFileStream(string(confDir / Path tracked.name), fmWrite)
  defer: file.close()
  file.freeze(tracked)
