extends Control

const CampaignCard = preload("res://componens/campaigncard.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	var save_dir = DirAccess.open("res://saves")
	if save_dir == null:
		return
	var dirs = save_dir.get_directories()
	for dir in dirs:
		var campaign = Campaign_res.new()
		campaign.load_campaign(dir)
		var campaigncard = CampaignCard.instantiate()
		campaigncard.campaign = campaign
		$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/CampaignGrid.add_child(campaigncard)
	
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
	
	var dir = DirAccess.open("res://saves")
	if dir == null:
		dir = DirAccess.open("res://")
		dir.make_dir("saves")
		dir.change_dir("saves")
	var i = 0
	var oldname = campaign.campaign_name
	while dir.make_dir(campaign.campaign_name) == Error.ERR_ALREADY_EXISTS:
		i += 1
		campaign.campaign_name = oldname + "_" + str(i)
	dir.change_dir(campaign.campaign_name)
	var campaigncard = CampaignCard.instantiate()
	campaigncard.campaign = campaign
	$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/CampaignGrid.add_child(campaigncard)
