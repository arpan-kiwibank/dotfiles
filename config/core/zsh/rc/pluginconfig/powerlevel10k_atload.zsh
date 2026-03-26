if [[ -f $ZRCDIR/pluginconfig/p10k.zsh ]]; then
  source $ZRCDIR/pluginconfig/p10k.zsh
fi
# Machine-local overrides: copy p10k.local.zsh.template to ~/.config/zsh/p10k.local.zsh
# to adjust segments, colors, or fonts without touching the repo file.
[[ -f ${ZDOTDIR:-$HOME/.config/zsh}/p10k.local.zsh ]] \
  && source ${ZDOTDIR:-$HOME/.config/zsh}/p10k.local.zsh
