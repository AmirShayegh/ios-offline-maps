//
//  SettingsViewController.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-03-05.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import UIKit

public enum StorageSection: Int, CaseIterable {
    case DataSize
    case DeleteLayerData
    case DeleteMapData
    case DeleteData
}

public enum BaseMapSection: Int, CaseIterable {
    case BaseMapSize
    case LayerSize
    
}

public enum LayerSection: Int, CaseIterable {
    case LayerSize
    case numerOfLayers
}

public enum SettingsSections: Int, CaseIterable {
    case BaseMap
    case Layers
    case Storage
}

class SettingsViewController: BaseViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cacheMapButton: UIButton!
    @IBOutlet weak var addLayerButton: UIButton!
    
    // MARK: Constants
    private let tableCells = [
        "BasicSettingTableViewCell",
        "ButtonSettingTableViewCell"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        style()
        setUpTable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    func setSizeOfStoredTiles() -> String {
        return "\(TileService.shared.sizeOfStoredTiles().roundToDecimal(2))MB"
    }
    
    func sizeOfLayers() -> String {
        return "\(TileService.shared.sizeOfStoredTiles().roundToDecimal(2))MB"
    }
    
    func sizeOfStoredData() -> String {
        return "\(TileService.shared.sizeOfStoredTiles().roundToDecimal(2))MB"
    }
    
    func deleteAllStoredData() {
        self.alert(title: "Are you sure?", message: "This will delete all downloaded Map and Layer data", yes: {
            TileService.shared.deleteAllStoredTiles()
        }) {
            return
        }
    }
    
    func deleteAllMapData() {
        
        alert(title: "Are you sure?", message: "This will delete all downloaded Map data", yes: {
            TileService.shared.deleteAllStoredTiles()
        }) {
            return
        }
    }
    
    func deleteAllLayerData() {
        alert(title: "Are you sure?", message: "This will delete all downloaded Layer data", yes: {
            TileService.shared.deleteAllStoredTiles()
        }) {
            return
        }
    }
    
    func style() {
        titleLabel.textColor = Colors.primary
        view.backgroundColor = Colors.primaryContrast
        addLayerButton.tintColor = Colors.primary
        cacheMapButton.tintColor = Colors.primary
        addLayerButton.setTitleColor(Colors.primary, for: .normal)
        cacheMapButton.setTitleColor(Colors.primary, for: .normal)
    }
    
}

// MARK: TableView
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    private func setUpTable() {
        if self.tableView == nil {return}
        tableView.delegate = self
        tableView.dataSource = self
        for cell in tableCells {
            register(table: cell)
        }
    }
    
    func register(table cellName: String) {
        let nib = UINib(nibName: cellName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellName)
    }
    
    func getBasicCell(indexPath: IndexPath) -> BasicSettingTableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "BasicSettingTableViewCell", for: indexPath) as! BasicSettingTableViewCell
    }
    
    func getButtonCell(indexPath: IndexPath) -> ButtonSettingTableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "ButtonSettingTableViewCell", for: indexPath) as! ButtonSettingTableViewCell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSections.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = SettingsSections(rawValue: Int(section)) else {return 0}
        switch sectionType {
        case .BaseMap:
            return BaseMapSection.allCases.count
        case .Layers:
            return LayerSection.allCases.count
        case .Storage:
            return StorageSection.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = SettingsSections(rawValue: Int(section)) else {return nil}
        switch sectionType {
        case .BaseMap:
            return "Base Map"
        case .Layers:
            return "Layers"
        case .Storage:
            return "Storage"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = SettingsSections(rawValue: Int(indexPath.section)) else {return UITableViewCell()}
        
        switch sectionType {
        case .BaseMap:
            return getCellforBaseMapSectionAt(indexPath: indexPath)
        case .Layers:
            return getCellforLayersSectionAt(indexPath: indexPath)
        case .Storage:
            return getCellforStorageSectionAt(indexPath: indexPath)
        }
    }
    
    private func getCellforBaseMapSectionAt(indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = BaseMapSection(rawValue: indexPath.row) else {return UITableViewCell()}
        switch sectionType {
        case .BaseMapSize:
            let cell = getBasicCell(indexPath: indexPath)
            cell.setup(name: "Cached Map", icon: "archivebox.fill", value: setSizeOfStoredTiles())
            return cell
        case .LayerSize:
            let cell = getBasicCell(indexPath: indexPath)
            cell.setup(name: "", icon: "", value: "")
            return cell
        }
    }
    
    private func getCellforLayersSectionAt(indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = LayerSection(rawValue: indexPath.row) else {return UITableViewCell()}
        switch sectionType {
        case .LayerSize:
            let cell = getBasicCell(indexPath: indexPath)
            cell.setup(name: "Stored Layers", icon: "archivebox.fill", value: setSizeOfStoredTiles())
            return cell
        case .numerOfLayers:
            let cell = getBasicCell(indexPath: indexPath)
            cell.setup(name: "Stored Layers", icon: "skew", value: "")
            return cell
        }
    }
    
    private func getCellforStorageSectionAt(indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = StorageSection(rawValue: indexPath.row) else {return UITableViewCell()}
        switch sectionType {
        case .DataSize:
            let cell = getBasicCell(indexPath: indexPath)
            cell.setup(name: "Stored Data", icon: "archivebox.fill", value: sizeOfStoredData())
            return cell
        case .DeleteData:
            let cell = getButtonCell(indexPath: indexPath)
            cell.setup(name: "Delete All Stored Data", icon: "trash.fill") { [weak self] in
                guard let strongerSelf = self else {return}
                strongerSelf.deleteAllStoredData()
            }
            return cell
        case .DeleteMapData:
            let cell = getButtonCell(indexPath: indexPath)
            cell.setup(name: "Delete All Cached Map Data", icon: "map") { [weak self] in
                guard let strongerSelf = self else {return}
                strongerSelf.alert(title: "Are you sure?", message: "This will delete all downloaded Map and Layer data", yes: {
                    strongerSelf.deleteAllMapData()
                }) {
                    return
                }
            }
            return cell
        case .DeleteLayerData:
            let cell = getButtonCell(indexPath: indexPath)
            cell.setup(name: "Delete All Stored Layer Data", icon: "skew") { [weak self] in
                guard let strongerSelf = self else {return}
                strongerSelf.deleteAllLayerData()
            }
            return cell
        }
    }
}
