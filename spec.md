# OSCAPE - Smart media player as desktop background

Sets the desktop background based on operating system info on what is currently playing in any kind of media player web browser spotify app etc - the artwork picture of the song. Or thumbnail of the video. When the next song or video starts, the desktop background shows the new song artwork or video. If a media player is playing video, that video is playing as the desktop wallpaper as well, sound on.

# Layout

- two scripts:
  - install_dependencies.sh
    - install dependencies from those sources, prefferred in order:
    - arch repo via pacman
    - mise
    - aur repo via yay
  - oscape.sh
    - starts adaptive background
      - song artwork
      - or video - sound on
      - if started with --yt
        - treat the os info on currently played as youtube video
        - if video url not directly available, search youtube by title
        - play youtube video as wallpaper background - sound on

# Compatibility

Current setup:
- Arch linux
- Wayland
- Hyprland
- Noctalia shell




