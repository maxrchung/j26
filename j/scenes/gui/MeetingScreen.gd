extends Control

@onready var FakeCountLabel = $"ButtonContainer/InnerContainer/FakeContainer/Count" as Label;
@onready var FakeAction = $"ButtonContainer/InnerContainer/FakeContainer/Action" as Button;

@onready var RealCountLabel = $"ButtonContainer/InnerContainer/RealContainer/Count" as Label;
@onready var RealAction = $"ButtonContainer/InnerContainer/RealContainer/Action"

func _set_enabled(flag: bool) -> void:
	FakeAction.disabled = not flag
	RealAction.disabled = not flag

func _on_fake_pressed() -> void:
	ServerConnection.vote_against()
	_set_enabled(false)

func _on_real_pressed() -> void:
	ServerConnection.vote_for()
	_set_enabled(false)

func _on_meeting_change(info: SrvCxn.EmergencyMeetingInfo) -> void:
	FakeCountLabel.text = "I".repeat(info.votes_against.size())
	RealCountLabel.text = "I".repeat(info.votes_for.size())

	var didVoteAgainst = ServerConnection.CurrentPlayerID in info.votes_against
	var didVoteFor = ServerConnection.CurrentPlayerID in info.votes_for
	var didVote = didVoteAgainst or didVoteFor
	_set_enabled(info.active and not didVote)

func _ready() -> void:
	_set_enabled(false)
	ServerConnection.emergency_meeting_updated.connect(_on_meeting_change)
