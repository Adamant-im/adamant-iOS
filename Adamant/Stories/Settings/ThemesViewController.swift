//
//  ThemesViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class ThemesViewController: UITableViewController {

    private static let identifier = "cell"
    
    private var themeKeys: [String]!
    private var checkedRow: Int? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = AccountViewController.Rows.theme.localized
        
        themeKeys = ThemesManager.shared.themes.keys.sorted()
        
        // hack to make default theme (Light) always first
        if let index = themeKeys.firstIndex(of: ThemesManager.shared.defaultTheme.id) {
            let id = themeKeys.remove(at: index)
            themeKeys.insert(id, at: 0)
        }
        
        checkedRow = themeKeys.firstIndex(of: ThemesManager.shared.currentTheme.id)
        tableView.register(UINib(nibName: "ThemeTableViewCell", bundle: nil), forCellReuseIdentifier: ThemesViewController.identifier)
        
        // Styles
        tableView.setStyle(.baseTable)
        navigationController?.navigationBar.setStyle(.baseNavigationBar)
        view.style = AdamantThemeStyle.primaryTintAndBackground
        observeThemeChange()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return themeKeys.count
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    // MARK: - Cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ThemesViewController.identifier, for: indexPath) as! ThemeTableViewCell
        
        let id = themeKeys[indexPath.row]
        
        if let theme = ThemesManager.shared.themes[id] {
            cell.titleLabel.text = theme.title
        } else {
            cell.titleLabel.text = id
        }
        
        if let checkedRow = checkedRow, indexPath.row == checkedRow {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        if let theme = ThemesManager.shared.themes[id] {
            cell.primaryColor = theme.background
            cell.secondaryColor = theme.primary
        } else {
            cell.primaryColor = ThemesManager.shared.defaultTheme.background
            cell.secondaryColor = ThemesManager.shared.defaultTheme.primary
        }
        
        cell.setStyle(.baseTableViewCell)
        cell.textLabel?.textColor = UIColor.adamant.primary

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let theme = ThemesManager.shared.themes[themeKeys[indexPath.row]] else {
            return
        }
        
        ThemesManager.shared.applyTheme(theme)
        
        if let checkedRow = checkedRow, let cell = tableView.cellForRow(at: IndexPath(row: checkedRow, section: 0)) {
            cell.accessoryType = .none
        }
        
        checkedRow = indexPath.row
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
    }
}

// MARK: - Stylist
extension ThemesViewController: Themeable {
    func apply(theme: AdamantTheme) {
        tableView.reloadData()
    }
}
