import asyncdispatch, jester, json, logging, os, random, strformat, strutils

import sincePkg/[base, pathing, redissave]

const
  apiVersion = "1"
  author = "Xe"
  snakeColor = "#FFD600"
  headType = "beluga"
  tailType = "skinny"

settings:
  bindAddr = getEnv("BIND_ADDR", "0.0.0.0")
  port = getEnv("PORT", "8000").parseInt.Port

routes:
  get "/":
    let info = %* {
      "apiversion": apiVersion,
      "author": author,
      "color": snakeColor,
      "head": headType,
      "tail": tailType,
      "version": getEnv("GIT_REV", "dev")
    }
    resp Http200, $info, "application/json"

  post "/start":
    let state = request.body.parseJson.to(State)
    info fmt"game {state.game.id}: starting"
    resp Http200, "OK", "text/plain"

  post "/move":
    try:
      let
        state = request.body.parseJson.to(State)
      var
        lastInfo: GameData
        target: CoordinatePair
        desc: string
        victim: string

      if state.turn != 0 and hasTurn(state.game.id, $(state.turn - 1)):
        lastInfo = getData(state.game.id, $(state.turn-1)).to(GameData)
        target = lastInfo.target
        desc = lastInfo.desc
        victim = lastInfo.victim
      else:
        let interm = state.findTarget
        target = interm.cp
        desc = interm.state
        victim = interm.victim

      case desc
      of "tail":
        target = state.you.tail
      of "hunting":
        var found = false
        for sn in state.board.snakes:
          if sn.id == victim:
            target = sn.head
            found = true
            break
        if not found:
          let interm = state.findTarget
          target = interm.cp
          desc = interm.state
          victim = interm.victim
      else: discard

      let source = state.you.head

      if source == target or state.board.isDeadly(target):
        let interm = state.findTarget
        target = interm.cp
        desc = interm.state

      var myPath = state.findPath(source, target)
      while myPath.len == 0:
        target = state.board.randomSafeTile
        desc = "random-fallback"
        myPath = state.findPath(source, target)

      var myMove: string
      if myPath.len >= 2:
        myMove = source -> myPath[1]
      else:
        debug fmt"can't find a path?"
        myMove = sample ["up", "left", "right", "down"]

      info fmt"game {state.game.id} turn {state.turn}: moving {myMove} to get to {target}"
      debug fmt"path: {myPath}"
      saveTurn(state, target, myMove, myPath, desc, victim)

      let ret = %* { "move": myMove }
      resp Http200, $ret, "application/json"
    except:
      info fmt"{getCurrentException().name}: {getCurrentExceptionMsg()}"
      info "random move"

      let ret = %* { "move": sample ["up", "left", "right", "down"] }
      resp Http200, $ret, "application/json"

  post "/end":
    let
      state = request.body.parseJson.to(State)
      didIWin = state.you.health > 0 and state.board.snakes.len == 1 and
                state.board.snakes[0].id == state.you.id

    info fmt"game {state.game.id} turn {state.turn}: win: {didIWin}"
    dropGame(state.game.id)

    resp Http200, "OK", "text/plain"

  get "/inspect/@gameId":
    resp Http200, pretty getGame(@"gameId"), "application/json"

  get "/inspect/@gameId/@turn":
    resp Http200, pretty getData(@"gameId", @"turn"), "application/json"
