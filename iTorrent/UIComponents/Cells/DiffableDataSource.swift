//
//  DiffableDataSource.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 17.04.2022.
//

import UIKit

class DiffableDataSource<Item>: UITableViewDiffableDataSource<SectionModel<Item>, Item> where Item: Hashable, Item: HidableItem {
    typealias Snapshot = NSDiffableDataSourceSnapshot<SectionModel<Item>, Item>

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        snapshot().sectionIdentifiers[section].header
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        snapshot().sectionIdentifiers[section].footer
    }
}

extension NSDiffableDataSourceSnapshot where SectionIdentifierType == SectionModel<ItemIdentifierType> {
    mutating func append(_ sections: [SectionIdentifierType]) {
        appendSections(sections)
        for section in sections {
            guard !section.hidden else { continue }
            appendItems(section.items.filter { !$0.hidden }, toSection: section)
        }
    }
}
