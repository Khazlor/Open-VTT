#Author: Vladimír Horák
#Desc:
#Script for controlling Campaign cards of Campaigns scene - selecting Campaign, signal for opening Campaign setting popup

extends Control
var campaign: Campaign_res
signal campaigncard_right_click(campaign, campaigncard)

# Called when the node enters the scene tree for the first time.
func _ready():
	$PanelContainer/Name.text = campaign.campaign_name
	$PanelContainer/MarginContainer/VBoxContainer/Players.text = "Players:"
	for player in campaign.players:
		$PanelContainer/MarginContainer/VBoxContainer/Players.text + "\n" + campaign.players
	$PanelContainer/MarginContainer/VBoxContainer/DM.text = "DM: " + campaign.DM_name
	$PanelContainer/MarginContainer/VBoxContainer/Desc.text = campaign.campaign_desc
	$PanelContainer/preview.texture = load(campaign.image)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_gui_input(event):
	if event.is_action_pressed("mouseleft"):
		Globals.campaign = campaign
		get_tree().change_scene_to_file("res://scenes/Maps.tscn")
	elif event.is_action_pressed("mouseright"):
		Globals.campaign = campaign
		emit_signal("campaigncard_right_click", campaign, self)
