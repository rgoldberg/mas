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
// 		if ((${#completions[@]})); then
// 		    local -a ids descs
// 		    local c
// 		    for c in "${completions[@]}"; do
// 		        ids+=("${c%%:*}")
// 		        descs+=("${c%%:*} -- ${c#*:}")
// 		    done
// 		    compadd -U -d descs -a ids
// 		fi
// 		"""
// 	default:
// 		""
// 	}
// }
