extends "res://scripts/tile.gd"

@onready var player:Player = GlobalVars.player
var popUpPreload = preload("res://scenes/pop_up.tscn")

var level = 1
var range = 46

var cropType = "default"


var priceCounts: Dictionary = {#count of all crops added to it, to be returned when destroyed
	"wheat": 0,
	"corn": 0,
	"bamboo": 0,
	"berry": 0,
	"onion": 0,
	"pepper": 0,
	"flower": 0
	
}

var seedPrices = {
	"wheat": 10,
	"corn": 10,
	"bamboo": 10,
	"berry": 10,
	"onion": 10,
	"flower": 10,
	"pepper": 10
}
var upgradePrices = {
	"wheat": 20,
	"corn": 20,
	"bamboo": 30,
	"berry": 10,
	"onion": 20,
	"pepper": 10,
	"flower": 20,
}

var sound = "res://sounds/metal_sound.mp3"
var tileState = ["level1","level2","level3"]

var textureRegions = {
	"level1": Rect2(16, 112, 16, 16),
	"level2": Rect2(32, 112, 16, 16),
	"level3": Rect2(48, 112, 16, 16),
}

var level1TextureRegions = {
	"default": 	Rect2(500, 0, 16, 16),
	"corn":Rect2(112, 0, 16, 16),
	"wheat":Rect2(96, 0, 16, 16),
	"bamboo": Rect2(128, 0, 16, 16),
	"berry": Rect2(144, 0, 16, 16),
	"onion": Rect2(160, 0, 16, 16),
	"flower": Rect2(176, 0, 16, 16),
	"pepper": Rect2(190, 0, 16, 16)
}

var level3TextureRegions = {
	"corn":Rect2(224, 16, 16, 16),
	"wheat":Rect2(240, 16, 16, 16),
	"bamboo": Rect2(208, 16, 16, 16),
	"berry": Rect2(190, 16, 16, 16),
	"onion": Rect2(176, 16, 16, 16),
	"flower": Rect2(176, 32, 16, 16),
	"pepper": Rect2(190, 32, 16, 16)
}

var currentTextureRegions: Dictionary



func _ready() -> void:
	currentTextureRegions = level1TextureRegions
	add_to_group("autoFarmerTiles")
	sprite = $Sprite 
	usesBlending = false
	tileType = "autoFarmTile"
	updateTexture()
	onStartLoad()

func getData():
	var nodeData = {}
	nodeData["group"] = "autoFarmerTiles"
	nodeData["position"] = position
	nodeData["level"] = level
	nodeData["cropType"] = cropType
	nodeData["upgradePrices"] = upgradePrices
	return nodeData

func updateTexture(): 
	var currentState = tileState[stateIndex] #Base Texture
	if currentState in textureRegions:
		var atlas = AtlasTexture.new()
		atlas.atlas = atlasTexture
		atlas.region = textureRegions[currentState]
		sprite.texture = atlas
	
	if cropType in currentTextureRegions: #Crop Texture
		var CropAtlas = AtlasTexture.new()
		CropAtlas.atlas = atlasTexture
		CropAtlas.region = currentTextureRegions[cropType]
		$cropTexture.texture = CropAtlas
	manageBlending()


func upgrade():
	if cropType == "default": #if crop not set
		return
		
	#if player.inventory[cropType] < upgradePrices[cropType]: #if player can afford it
		#return
	if player.inventory["berry"] < upgradePrices[cropType]: #if player can afford it TESTING CHANGE
		return
		
	if level == 4: #max lvl
		return
	
	level+=1 
	
	player.recieve("berry", -upgradePrices[cropType]) #TESTING CHANGE
	
	priceCounts[cropType] += upgradePrices[cropType]
	upgradePrices[cropType] *= 2  #increases price on each upgrade
	upgradePrices[cropType] = int(upgradePrices[cropType]) #rounds price
	
	
	
	if level == 2: #set texture to red and increase range
		stateIndex = 1
		range = 55
		var popUp:PopUp = popUpPreload.instantiate(); player.add_child(popUp)
		popUp.setText("Level 2: Range Increased")
	if level == 3: #can seed
		currentTextureRegions = level3TextureRegions #set to seeded
		var popUp:PopUp = popUpPreload.instantiate(); player.add_child(popUp)
		popUp.setText("Level 3: Can seed crops")
	if level == 4: #set texture to purple and faster activation
		$ActivationTimer.wait_time = 8
		stateIndex = 2
		var popUp:PopUp = popUpPreload.instantiate(); player.add_child(popUp)
		popUp.setText("Level 4: Speed Increased")
	updateTexture()
	SoundManager.play_sound("res://sounds/metal_sound.mp3",get_parent().position)

func setCrop(newCrop):
	if player.inventory[newCrop] < seedPrices[newCrop]:
		return
	if cropType == newCrop or cropType != "default":
		return
	
	
	player.recieve(newCrop, -seedPrices[newCrop])
	cropType = newCrop
	priceCounts[newCrop] += seedPrices[newCrop]
	updateTexture()


func harvestFarmTiles():
	for tile in get_tree().get_nodes_in_group("farmTiles"):
		if tile.cropType == cropType:
			if position.distance_to(tile.position) <= range:  #44 makes circle  46 makes square
				if tile.harvestable:
					tile.harvestCrop()

func plantFarmTiles():
	for tile in get_tree().get_nodes_in_group("farmTiles"):
		if tile.cropType == cropType:
			if position.distance_to(tile.position) <= range:  #44 makes circle  46 makes square
				if tile.tileState[tile.stateIndex] == "fertile" and tile.cropType != "default":
					tile.seedCrop()

func activate():
	$AnimationPlayer.play("activate")
	harvestFarmTiles()
	if level >= 3:
		plantFarmTiles()


func _on_activation_timer_timeout() -> void:
	activate()

func onStartLoad():
	match level:
		1:
			stateIndex = 0
		2:
			stateIndex = 1
			range = 55
		3:
			currentTextureRegions = level3TextureRegions #set to seeded
		4:
			stateIndex = 2
			$ActivationTimer.wait_time = 5
	
	updateTexture()
