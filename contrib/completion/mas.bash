#!/usr/bin/env bash

_mas() {
	local cur prev words cword
	if declare -F _init_completion >/dev/null 2>&1; then
		_init_completion || return
	else
		COMPREPLY=()
		cur="${COMP_WORDS[COMP_CWORD]}"
		prev="${COMP_WORDS[COMP_CWORD-1]}"
		words=("${COMP_WORDS[@]}")
		cword="${COMP_CWORD}"
	fi
	if [[ "${cword}" -eq 1 ]]; then
		local shell_opts="$(shopt -p extglob)"
		shopt -s extglob
		local -r ifs_old="${IFS}"
		IFS=$'\n'
		local -a mas_help=($(mas help 2>/dev/null))
		mas_help=("${mas_help[@]:6:${#mas_help[@]}-7}")
		mas_help=("${mas_help[@]#  }")
		local -a commands=(help)
		for line in "${mas_help[@]}"; do
			if [[ ! "${line}" =~ ^\  ]]; then
				commands+=("${line%%?(,) *}")
			fi
		done
		COMPREPLY=($(compgen -W "${commands[*]}" -- "${cur}"))
		IFS="${ifs_old}"
		eval "${shell_opts}"
	fi
}

complete -F _mas mas
