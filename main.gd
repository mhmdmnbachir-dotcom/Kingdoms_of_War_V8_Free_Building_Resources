extends Node3D

# Kingdoms of War V8 - lightweight, generated 3D RTS prototype.
# Touch a blue soldier to select; tap ground to move. Use buttons to gather/build/train.
var camera: Camera3D
var ui_label: Label
var resource_label: Label
var selected_unit: Node3D
var units: Array[Node3D] = []
var buildings: Array[Node3D] = []
var resource_nodes: Array[Node3D] = []
var wood := 80
var stone := 50
var gold := 40
var build_mode := ""
var game_over := false
var human_base: Node3D
var orc_base: Node3D
var next_unit_id := 0
const HUMAN := Color(0.16, 0.42, 0.95)
const ORC := Color(0.72, 0.16, 0.12)
const GRASS := Color(0.25, 0.45, 0.22)
const WOOD := Color(0.36, 0.21, 0.10)
const STONE := Color(0.40, 0.42, 0.43)
const GOLD := Color(0.95, 0.68, 0.10)

func _ready() -> void:
    _make_world()
    _make_camera()
    _make_factions()
    _make_resources()
    _make_ui()
    _refresh_ui()

func _mat(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 1.0
    return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, label: String = "Block") -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.position = pos
    n.material_override = _mat(c)
    parent.add_child(n)
    return n

func _make_world() -> void:
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(46, 34)
    ground.mesh = plane
    ground.material_override = _mat(GRASS)
    ground.position.y = -0.15
    add_child(ground)
    _box(self, Vector3(4.5, 0.04, 34), Vector3(0, -0.07, 0), Color(0.08, 0.36, 0.67), "River")
    _box(self, Vector3(5.0, 0.18, 5.4), Vector3(0, 0.03, 0), WOOD, "Bridge")
    for i in range(8):
        _box(self, Vector3(4.9, 0.12, 0.55), Vector3(0, 0.15, -2.0 + i * 0.55), Color(0.48, 0.29, 0.13), "BridgePlank")
    for p in [Vector3(-17,0,-10),Vector3(-14,0,11),Vector3(-9,0,13),Vector3(15,0,-11),Vector3(18,0,9),Vector3(10,0,13),Vector3(4,0,-13),Vector3(-4,0,12)]:
        _make_tree(p)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55, -25, 0)
    light.light_energy = 1.1
    add_child(light)
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.72, 0.78, 0.82)
    e.ambient_light_energy = 0.65
    env.environment = e
    add_child(env)

func _make_tree(p: Vector3) -> void:
    var root := Node3D.new()
    root.position = p
    add_child(root)
    _box(root, Vector3(0.35, 1.3, 0.35), Vector3(0,0.65,0), WOOD, "Trunk")
    var crown := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.85
    mesh.height = 1.7
    crown.mesh = mesh
    crown.position.y = 1.7
    crown.material_override = _mat(Color(0.10,0.29,0.12))
    root.add_child(crown)

func _make_camera() -> void:
    camera = Camera3D.new()
    camera.position = Vector3(0, 29, 25)
    camera.rotation_degrees = Vector3(-49, 0, 0)
    camera.fov = 52
    camera.current = true
    add_child(camera)

func _make_factions() -> void:
    human_base = _make_base(Vector3(-10,0,-3), HUMAN, "Human Citadel", false)
    orc_base = _make_base(Vector3(10,0,3), ORC, "Orc Stronghold", true)
    for p in [Vector3(-8,0,0),Vector3(-12,0,1),Vector3(-7,0,-5),Vector3(8,0,1),Vector3(12,0,5),Vector3(7,0,6)]:
        _make_unit(p, ORC if p.x > 0 else HUMAN, p.x > 0)

