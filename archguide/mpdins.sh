#!/bin/bash
# after install finished,if you want to use 'ncmpcpp',you should press 'u' to update database,then press '2' to explorer musics


sudo pacman -S --noconfirm mpd ncmpcpp

#configurate mpd
mkdir ~/music 2>/dev/null
mkdir -p ~/.config/mpd/playlists 2>/dev/null
touch ~/.config/mpd/{database,log,pid,state,sticker.sql,socket} 2>/dev/null
cp /usr/share/doc/mpd/mpdconf.example ~/.config/mpd/mpd.conf
sed -r -i "s/#(music_directory\s{2,}).*/\1\"~\/music\"/" ~/.config/mpd/mpd.conf
sed -r -i "s/#(playlist_directory\s+).*/\1\"~\/\.config\/mpd\/playlists\"/" ~/.config/mpd/mpd.conf
sed -r -i "s/#(db_file\s+).*/\1\"~\/\.config\/mpd\/database\"/" ~/.config/mpd/mpd.conf
sed -r -i "s/#(log_file\s+).*/\1\"~\/\.config\/mpd\/log\"/" ~/.config/mpd/mpd.conf
sed -r -i "s/#(pid_file\s+).*/\1\"~\/\.config\/mpd\/pid\"/" ~/.config/mpd/mpd.conf
sed -r -i "s/#(state_file\s+).*/\1\"~\/\.config\/mpd\/state\"/" ~/.config/mpd/mpd.conf
sed -r -i "s/#(sticker_file\s+).*/\1\"~\/\.config\/mpd\/sticker.sql\"/" ~/.config/mpd/mpd.conf

# sed -r -i "/Unix Socket/{N;s/#(bind_to_address\s+).*/\1\"~\/\.config\/mpd\/socket\"/}" ~/.config/mpd/mpd.conf
cat>>~/.config/mpd/mpd.conf<<-EOF
audio_output {
        type            "pulse"
        name            "pulse audio"
}

audio_output { 
   type                    "fifo" 
   name                    "my_fifo" 
   path                    "/tmp/mpd.fifo" 
   format                  "44100:16:2" 
}
EOF

mkdir ~/.ncmpcpp 2>/dev/null
# cp /usr/share/doc/ncmpcpp/config ~/.ncmpcpp/config
cat>~/.ncmpcpp/config<<-EOF
# MPD
mpd_host = "localhost"
mpd_port = "6600"

mpd_crossfade_time = 2

# VISUALIZER
visualizer_in_stereo = "no"
visualizer_data_source = "/tmp/mpd.fifo"
visualizer_fps = 60
visualizer_output_name = "Visualizer"
visualizer_type = "wave"
visualizer_look = "▐"
visualizer_color = "red,magenta,cyan,green,yellow"
visualizer_spectrum_smooth_look = no

# GLOBAL
cyclic_scrolling = "yes"
mouse_support = "yes"
mouse_list_scroll_whole_page = "yes"
lines_scrolled = "1"
message_delay_time = "1"
playlist_shorten_total_times = "yes"
playlist_display_mode = "columns"
browser_display_mode = "columns"
search_engine_display_mode = "columns"
playlist_editor_display_mode = "columns"
autocenter_mode = "yes"
centered_cursor = "yes"
user_interface = "classic"
follow_now_playing_lyrics = "yes"
locked_screen_width_part = "50"
ask_for_locked_screen_width_part = "yes"
display_bitrate = "no"
external_editor = "nano"
main_window_color = "default"
startup_screen = "playlist"

# PROGRESSBAR
progressbar_look = "━━━"
progressbar_elapsed_color = 5
progressbar_color = "black"

# UI VISIBILITY
header_visibility = "no"
statusbar_visibility = "yes"
titles_visibility = "no"
enable_window_title = "yes"

# COLOR
statusbar_color = "white"
color1 = "white"
color2 = "blue"

# UI FORMAT
now_playing_prefix = "\$b\$2\$7 "
now_playing_suffix = "  \$/b\$8"
current_item_prefix = "\$b\$7\$/b\$3 "
current_item_suffix = "  \$8"

song_columns_list_format = "(50)[]{t|fr:Title} (0)[magenta]{a} (7f)[green]{l}"

song_list_format = {\$4%a - }{%t}|{\$8%f\$9}\$R{\$3(%l)\$9}

song_status_format = \$b{{\$8"%t"}} \$3by {\$4%a{ \$3in \$7%b{ (%y)}} \$3}|{\$8%f}
EOF
systemctl start mpd --user 2>/dev/null
systemctl enable mpd --user 2>/dev/null