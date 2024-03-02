curr_d_id=$(yabai -m query --displays --space | jq '.id')
last_d_id=$(yabai -m query --displays | jq '.[-1].id')

if [[ $last_d_id == $curr_d_id ]]; then
	yabai -m display --focus first
else
	yabai -m display --focus next
fi
