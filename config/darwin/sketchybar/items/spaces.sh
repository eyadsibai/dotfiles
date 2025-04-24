#!/usr/bin/env bash

sketchybar --add event aerospace_workspace_change


# for sid in $(/opt/homebrew/bin/aerospace list-workspaces --all); do
#     sketchybar --add item space.$sid left \
#         --subscribe space.$sid aerospace_workspace_change \
#         --set space.$sid \
#         # space=$sid \
#         icon=$sid \
#         label.font="sketchybar-app-font:Regular:12.0" \
#         label.padding_right=10 \
#         label.y_offset=-1 \
#         click_script="/opt/homebrew/bin/aerospace workspace $sid" \
#         script="$CONFIG_DIR/plugins/space.sh $sid"
# done


for sid in $(aerospace list-workspaces --all); do
    sketchybar --add item space.$sid left \
        --subscribe space.$sid aerospace_workspace_change \
        --set space.$sid \
        icon=$sid \
        click_script="aerospace workspace $sid" \
        script="$CONFIG_DIR/plugins/space.sh $sid"
done

sketchybar --add item space_separator left             \                \
           --set space_separator icon="􀆊"                                \
                                 icon.color=$ACCENT_COLOR \
                                 icon.padding_left=4                   \
                                 label.drawing=off                     \
                                 background.drawing=off                \
                                 script="$PLUGIN_DIR/space_windows.sh" \
           --subscribe space_separator space_windows_change


# DOES NOT WORK WITH AEROSPACE SPACES
# sketchybar --add item space_separator left             \                \
#            --set space_separator icon="􀆊"                                \
#                                  icon.color=$ACCENT_COLOR \
#                                  icon.padding_left=4                   \
#                                  label.drawing=off                     \
#                                  background.drawing=off                \
#                                  script="$PLUGIN_DIR/space_windows.sh" \
#            --subscribe space_separator space_windows_change
