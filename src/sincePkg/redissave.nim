## In-memory replacement for the original Redis-backed save module.
##
## The module name is preserved to minimize churn at call sites in since.nim,
## but state is now kept in a process-local `Table[string, string]` keyed by
## `gameId:turn`. `dropGame` is called from the `/end` handler to free memory
## when a game completes. This trades cross-restart persistence for zero
## external infrastructure (no Redis required to run a snake).

import algorithm, json, strformat, strutils, tables
import pathing

type GameData* = object
  state*: State
  target*: CoordinatePair
  myMove*: string
  path*: Path
  desc*: string
  victim*: string

proc cmp*(a, b: GameData): int =
  return cmp[int](a.state.turn, b.state.turn)

var store: Table[string, string]

proc createKey(gameId, turn: string): string =
  fmt"{gameId}:{turn}"

proc createKey(s: State): string =
  createKey(s.game.id, $s.turn)

proc compareKey(a, b: string): int =
  let
    aSp = a.split(":")
    bSp = b.split(":")

  return cmp[int](aSp[1].parseInt, bSp[1].parseInt)

proc saveTurn*(s: State, target: CoordinatePair, myMove: string, path: Path,
    desc, victim: string) =
  let toWrite = %* {
    "state": s,
    "target": target,
    "path": path,
    "myMove": myMove,
    "desc": desc,
    "victim": victim
  }

  store[s.createKey] = $toWrite

proc hasTurn*(gameId, turn: string): bool =
  store.hasKey(createKey(gameId, turn))

proc getGame*(gameId: string): JsonNode =
  result = newJArray()

  var keys: seq[string] = @[]
  for k in store.keys:
    if k.startsWith(gameId & ":"):
      keys.add k
  keys.sort compareKey
  for key in keys:
    result.add store[key].parseJson

proc getData*(gameId, turn: string): JsonNode =
  let key = createKey(gameId, turn)
  if not store.hasKey(key):
    return newJNull()
  store[key].parseJson

proc dropGame*(gameId: string) =
  var keys: seq[string] = @[]
  for k in store.keys:
    if k.startsWith(gameId & ":"):
      keys.add k
  for k in keys:
    store.del k
