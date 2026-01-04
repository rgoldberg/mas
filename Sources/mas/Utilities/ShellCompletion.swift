//
// ShellCompletion.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

// TODO: Remove?
// private import ArgumentParser
//
// var associatedValueInsertionShellScript: String {
// 	switch CompletionShell.requesting {
// 	case .bash:
// 		"""
// 		printf $'\\n'
// 		printf $'%s\\n' "${completions[@]}" >&2
// 		__mas_add_completions -W "${completions[@]}"
// 		__mas_add_completions -W 1234
// 		"""
// 	case .fish:
// 		"printf %sA\\n $completions"
// 	case .zsh:
// 		"""
//
// 		local search_term="${words[CURRENT]}"
// 		if [[ ! "${search_term}" =~ ^[0-9]+$ && -n "${search_term}" ]]; then
// 		    local -a ids descs
// 		    local line id name
// 		    while IFS= read -r line; do
// 		        if [[ "${line}" =~ ^([0-9]+)[[:space:]]+(.+)$ ]]; then
// 		            id="${match[1]}"
// 		            name="${match[2]}"
// 		            ids+=("${id}")
// 		            descs+=("${id} -- ${name}")
// 		        fi
// 		    done < <("${command_name}" search "${search_term}" 2>/dev/null)
// 		    if ((${#ids[@]} > 0)); then
// 		        compadd -U -d descs -o nosort -l -- "${ids[@]}"
// 		        ret=0
// 		    fi
// 		fi
// 		"""
// 	default:
// 		""
// 	}
// }