func _make_base(p: Vector3, color: Color, label: String, enemy: bool) -> Node3D:
    var root := Node3D.new()
    root.name = "OrcStronghold" if enemy else "HumanCitadel"
    root.position = p
    root.set_meta("is_building", true)
    root.set_meta("is_enemy", enemy)
    root.set_meta("building_type", "Keep")
    root.set_meta("health", 600.0)
    root.set_meta("max_health", 600.0)
    root.set_meta("label", label)
    add_child(root)
    _box(root, Vector3(3.8,2.4,3.8), Vector3(0,1.2,0), color.darkened(0.2), "KeepWalls")
    _box(root, Vector3(4.2,0.45,4.2), Vector3(0,2.55,0), WOOD if not enemy else STONE, "KeepRoof")
    for x in [-1.5,1.5]:
        for z in [-1.5,1.5]:
            _box(root, Vector3(0.65,3.0,0.65), Vector3(x,1.5,z), color, "Tower")
    buildings.append(root)
    return root

func _make_resources() -> void:
    for p in [Vector3(-16,0,-2),Vector3(-15,0,5),Vector3(-5,0,8),Vector3(15,0,-4),Vector3(16,0,7)]:
        _make_resource(p, "Wood", Color(0.18,0.42,0.12))
    for p in [Vector3(-4,0,-9),Vector3(5,0,10),Vector3(17,0,-9)]:
        _make_resource(p, "Stone", STONE)
    for p in [Vector3(-18,0,1),Vector3(18,0,2)]:
        _make_resource(p, "Gold", GOLD)

func _make_resource(p: Vector3, kind: String, color: Color) -> void:
    var root := Node3D.new()
    root.position = p
    root.set_meta("resource_type", kind)
    root.set_meta("amount", 500)
    root.set_meta("is_resource", true)
    add_child(root)
    if kind == "Wood":
        _box(root, Vector3(0.65,1.5,0.65), Vector3(0,0.75,0), WOOD, "Log")
        var crown := MeshInstance3D.new()
        var s := SphereMesh.new()
        s.radius = 0.9
        s.height = 1.8
        crown.mesh = s
        crown.position.y = 1.8
        crown.material_override = _mat(color)
        root.add_child(crown)
    else:
        _box(root, Vector3(1.2,0.8,1.0), Vector3(0,0.4,0), color, kind)
        _box(root, Vector3(0.7,0.45,0.6), Vector3(0.1,0.95,0.0), color.lightened(0.2), kind + "Chunk")
    resource_nodes.append(root)

func _make_unit(p: Vector3, color: Color, enemy: bool, unit_type: String = "Soldier") -> Node3D:
    next_unit_id += 1
    var u := Node3D.new()
    u.name = ("Orc" if enemy else "Human") + str(next_unit_id)
    u.position = p
    u.set_meta("is_enemy", enemy)
    u.set_meta("unit_type", unit_type)
    u.set_meta("destination", p)
    u.set_meta("speed", 2.8 if unit_type == "Worker" else (2.5 if enemy else 3.2))
    u.set_meta("health", 70.0 if unit_type == "Worker" else 100.0)
    u.set_meta("attack_timer", 0.0)
    u.set_meta("damage", 12.0 if unit_type == "Worker" else 20.0)
    add_child(u)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.34 if unit_type != "Worker" else 0.30
    capsule.height = 1.25
    body.mesh = capsule
    body.position.y = 0.63
    body.material_override = _mat(color)
    u.add_child(body)
    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.23
    sphere.height = 0.46
    head.mesh = sphere
    head.position.y = 1.38
    head.material_override = _mat(Color(0.82,0.66,0.5) if not enemy else Color(0.25,0.48,0.16))
    u.add_child(head)
    _box(u, Vector3(0.10,0.7,0.1), Vector3(0.32,0.7,0), GOLD if unit_type == "Soldier" else WOOD, "WeaponOrTool")
    units.append(u)
    return u

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(10,10)
    panel.custom_minimum_size = Vector2(330, 250)
    layer.add_child(panel)
    var col := VBoxContainer.new()
    panel.add_child(col)
    resource_label = Label.new()
    resource_label.text = "Wood 80 | Stone 50 | Gold 40"
    resource_label.add_theme_font_size_override("font_size", 18)
    col.add_child(resource_label)
    ui_label = Label.new()
    ui_label.text = "KINGDOMS OF WAR V8\nSelect a blue unit, then tap ground to move."
    ui_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    ui_label.custom_minimum_size.y = 46
    col.add_child(ui_label)
    _add_button(col, "GATHER RESOURCES (+20 wood, +10 stone)", _gather)
    _add_button(col, "BUILD FARM (30 wood, 10 stone)", _build_farm)
    _add_button(col, "BUILD BARRACKS (50 wood, 30 stone)", _build_barracks)
    _add_button(col, "TRAIN SOLDIER (20 gold, 10 food)", _train_soldier)
    _add_button(col, "TRAIN WORKER (15 gold)", _train_worker)
    _add_button(col, "CANCEL BUILD / DESELECT", _cancel_action)

