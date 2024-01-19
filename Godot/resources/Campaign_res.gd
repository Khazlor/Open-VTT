#Author: Vladimír Horák
#Desc:
#Resource for saving campaign settings

class_name Campaign_res
extends Resource

var campaign_name = "Campaign Name"
var campaign_desc = "Description"
var DM_name = "DM Name"
var players = []
var map_list = []
var image = "res://images/Placeholder-1479066.png"


func save_campaign():
	var save_dict = {
		"campaign_desc" : campaign_desc,
		"DM_name" : DM_name,
		"players" : players,
		"image" : image
	}
	var campaign_save = FileAccess.open("res://saves/Campaigns/" + campaign_name + "/campaign.json", FileAccess.WRITE)
	if campaign_save == null:
		print("file open error - aborting")
		return
	campaign_save.store_pascal_string(JSON.stringify(save_dict))
	campaign_save.close()
	
func load_campaign(campaign_name):
	self.campaign_name = campaign_name
	if not FileAccess.file_exists("res://saves/Campaigns/" + campaign_name + "/campaign.json"):
		return #no save to load
	
	var campaign_save = FileAccess.open("res://saves/Campaigns/" + campaign_name + "/campaign.json", FileAccess.READ)
	if campaign_save == null:
		print("file open error - aborting")
		return
	var json = JSON.new()
	var parse_result = json.parse(campaign_save.get_pascal_string())
	if not parse_result == OK:
		print("JSON parse error")
		return
	var save_dict = json.get_data()
	for i in save_dict.keys():
		if i == "campaign_desc" or i == "DM_name" or i == "players" or i == "image":
			self.set(i, save_dict[i])#load data
	campaign_save.close()
