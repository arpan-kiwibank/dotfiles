if [[ -f $ZRCDIR/pluginconfig/p10k.zsh ]]; then
  source $ZRCDIR/pluginconfig/p10k.zsh
fi
# Machine-local overrides: copy p10k.local.zsh.template to ~/.config/zsh/p10k.local.zsh
# to adjust segments, colors, or fonts without touching the repo file.
# NOTE: POWERLEVEL9K_MODE is pre-seeded in powerlevel10k_atinit.zsh (runs before the plugin
# loads), so the correct icon set is active from the first prompt. Changes to MODE here
# have no effect — edit p10k.local.zsh and open a new terminal to change the icon mode.
[[ -f ${ZDOTDIR:-$HOME/.config/zsh}/p10k.local.zsh ]] \
  && source ${ZDOTDIR:-$HOME/.config/zsh}/p10k.local.zsh
