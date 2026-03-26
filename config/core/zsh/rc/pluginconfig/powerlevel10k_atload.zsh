if [[ -f $ZRCDIR/pluginconfig/p10k.zsh ]]; then
  source $ZRCDIR/pluginconfig/p10k.zsh
fi
# Machine-local overrides: copy p10k.local.zsh.template to ~/.config/zsh/p10k.local.zsh
# to adjust segments, colors, or fonts without touching the repo file.
if [[ -f ${ZDOTDIR:-$HOME/.config/zsh}/p10k.local.zsh ]]; then
  source ${ZDOTDIR:-$HOME/.config/zsh}/p10k.local.zsh
  # Re-initialize p10k so POWERLEVEL9K_MODE and other overrides take effect.
  # p10k reload works even with POWERLEVEL9K_DISABLE_HOT_RELOAD=true.
  (( $+functions[p10k] )) && p10k reload
fi