func _add_button(parent: Node, label: String, cb: Callable) -> void:
    var b := Button.new()
    b.text = label
    b.custom_minimum_size = Vector2(300, 38)
    b.pressed.connect(cb)
    parent.add_child(b)

func _gather() -> void:
    wood += 20
    stone += 10
    gold += 5
    _refresh_ui()
    ui_label.text = "Resources collected. Upgrade your base or train units."

func _build_farm() -> void:
    if wood < 30 or stone < 10:
        ui_label.text = "Not enough resources: Farm costs 30 wood and 10 stone."
        return
    wood -= 30
    stone -= 10
    _make_building(Vector3(-7 + randf_range(-2,2),0,5 + randf_range(-1,3)), "Farm", Color(0.65,0.52,0.24), false)
    ui_label.text = "Farm built! Tap GATHER to simulate collecting food and resources."
    _refresh_ui()

func _build_barracks() -> void:
    if wood < 50 or stone < 30:
        ui_label.text = "Not enough resources: Barracks costs 50 wood and 30 stone."
        return
    wood -= 50
    stone -= 30
    _make_building(Vector3(-13,0,-7), "Barracks", Color(0.43,0.38,0.29), false)
    ui_label.text = "Barracks built! You can now train soldiers."
    _refresh_ui()

func _train_soldier() -> void:
    if gold < 20:
        ui_label.text = "Need 20 gold to train a soldier. Gather resources first."
        return
    gold -= 20
    _make_unit(Vector3(-9 + randf_range(-1,1),0,-1 + randf_range(-1,1)), HUMAN, false, "Soldier")
    ui_label.text = "A new soldier joined your army. Select and command them."
    _refresh_ui()

func _train_worker() -> void:
    if gold < 15:
        ui_label.text = "Need 15 gold to train a worker."
        return
    gold -= 15
    _make_unit(Vector3(-11 + randf_range(-1,1),0,1 + randf_range(-1,1)), Color(0.25,0.75,0.95), false, "Worker")
    ui_label.text = "Worker trained. Workers can be selected and moved; resource gathering is currently button-based."
    _refresh_ui()

func _make_building(p: Vector3, kind: String, color: Color, enemy: bool) -> void:
    var root := Node3D.new()
    root.name = kind.replace(" ", "") + str(buildings.size())
    root.position = p
    root.set_meta("is_building", true)
    root.set_meta("is_enemy", enemy)
    root.set_meta("building_type", kind)
    root.set_meta("health", 180.0)
    root.set_meta("max_health", 180.0)
    add_child(root)
    _box(root, Vector3(2.0,1.4,2.0), Vector3(0,0.7,0), color, "BuildingBody")
    _box(root, Vector3(2.3,0.3,2.3), Vector3(0,1.55,0), WOOD, "Roof")
    buildings.append(root)

func _cancel_action() -> void:
    selected_unit = null
    build_mode = ""
    ui_label.text = "Deselected. Tap a blue unit, then tap ground to move."

func _unhandled_input(event: InputEvent) -> void:
    var pressed := false
    var screen_pos := Vector2.ZERO
    if event is InputEventScreenTouch and event.pressed:
        pressed = true
        screen_pos = event.position
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        pressed = true
        screen_pos = event.position
    if not pressed or screen_pos.x < 350 and screen_pos.y < 300:
        return
    var origin := camera.project_ray_origin(screen_pos)
    var dir := camera.project_ray_normal(screen_pos)
    if abs(dir.y) < 0.001:
        return
    var dist := -origin.y / dir.y
    if dist < 0:
        return
    var hit := origin + dir * dist
    hit.y = 0
    _world_tap(hit)

