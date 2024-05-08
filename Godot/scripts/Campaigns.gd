#Author: Vladimír Horák
#Desc:
#Script for controlling Campaign scene -- creating, editing, selecting Campaign

extends Control

const CampaignCard = preload("res://components/campaigncard.tscn")

@onready var popup = $PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/PopupPanel

var campaign: Campaign_res
var campaigncard

# Called when the node enters the scene tree for the first time.
func _ready():
	popup.transient = true
	popup.exclusive = true
	var save_dir = DirAccess.open(Globals.base_dir_path + "/saves/Campaigns")
	if save_dir == null:
		return
	var dirs = save_dir.get_directories()
	for dir in dirs:
		campaign = Campaign_res.new()
		campaign.load_campaign(dir)
		
		_add_campaigncard(campaign)
	
#	print(PersistentData)
#	for campaign in PersistentData.campaign_list:
#		var campaigncard = CampaignCard.instantiate()
#		campaigncard.campaign = campaign
#		$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/CampaignGrid.add_child(campaigncard)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_resized():
	var screensize = get_viewport().size
	$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/CampaignGrid.columns = screensize.x/400


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_new_map_pressed():
	var campaign = Campaign_res.new()
	
	if not DirAccess.dir_exists_absolute(Globals.base_dir_path + "/saves/Campaigns"):
		DirAccess.make_dir_recursive_absolute(Globals.base_dir_path + "/saves/Campaigns")
	var i = 0
	var oldname = campaign.campaign_name
	while DirAccess.dir_exists_absolute(Globals.base_dir_path + "/saves/Campaigns/" + campaign.campaign_name):
		i += 1
		campaign.campaign_name = oldname + "_" + str(i)
	DirAccess.make_dir_recursive_absolute(Globals.base_dir_path + "/saves/Campaigns/" + campaign.campaign_name)
	_add_campaigncard(campaign)
	
func _add_campaigncard(campaign: Campaign_res):
	campaigncard = CampaignCard.instantiate()
	campaigncard.campaign = campaign
	campaigncard.connect("campaigncard_right_click", _on_campaigncard_right_click)
	$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/CampaignGrid.add_child(campaigncard)
	
func _on_campaigncard_right_click(campaign: Campaign_res, campaigncard):
	self.campaign = campaign
	self.campaigncard = campaigncard
	
	popup.position = get_global_mouse_position()
	popup.get_node("VBoxContainer/CampaignName").text = campaign.campaign_name
	popup.get_node("VBoxContainer/CampaignDesc").text = campaign.campaign_desc
	popup.visible = true
	
	#keep popup in window
	if popup.position.x + popup.size.x > get_viewport().size.x:
		popup.position.x = get_viewport().size.x - popup.size.x
	if popup.position.y + popup.size.y > get_viewport().size.y:
		popup.position.y = get_viewport().size.y - popup.size.y
	
#apply changes in settings - right click on card
func _on_apply_button_pressed():
	#setting campaign_res
	var newname = popup.get_node("VBoxContainer/CampaignName").text
	if campaign.campaign_name != newname:
		var oldname = campaign.campaign_name
		campaign.campaign_name = newname
		var i = 0
		while DirAccess.dir_exists_absolute(Globals.base_dir_path + "/saves/Campaigns/" + campaign.campaign_name):
			i += 1
			campaign.campaign_name = newname + "_" + str(i)
		if DirAccess.rename_absolute(Globals.base_dir_path + "/saves/Campaigns/" + oldname, Globals.base_dir_path + "/saves/Campaigns/" + campaign.campaign_name) != Error.OK:
			campaign.campaign_name = oldname
	campaign.campaign_desc = popup.get_node("VBoxContainer/CampaignDesc").text
	
	#setting campaign_card
	campaigncard.get_node("PanelContainer/Name").text = campaign.campaign_name
	campaigncard.get_node("PanelContainer/MarginContainer/VBoxContainer/Desc").text = campaign.campaign_desc
	campaigncard.get_node("PanelContainer/preview").texture = Globals.load_texture(campaign.image)
	campaign.save_campaign()
	popup.hide()


func _on_cancel_button_pressed():
	popup.hide()


func _on_duplicate_button_pressed():
	var newcampaign = campaign.duplicate(true)
	var i = 0
	var oldname = newcampaign.campaign_name
	while DirAccess.dir_exists_absolute(Globals.base_dir_path + "/saves/Campaigns/" + campaign.campaign_name):
		i += 1
		newcampaign.campaign_name = oldname + "_" + str(i)
	newcampaign.save_map()
	
	_add_campaigncard(newcampaign)
	popup.hide()


func _on_delete_button_pressed():
	OS.move_to_trash(ProjectSettings.globalize_path(Globals.base_dir_path + "/saves/Campaigns/" + campaign.campaign_name))
#	DirAccess.remove_absolute(Globals.base_dir_path + "/saves/Campaigns/" + campaign.campaign_name)
	campaigncard.queue_free()
	campaign = null
	popup.hide()
	
