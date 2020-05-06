#
#
# NIM port of General Purpose Goal Oriented Action Planning
# https://github.com/stolk/GPGOAP
#
# Copyright 2020 Joris Bontje
# Copyright 2012 Abraham T. Stolk
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
#

import algorithm
import bitops
import hashes
import heapqueue
import strformat
import strutils
import tables

const MAXATOMS = 64
const MAXACTIONS = 64

type
    WorldState* = object
        values: int64
        dontcare: int64

    ActionPlanner* = ref object
        atm_names: array[0..MAXATOMS, string]
        numatoms: int

        act_names: array[0..MAXACTIONS, string]
        act_pre: array[0..MAXACTIONS, WorldState]
        act_pst: array[0..MAXACTIONS, WorldState]
        act_costs: array[0..MAXACTIONS, int]
        numactions: int

    PriorityNode = object
        node: WorldState
        priority: int

    Transition* = object
        parent: WorldState
        node*: WorldState
        action*: string
        cost: int

    Plan* = object
        cost*: int
        path*: seq[Transition]

proc hash(x: WorldState): Hash =
    var h: Hash = 0
    h = h !& hash(x.values)
    h = h !& hash(x.dontcare)
    result = !$h

proc `<`(a, b: PriorityNode): bool = a.priority < b.priority

proc initWorldState*(): WorldState =
    result = WorldState(values: 0, dontcare: -1)

proc newActionPlanner*(): ActionPlanner =
    result = ActionPlanner()
    for i in 0..<MAXACTIONS:
        result.act_pre[i] = initWorldState()
        result.act_pst[i] = initWorldState()

proc idx_for_atomname(ap: ActionPlanner, atomname: string): int =
    var idx = 0
    for idx in 0..<ap.numatoms:
        if ap.atm_names[idx] == atomname: return idx
    idx = ap.numatoms
    if idx < MAXATOMS:
        ap.atm_names[idx] = atomname
        ap.numatoms += 1
        return idx

    return -1

proc idx_for_actionname(ap: ActionPlanner, actionname: string): int =
    var idx = 0
    for idx in 0..<ap.numactions:
        if ap.act_names[idx] == actionname: return idx
    idx = ap.numactions
    if idx < MAXACTIONS:
        ap.act_names[idx] = actionname
        ap.act_costs[idx] = 1
        ap.numactions += 1
        return idx

    return -1

proc goap_worldstate_set*(ap: ActionPlanner, ws: var WorldState, atomname: string, value: bool) =
    let idx = idx_for_atomname(ap, atomname)
    if (idx == -1):
        raise newException(ValueError, "No free index for atom")
    if value:
        setBit(ws.values, idx)
    else:
        clearBit(ws.values, idx)
    clearBit(ws.dontcare, idx)

proc goap_set_pre*(ap: ActionPlanner, actionname: string, atomname: string, value: bool) =
    let actidx = idx_for_actionname(ap, actionname)
    let atmidx = idx_for_atomname(ap, atomname)
    if (actidx == -1 or atmidx == -1):
        raise newException(ValueError, "No free index for action or atom")
    goap_worldstate_set(ap, ap.act_pre[actidx], atomname, value)

proc goap_set_pst*(ap: ActionPlanner, actionname: string, atomname: string, value: bool) =
    let actidx = idx_for_actionname(ap, actionname)
    let atmidx = idx_for_atomname(ap, atomname)
    if (actidx == -1 or atmidx == -1):
        raise newException(ValueError, "No free index for action or atom")
    goap_worldstate_set(ap, ap.act_pst[actidx], atomname, value)

proc goap_set_cost*(ap: ActionPlanner, actionname: string, cost: int) =
    let actidx = idx_for_actionname(ap, actionname)
    if (actidx == -1):
        raise newException(ValueError, "No free index for action")
    ap.act_costs[actidx] = cost

proc goap_worldstate_description*(ap: ActionPlanner, ws: WorldState): string =
    for i in 0..<MAXATOMS:
        if not testBit(ws.dontcare, i):
            if testBit(ws.values, i):
                result &= toUpperAscii(ap.atm_names[i]) & ","
            else:
                result &= ap.atm_names[i] & ","

proc goap_description*(ap: ActionPlanner): string =
    for a in 0..<ap.numactions:
        result &= &"{ap.act_names[a]}:\n"

        let pre = ap.act_pre[a]
        let pst = ap.act_pst[a]
        for i in 0..<MAXATOMS:
            if not testBit(pre.dontcare, i):
                let v = testBit(pre.values, i)
                result &= &"  {ap.atm_names[i]}=={int(v)}\n"
        for i in 0..<MAXATOMS:
            if not testBit(pst.dontcare, i):
                let v = testBit(pst.values, i)
                result &= &"  {ap.atm_names[i]}:={int(v)}\n"

proc goap_do_action(ap: ActionPlanner, actionnr: int, fr: WorldState): WorldState =
    let pst = ap.act_pst[actionnr]
    let unaffected = pst.dontcare
    let affected = bitnot(unaffected)

    result.values = bitor(bitand(fr.values, unaffected), bitand(pst.values, affected))
    result.dontcare = bitand(fr.dontcare, pst.dontcare)

proc goap_get_possible_state_transitions(ap: ActionPlanner, fr: WorldState): seq[Transition] =
    for i in 0..<ap.numactions:
        let pre = ap.act_pre[i]
        let care = bitnot(pre.dontcare)
        let met = bitand(pre.values, care) == bitand(fr.values, care)
        if met:
            result.add(
                Transition(
                    parent: fr,
                    node: goap_do_action(ap, i, fr),
                    action: ap.act_names[i],
                    cost: ap.act_costs[i]))

# This is our heuristic: estimate for remaining distance is the nr of mismatched atoms that matter.
proc heuristic(fr: WorldState, to: WorldState): int =
    let care = bitnot(to.dontcare)
    let diff = bitxor(bitand(fr.values, care), bitand(to.values, care))
    return countSetBits(diff)

proc match(fr: WorldState, to: WorldState): bool =
    let care = bitnot(to.dontcare)
    result = bitand(fr.values, care) == bitand(to.values, care)

proc reconstruct_path(ap: ActionPlanner, came_from: TableRef[WorldState, Transition], start: WorldState, goal: WorldState): Plan =
    var current = goal
    while current != start:
        result.cost += came_from[current].cost
        result.path.add(came_from[current])
        current = came_from[current].parent
    result.path.reverse()

proc astar_plan*(ap: ActionPlanner, start: WorldState, goal: WorldState): Plan =
    var frontier = initHeapQueue[PriorityNode]()
    frontier.push(PriorityNode(node: start, priority: 0))
    var came_from = newTable[WorldState, Transition]()
    var cost_so_far = newTable[WorldState, int]()
    cost_so_far[start] = 0

    while len(frontier) > 0:
        let current = frontier.pop().node

        if match(current, goal):
            return reconstruct_path(ap, came_from, start, current)

        for transition in goap_get_possible_state_transitions(ap, current):
            let next = transition.node
            let new_cost = cost_so_far[current] + transition.cost
            if next notin cost_so_far or new_cost < cost_so_far[next]:
                cost_so_far[next] = new_cost
                let priority = new_cost + heuristic(goal, next)
                frontier.push(PriorityNode(node: next, priority: priority))
                came_from[next] = transition