func _world_tap(hit: Vector3) -> void:
    var nearest: Node3D = null
    var best := 1.5
    for u in units:
        if not is_instance_valid(u):
            continue
        var d := Vector2(u.global_position.x-hit.x, u.global_position.z-hit.z).length()
        if d < best:
            best = d
            nearest = u
    if nearest != null:
        if not bool(nearest.get_meta("is_enemy")):
            selected_unit = nearest
            ui_label.text = "Selected %s. Tap the ground to move." % str(nearest.get_meta("unit_type"))
        else:
            ui_label.text = "Enemy unit. Move your soldiers close to attack automatically."
        return
    if selected_unit != null and is_instance_valid(selected_unit):
        selected_unit.set_meta("destination", Vector3(clamp(hit.x,-21,21),0,clamp(hit.z,-15,15)))
        ui_label.text = "Unit moving. Units automatically fight nearby enemies."

func _process(delta: float) -> void:
    if game_over:
        return
    for enemy in units.duplicate():
        if not is_instance_valid(enemy) or not bool(enemy.get_meta("is_enemy")):
            continue
        var closest: Node3D = null
        var closest_dist := 6.0
        for human in units:
            if not is_instance_valid(human) or bool(human.get_meta("is_enemy")):
                continue
            var d := Vector2(enemy.position.x-human.position.x, enemy.position.z-human.position.z).length()
            if d < closest_dist:
                closest_dist = d
                closest = human
        if closest != null:
            enemy.set_meta("destination", closest.global_position)
    for unit in units.duplicate():
        if not is_instance_valid(unit):
            continue
        var dest: Vector3 = unit.get_meta("destination")
        var pos := unit.global_position
        var flat := Vector3(dest.x,pos.y,dest.z)
        if pos.distance_to(flat) > 0.12:
            unit.global_position = pos.move_toward(flat,float(unit.get_meta("speed"))*delta)
        var timer := float(unit.get_meta("attack_timer"))-delta
        if timer > 0:
            unit.set_meta("attack_timer",timer)
            continue
        var target: Node3D = null
        var best := 1.45
        for other in units:
            if not is_instance_valid(other) or other == unit or bool(other.get_meta("is_enemy")) == bool(unit.get_meta("is_enemy")):
                continue
            var d := Vector2(unit.position.x-other.position.x,unit.position.z-other.position.z).length()
            if d < best:
                best = d
                target = other
        if target != null:
            target.set_meta("health",float(target.get_meta("health"))-float(unit.get_meta("damage")))
            unit.set_meta("attack_timer",0.85)
            if float(target.get_meta("health")) <= 0:
                var was_enemy := bool(target.get_meta("is_enemy"))
                units.erase(target)
                if selected_unit == target:
                    selected_unit = null
                target.queue_free()
                ui_label.text = "Enemy defeated!" if was_enemy else "A soldier has fallen."
            continue
        if not bool(unit.get_meta("is_enemy")) and str(unit.get_meta("unit_type")) == "Soldier":
            if is_instance_valid(orc_base):
                var dkeep := Vector2(unit.position.x-orc_base.position.x,unit.position.z-orc_base.position.z).length()
                if dkeep < 2.7:
                    orc_base.set_meta("health",float(orc_base.get_meta("health"))-float(unit.get_meta("damage"))*delta)
                    if float(orc_base.get_meta("health")) <= 0:
                        game_over = true
                        ui_label.text = "VICTORY! The Orc Stronghold has fallen."
                        return
    _refresh_ui()

func _refresh_ui() -> void:
    if is_instance_valid(resource_label):
        resource_label.text = "WOOD %d   STONE %d   GOLD %d\nArmy: %d" % [wood,stone,gold,units.filter(func(u): return is_instance_valid(u) and not bool(u.get_meta("is_enemy"))).size()]
