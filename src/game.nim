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

import strformat

import goap

proc main() =
    let ap = newActionPlanner()

    goap_set_pre(ap, "scout", "armedwithgun", true)
    goap_set_pst(ap, "scout", "enemyvisible", true)

    goap_set_pre(ap, "approach", "enemyvisible", true)
    goap_set_pst(ap, "approach", "nearenemy", true)

    goap_set_pre(ap, "aim", "enemyvisible", true)
    goap_set_pre(ap, "aim", "weaponloaded", true)
    goap_set_pst(ap, "aim", "enemylinedup", true)

    goap_set_pre(ap, "shoot", "enemylinedup", true)
    goap_set_pst(ap, "shoot", "enemyalive", false)

    goap_set_pre(ap, "load", "armedwithgun", true)
    goap_set_pst(ap, "load", "weaponloaded", true)

    goap_set_pre(ap, "detonatebomb", "armedwithbomb", true)
    goap_set_pre(ap, "detonatebomb", "nearenemy", true)
    goap_set_pst(ap, "detonatebomb", "alive", false)
    goap_set_pst(ap, "detonatebomb", "enemyalive", false)

    goap_set_pre(ap, "flee", "enemyvisible", true)
    goap_set_pst(ap, "flee", "nearenemy", false)

    echo goap_description(ap)

    var fr = initWorldState()
    goap_worldstate_set(ap, fr, "enemyvisible", false)
    goap_worldstate_set(ap, fr, "armedwithgun", true)
    goap_worldstate_set(ap, fr, "weaponloaded", false)
    goap_worldstate_set(ap, fr, "enemylinedup", false)
    goap_worldstate_set(ap, fr, "enemyalive", true)
    goap_worldstate_set(ap, fr, "armedwithbomb", true)
    goap_worldstate_set(ap, fr, "nearenemy", false)
    goap_worldstate_set(ap, fr, "alive", true)

    goap_set_cost(ap, "detonatebomb", 5)    # make suicide more expensive than shooting.

    var goal = initWorldState()
    goap_worldstate_set(ap, goal, "enemyalive", false)
    # goap_worldstate_set(ap, goal, "alive", true)     # add this to avoid suicide actions in plan.

    let plan = astar_plan(ap, fr, goal)
    echo fmt"plancost = {plan.cost}"
    echo fmt"                        {goap_worldstate_description(ap, fr)}"
    for idx, transition in plan.path:
        echo fmt"{idx}: {transition.action:<20} {goap_worldstate_description(ap, transition.node)}"

main()
