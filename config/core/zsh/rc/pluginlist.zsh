#==============================================================#
## Setup zinit                                                ##
#==============================================================#
# cSpell:disable
if [ -z "$ZPLG_HOME" ]; then
	ZPLG_HOME="$ZDATADIR/zinit"
fi

if ! test -d "$ZPLG_HOME"; then
	mkdir -p "$ZPLG_HOME"
	chmod g-rwX "$ZPLG_HOME"
	git clone --depth 10 https://github.com/zdharma-continuum/zinit.git ${ZPLG_HOME}/bin
fi

typeset -gAH ZPLGM
ZPLGM[HOME_DIR]="${ZPLG_HOME}"
source "$ZPLG_HOME/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Read the active dotfiles profile from the bootstrap state file.
# Defaults to 'full' so a first shell session (before bootstrap) loads everything.
typeset -g DOTFILES_ACTIVE_PROFILE
DOTFILES_ACTIVE_PROFILE="${$(command cat "${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/active-profile" 2>/dev/null):-full}"


#==============================================================#
## Plugin load                                                ##
#==============================================================#

#--------------------------------#
# zinit extension
#--------------------------------#
zinit light-mode for \
	@zdharma-continuum/zinit-annex-readurl


#--------------------------------#
# completion
#--------------------------------#
zinit wait'0b' lucid \
	atload"source $ZHOMEDIR/rc/pluginconfig/zsh-autosuggestions_atload.zsh" \
	light-mode for @zsh-users/zsh-autosuggestions

zinit wait'0c' lucid \
	atinit"source $ZHOMEDIR/rc/pluginconfig/zsh-autocomplete_atinit.zsh" \
	atload"source $ZHOMEDIR/rc/pluginconfig/zsh-autocomplete_atload.zsh" \
	light-mode for @marlonrichert/zsh-autocomplete

zinit wait'0b' lucid as"completion" \
	atload"source $ZHOMEDIR/rc/pluginconfig/zsh-completions_atload.zsh; zicompinit; zicdreplay" \
	light-mode for @zsh-users/zsh-completions


#--------------------------------#
# prompt
#--------------------------------#
zinit wait'0a' lucid \
	if"(( ${ZSH_VERSION%%.*} > 4.4))" \
	atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
	atload"source $ZHOMEDIR/rc/pluginconfig/fast-syntax-highlighting.zsh" \
	light-mode for @zdharma-continuum/fast-syntax-highlighting

PROMPT="%~"$'\n'"> "
zinit wait'!0b' lucid depth=1 \
	atload"source $ZHOMEDIR/rc/pluginconfig/powerlevel10k_atload.zsh" \
	light-mode for @romkatv/powerlevel10k


#--------------------------------#
# history
#--------------------------------#
zinit wait'1' lucid \
	if"(( ${ZSH_VERSION%%.*} > 4.4))" \
	light-mode for @zsh-users/zsh-history-substring-search


#--------------------------------#
# alias
#--------------------------------#
zinit wait'0' lucid \
	light-mode for @unixorn/git-extra-commands

zinit wait'0a' lucid \
	atload"source $ZHOMEDIR/rc/pluginconfig/zsh-abbrev-alias_atinit.zsh" \
	light-mode for @momo-lab/zsh-abbrev-alias

#--------------------------------#
# environment variable
#--------------------------------#
zinit wait'0' lucid \
	light-mode for @Tarrasch/zsh-autoenv


#--------------------------------#
# improve cd
#--------------------------------#
zinit wait'1' lucid \
	from"gh-r" as"program" pick"zoxide-*/zoxide" \
	atload"source $ZHOMEDIR/rc/pluginconfig/zoxide_atload.zsh" \
	light-mode for @ajeetdsouza/zoxide

zinit wait'1' lucid \
	atload"source $ZHOMEDIR/rc/pluginconfig/cd-gitroot_atload.zsh" \
	light-mode for @mollifier/cd-gitroot

zinit wait'1' lucid \
	atinit"source $ZHOMEDIR/rc/pluginconfig/zshmarks_atinit.zsh" \
	light-mode for @jocelynmallon/zshmarks


#--------------------------------#
# git
#--------------------------------#
zinit wait'2' lucid \
	light-mode for @caarlos0/zsh-git-sync


#--------------------------------#
# fzf
#--------------------------------#
zinit wait'1a' lucid \
 	from"gh-r" as"program" \
 	atload"source $ZHOMEDIR/rc/pluginconfig/fzf_atload.zsh" \
 	for @junegunn/fzf
if [ "$ZSHRC_BENCH" != "true" ]; then
zinit ice wait'0c' lucid
zinit snippet https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh
zinit ice wait'1a' lucid atload"source $ZHOMEDIR/rc/pluginconfig/fzf_completion.zsh_atload.zsh"
zinit snippet https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh
zinit ice wait'0a' lucid as"program"
zinit snippet https://raw.githubusercontent.com/junegunn/fzf/master/bin/fzf-tmux
fi

zinit wait'1' lucid \
	pick"fzf-extras.zsh" \
	atload"source $ZHOMEDIR/rc/pluginconfig/fzf-extras_atload.zsh" \
	light-mode for @atweiden/fzf-extras # fzf

zinit wait'0c' lucid \
	pick"fzf-finder.plugin.zsh" \
	atinit"source $ZHOMEDIR/rc/pluginconfig/zsh-plugin-fzf-finder_atinit.zsh" \
	light-mode for @leophys/zsh-plugin-fzf-finder

zinit wait'0c' lucid \
	atinit"source $ZHOMEDIR/rc/pluginconfig/fzf-mark_atinit.zsh" \
	light-mode for @urbainvaes/fzf-marks

zinit wait'1c' lucid \
	atinit"source $ZHOMEDIR/rc/pluginconfig/fzf-zsh-completions_atinit.zsh" \
	light-mode for @chitoku-k/fzf-zsh-completions

zinit wait'2' lucid \
	atinit"source $ZHOMEDIR/rc/pluginconfig/zsh-fzf-widgets_atinit.zsh" \
	light-mode for @amaya382/zsh-fzf-widgets




#--------------------------------#
# extension
#--------------------------------#
zinit wait'1' lucid \
	atload"source $ZHOMEDIR/rc/pluginconfig/emoji-cli_atload.zsh" \
	light-mode for @b4b4r07/emoji-cli

if [[ -z "$SSH_CONNECTION" ]] && builtin command -v notify-send >/dev/null 2>&1; then
	zinit wait'0' lucid \
		atload"source $ZHOMEDIR/rc/pluginconfig/zsh-auto-notify_atload.zsh" \
		light-mode for @MichaelAquilina/zsh-auto-notify
fi

zinit wait'0' lucid \
	light-mode for @mafredri/zsh-async

zinit wait'0' lucid \
	atinit"source $ZHOMEDIR/rc/pluginconfig/zsh-completion-generator_atinit.zsh" \
	light-mode for @RobSis/zsh-completion-generator

zinit wait'2' lucid \
	light-mode for @hlissner/zsh-autopair

#--------------------------------#
# enhancive command
#--------------------------------#
zinit wait'1' lucid \
	from"gh-r" as"program" pick"eza" \
	atload"source $ZHOMEDIR/rc/pluginconfig/eza_atload.zsh" \
	light-mode for @eza-community/eza
if [ "$ZSHRC_BENCH" != "true" ]; then
	zinit ice wait'1' lucid as"completion" nocompile
	zinit snippet https://github.com/eza-community/eza/blob/main/completions/zsh/_eza
fi

zinit wait'1' lucid blockf nocompletions \
	from"gh-r" as'program' pick'ripgrep*/rg' \
	cp"ripgrep-*/complete/_rg -> _rg" \
	atclone'chown -R $(id -nu):$(id -ng) .; zinit creinstall -q BurntSushi/ripgrep' \
	atpull'%atclone' \
	light-mode for @BurntSushi/ripgrep

zinit wait'1' lucid blockf nocompletions \
	from"gh-r" as'program' cp"fd-*/autocomplete/_fd -> _fd" pick'fd*/fd' \
	atclone'chown -R $(id -nu):$(id -ng) .; zinit creinstall -q sharkdp/fd' \
	atpull'%atclone' \
	light-mode for @sharkdp/fd

zinit wait'1' lucid \
	from"gh-r" as"program" cp"bat/autocomplete/bat.zsh -> _bat" pick"bat*/bat" \
	atload"export BAT_THEME='Nord'; alias cat=bat" \
	light-mode for @sharkdp/bat

zinit wait'1' lucid \
	from"gh-r" as"program" \
	atload"alias rm='trash put'" \
	light-mode for @oberblastmeister/trashy

zinit wait'1' lucid \
	from"gh-r" as"program" mv'*tealdeer* -> tldr' \
	atclone'chmod +x tldr' atpull'chmod +x tldr' \
	light-mode for @tealdeer-rs/tealdeer
if [ "$ZSHRC_BENCH" != "true" ]; then
	zinit ice wait'1' lucid as"completion" mv'zsh_tealdeer -> _tldr'
	zinit snippet https://raw.githubusercontent.com/tealdeer-rs/tealdeer/main/completion/zsh_tealdeer
fi

zinit wait'1' lucid \
	from"gh-r" as"program" bpick'*linux*' \
	light-mode for @dalance/procs

zinit wait'1' lucid \
	from"gh-r" as"program" pick"delta*/delta" \
	atload"compdef _gnu_generic delta" \
	light-mode for @dandavison/delta

zinit wait'1' lucid \
	from"gh-r" as"program" pick"mmv*/mmv" \
	light-mode for @itchyny/mmv


#--------------------------------#
# program
#--------------------------------#
# neovim
zinit wait'0' lucid nocompletions \
	from'gh-r' ver'nightly' as'program' bpick'*tar.gz' \
	pick'nvim*/bin/*' \
	atclone"echo "" > ._zinit/is_release" \
	atpull'%atclone' \
	run-atpull \
	atload"source $ZHOMEDIR/rc/pluginconfig/neovim_atload.zsh" \
	light-mode for @neovim/neovim
	#atclone"command cp -rf nvim*/* $ZPFX; echo "" > ._zinit/is_release" \

# translation #
zinit wait'1' lucid \
	ver"stable" pullopts"--rebase" \
	light-mode for @soimort/translate-shell


zinit wait'1' lucid \
	from"gh-r" as"program" \
	mv'mocword* -> mocword' \
	atclone'chmod +x mocword' atpull'chmod +x mocword' \
	atload"source $ZHOMEDIR/rc/pluginconfig/mocword_atload.zsh" \
	light-mode for @high-moctane/mocword

# env #
zinit wait'1' lucid \
	from"gh-r" as"program" pick"direnv" \
	atclone'./direnv hook zsh > zhook.zsh' \
	atpull'%atclone' \
	light-mode for @direnv/direnv


zinit wait'1' lucid \
	from"gh-r" as"program" \
	mv'mise-* -> mise' \
	atclone'chmod +x mise' atpull'chmod +x mise' \
	atload"source $ZHOMEDIR/rc/pluginconfig/mise_atload.zsh" \
	light-mode for @jdx/mise

# GitHub #
zinit wait'1' lucid \
	from"gh-r" as"program" pick"ghq*/ghq" \
	atload"source $ZHOMEDIR/rc/pluginconfig/ghq_atload.zsh" \
	light-mode for @x-motemen/ghq

zinit wait'1' lucid \
	from"gh-r" as"program" pick"ghg*/ghg" \
	light-mode for @Songmu/ghg

zinit wait'1' lucid \
	from"gh-r" as'program' bpick'*linux_*.tar.gz' pick'gh*/**/gh' \
	atload"source $ZHOMEDIR/rc/pluginconfig/gh_atload.zsh" \
	light-mode for @cli/cli



#--------------------------------------------------------------#
# Optional-tool plugins — only loaded when 'full' profile is  #
# active. To add a new tool: add its zinit block here.        #
# $DOTFILES_ACTIVE_PROFILE is read from the bootstrap state   #
# file at startup (see top of this file).                     #
#--------------------------------------------------------------#
if [[ "$DOTFILES_ACTIVE_PROFILE" == "full" ]]; then

        # zeno: snippet/completion engine (requires deno)
        if [[ "$ZSHRC_BENCH" != "true" ]]; then
                zinit wait'2' lucid silent blockf depth"1" \
                        atclone'deno cache --no-check ./src/cli.ts' \
                        atpull'%atclone' \
                        atinit"source $ZHOMEDIR/rc/pluginconfig/zeno_atinit.zsh" \
                        atload"source $ZHOMEDIR/rc/pluginconfig/zeno_atload.zsh" \
                        for @yuki-yano/zeno.zsh
        fi

        # pet: command snippet manager
        [[ $- == *i* ]] && stty -ixon
        zinit wait'1' lucid blockf nocompletions \
                from"gh-r" as"program" pick"pet" bpick'*linux_amd64.tar.gz' \
                atclone'chown -R $(id -nu):$(id -ng) .; zinit creinstall -q knqyf263/pet' \
                atpull'%atclone' \
                atload"source $ZHOMEDIR/rc/pluginconfig/pet_atload.zsh" \
                for @knqyf263/pet

fi

# etc #
zinit wait'1' lucid \
	as"program" pick"emojify" \
	light-mode for @mrowa44/emojify


#==============================================================#
# my plugins
#==============================================================#
if [ "$ZSHRC_BENCH" != "true" ]; then
	zinit wait'1' lucid \
		atload"source $ZHOMEDIR/rc/pluginconfig/mru.zsh_atload.zsh" \
		light-mode for "$ZHOMEDIR/rc/myplugins/mru.zsh/"
	zinit wait'1' lucid \
		pick"*.sh" \
		light-mode for "$ZHOMEDIR/rc/myplugins/vte/"
	# zinit wait'2' lucid \
		#   light-mode for "$ZHOMEDIR/rc/myplugins/coc-project.zsh/"
fi




#==============================================================#
# completion
#==============================================================#
if [ "$ZSHRC_BENCH" != "true" ]; then
	zinit wait'2' lucid silent \
		atload"zicompinit; zicdreplay" \
		light-mode for "$ZHOMEDIR/rc/myplugins/command_config.zsh"
fi


#==============================================================#
# local plugins
#==============================================================#
[ -f "$HOME/.zshrc.plugin.local" ] && source "$HOME/.zshrc.plugin.local"



# -> powerlevel10k
# Too slow on ssh
# zinit ice wait'!0' lucid atload"source $ZHOMEDIR/rc/pluginconfig/zsh-command-time_atload.zsh"
# zinit light popstas/zsh-command-time
# fz
#FZFZ_RECENT_DIRS_TOOL=zshz
#zinit ice wait'!0' lucid as"program" pick:"fzf-z.plugin.zsh"
#zinit light andrewferrier/fzf-z
# fasd Not updated recently
#zinit ice pick'fasd'
#zinit light clvv/fasd atload'eval "$(fasd --init auto)"'
# asdf
#zinit ice wait'!0' lucid as"program" pick:"bin/anyenv" if"[[ -d "$HOME/.config/anyenv/anyenv-install" ]]" atload'eval "$(anyenv init -)"'
#zinit light anyenv/anyenv
# don't maintain
# zinit ice pick"*.sh" atinit"source $ZHOMEDIR/rc/pluginconfig/z_atinit.zsh"
# zinit light rupa/z
# git-prompt
# zinit ice lucid wait"0" atload"source $ZHOMEDIR/rc/pluginconfig/zsh-async_atload.zsh && set_async"
# zinit light mafredri/zsh-async

# don't use
# zinit ice wait'1' lucid atload"alias rm=gomi"
# zinit light b4b4r07/zsh-gomi
#zsh-users/zsh-syntax-highlighting # -> zdharma/fast-syntax-highlighting
# move
# zplug 'hchbaw/zce.zsh' # -> don't move

# zplug 'felixr/docker-zsh-completion' # -> broken
# fuzzy finder
# unused
#zplug 'b4b4r07/enhancd', use:init.sh
#zplug 'junegunn/fzf-bin', as:command, from:gh-r, rename-to:fzf # -> zplug grep bug
#zplug 'junegunn/fzf', as:command, use:bin/fzf-tmux

#zplug "autojump" # ->z
#zplug "tarruda/zsh-autosuggestions" # ->auto-fu
#zplug 'mollifier/anyframe' # -> fzf
#zplug 'zsh-users/zaw' # -> fzf
