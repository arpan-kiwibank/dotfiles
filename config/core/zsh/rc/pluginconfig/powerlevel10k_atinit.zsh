# Pre-seed POWERLEVEL9K_MODE (and any other POWERLEVEL9K_* vars) from the
# machine-local override file BEFORE zinit sources powerlevel10k.zsh.
#
# POWERLEVEL9K_MODE is read ONCE at plugin load time to select the icon set
# (nerdfont, ascii, etc.). It cannot be changed afterwards via p10k reload.
# This file runs via zinit atinit so the correct mode is active when the
# plugin initialises and loads its icon tables.
[[ -f ${ZDOTDIR:-$HOME/.config/zsh}/p10k.local.zsh ]] \
  && source ${ZDOTDIR:-$HOME/.config/zsh}/p10k.local.zsh
