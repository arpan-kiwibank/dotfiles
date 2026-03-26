function existsCommand() {
	builtin command -v $1 > /dev/null 2>&1
}

function source-safe() { if [ -f "$1" ]; then source "$1"; fi }

#==============================================================#
## Apply XDG
#==============================================================#
mkdir -p "$XDG_CACHE_HOME"/less
export LESSHISTFILE="$XDG_CACHE_HOME"/less/history
mkdir -p "$XDG_CACHE_HOME"/gdb
export SQLITE_HISTORY="$XDG_CACHE_HOME"/sqlite_history

#==============================================================#
## aws completion
#==============================================================#
if existsCommand aws_zsh_completer.sh; then
	source aws_zsh_completer.sh
fi


#==============================================================#
## terraform completion
#==============================================================#
if existsCommand terraform; then
	autoload -U +X bashcompinit && bashcompinit
	complete -o nospace -C "$(command -v terraform)" terraform
fi


#==============================================================#
## npm completion
#==============================================================#
_npm_path_hook() {
	if [[ -n $NPM_DIR ]]; then
		# remove old dir from path
		path=(${path:#$NPM_DIR})
		unset NPM_DIR
	fi

	if [[ -d "${PWD}/node_modules/.bin" ]]; then
		NPM_DIR="${PWD}/node_modules/.bin"
		path=($NPM_DIR $path)
	fi
}
[[ -z $chpwd_functions ]] && chpwd_functions=()
chpwd_functions=($chpwd_functions _npm_path_hook)

#==============================================================#
## Copilot cli
#==============================================================#
# sudo npm install -g @githubnext/github-copilot-cli
# github-copilot-cli auth
if existsCommand github-copilot-cli; then
	eval "$(github-copilot-cli alias -- "$0")"
fi


