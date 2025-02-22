#!/usr/bin/python3

# until ( hyprctl hyprpaper unload all @> /dev/null )
# do
#     sleep 1
# done

# while true
# do

# ZEITGEIST_WALLPAPER_DIR="${HOME}/.local/share/wallpapers/zietgeist"
# monitor=$( hyprctl monitors | grep Monitor | awk '{print $2}' )
# current_wallpaper=$( hyprctl hyprpaper listactive | grep "${monitor}" | awk '{print $3}' ) 
# echo "${current_wallpaper}"

# if [ -d "${ZEITGEIST_WALLPAPER_DIR}" ]
# then
#     readarray -d '' wallpapers < <( find "${ZEITGEIST_WALLPAPER_DIR}" -type f -print0 )
#     possible_wallpapers=()
#     for wallpaper in "${wallpapers[@]}"
#     do
#         [[ "${wallpaper}" != "${current_wallpaper}" ]] && possible_wallpapers+=( "${wallpaper}" )
#     done

#     random_background=$( printf "%s\n" "${possible_wallpapers[@]}" | shuf -n 1 )

#     echo "${random_background}"
#     hyprctl hyprpaper unload all
#     hyprctl hyprpaper preload "${random_background}"
#     hyprctl hyprpaper wallpaper "${monitor}, ${random_background}"
# fi

# sleep 10

# done

    
if __name__ == "__main__":

    import argparse
    import json
    import math
    import os
    import random
    import sys
    import subprocess as sp
    import time

    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--dir", dest="dir", 
        default=os.path.join(os.environ["HOME"], ".local/share/wallpapers/zietgeist"),
        help="Directory to search for wallpapers")
    parser.add_argument("-r", "--rotate", type=int, default=600, help="How often, in seconds, to rotate the wallpaper")
    parser.add_argument("--file-types", dest="file_types", default=[".png", ".jpg", ".jpeg", ".webp"], nargs="+", 
        help="Filetypes to support.")
    parser.add_argument("-m", "--monitors", default=["all"], dest="monitors", nargs="+",
        help="Monitors to change wallpaper for, set to \"all\" (default) to handle all monitors")

    args = parser.parse_args()

    monitors = args.monitors
    wallpapers = {}

    if "all" in monitors:
        monitors = [x["name"] for x in json.loads(
            sp.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True).stdout
        )]

    try:
        while (True):

            time.sleep( args.rotate )

            keys_to_delete = [ k for k in wallpapers.keys() ]
            for k in keys_to_delete:
                if not os.path.exists(k):
                    print(k)
                    wallpapers.pop(k, None)

            for root, dir, file in os.walk( args.dir ):
                    for f in file:
                        full_path = os.path.join(root, f)
                        if full_path not in wallpapers.keys() and os.path.splitext(f)[1] in args.file_types:
                            wallpapers[full_path] = 1.0
                        

            for monitor in monitors:

                wallpaper_list = []
                wallpaper_weights = []
                for k, v in wallpapers.items():
                    
                    wallpaper_list.append(k)
                    wallpaper_weights.append(v)

                selected_wallpaper = random.choices(wallpaper_list, weights=wallpaper_weights, k=1)[0]
                print("Selected wallpaper {}".format(selected_wallpaper))
                try:
                    sp.run(["hyprctl", "hyprpaper", "unload", "all"], check=True)
                    sp.run(["hyprctl", "hyprpaper", "preload", selected_wallpaper])
                    sp.run(["hyprctl", "hyprpaper", "wallpaper", "{}, {}".format(monitor, selected_wallpaper)])
                except sp.CalledProcessError as e:
                    print("Got error ", e)


                for k, v in wallpapers.items():
                    if k == selected_wallpaper:
                        wallpapers[k] = random.random() / 10
                    else:
                        wallpapers[k] = 1 - ( 1 / math.exp(4 * v))

            print(wallpapers)

            
    except KeyboardInterrupt:
        sys.exit(0)        

