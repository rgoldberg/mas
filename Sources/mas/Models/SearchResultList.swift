//
// SearchResultList.swift
// mas
//
// Created by Ben Chatelain on 2018-12-29.
// Copyright © 2018 mas-cli. All rights reserved.
//

struct SearchResultList: Decodable {
	var resultCount: Int
	var results: [SearchResult]
}
