# Source the p10k configuration. The local override (p10k.local.zsh) is applied
# inside p10k.zsh just before its p10k reload call, so MODE and all other
# overrides take effect in a single reload with the final merged settings.
if [[ -f $ZRCDIR/pluginconfig/p10k.zsh ]]; then
  source $ZRCDIR/pluginconfig/p10k.zsh
fi
