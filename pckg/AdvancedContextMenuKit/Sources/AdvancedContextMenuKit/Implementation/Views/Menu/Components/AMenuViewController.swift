//
//  AMenuViewController.swift
//
//
//  Created by Stanislav Jelezoglo on 25.07.2023.
//

import UIKit
import SnapKit
import CommonKit

@MainActor
final class AMenuViewController: UIViewController {
        
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        tableView.layer.cornerRadius = 15
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.register(AMenuRowCell.self, forCellReuseIdentifier: String(describing: AMenuRowCell.self))
        
        return tableView
    }()
    
    // MARK: Proprieties
        
    let menuContent: AMenuSection
    var finished: (((() -> Void)?) -> Void)?
    
    private var done = false
    private var selectedItem: IndexPath?
    private let rowHeight = 40
    
    private let font = UIFont.systemFont(ofSize: 17)
    private let dragSensitivity: CGFloat = 250
    
    var menuSize: CGSize {
        let items = menuContent.menuItems.count
        let height = items * rowHeight
        return CGSize(width: 250, height: height)
    }
    
    // MARK: Init
    
    init(menuContent: AMenuSection) {
        self.menuContent = menuContent
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.cornerRadius = 15
        
        setupGestures()
        setupView()
    }
    
    private func setupView() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
    }
    
    private func setupGestures() {
        let panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(userPanned(_:))
        )
        view.addGestureRecognizer(panGestureRecognizer)
        
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(userTapped(_:))
        )
        view.addGestureRecognizer(tapGestureRecognizer)
        
        let hoverGestureRecognizer = UIHoverGestureRecognizer(
            target: self,
            action: #selector(self.hoverGesture(_:))
        )
        self.view.addGestureRecognizer(hoverGestureRecognizer)
    }
}

// MARK: - Private

private extension AMenuViewController {
    @objc private func hoverGesture(_ gestureRecognizer: UIHoverGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: self.view)
        let indexPath = self.indexPath(forRowAtPoint: touchLocation)
        
        switch gestureRecognizer.state {
        case .began:
            guard let indexPath = indexPath else {
                return
            }
            
            selectRow(at: indexPath)
        case .changed:
            guard !done else {
                selectRow(at: nil)
                return
            }
            
            selectRow(at: indexPath)
        case .ended:
            selectRow(at: nil)
        default:
            selectRow(at: nil)
        }
    }
    
    @objc func userTapped(_ gestureRecognizer: UIPanGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: view)

        guard gestureRecognizer.state == .ended,
              let indexPath = self.indexPath(forRowAtPoint: touchLocation)
        else { return }
        
        selectRow(at: indexPath)
        let menuItem = menuContent.menuItems[indexPath.row]
        menuItemWasTapped(menuItem)
    }
    
    @objc func userPanned(_ gestureRecognizer: UIPanGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: view)
        let indexPath = self.indexPath(forRowAtPoint: touchLocation)
        
        switch gestureRecognizer.state {
        case .began:
            guard let indexPath = indexPath else {
                if !done {
                    done = true
                    finished?(nil)
                }
                return
            }
            
            selectRow(at: indexPath)
        case .changed:
            guard !done else {
                selectRow(at: nil)
                return
            }
            
            selectRow(at: indexPath)
        case .ended:
            selectRow(at: nil)
            
            guard !done,
                  let indexPath = indexPath,
                  indexPath.row > -1,
                  gestureRecognizer.velocity(
                    in: tableView
                  ).magnitude < dragSensitivity
            else {
                return
            }
            
            let menuItem = menuContent.menuItems[indexPath.row]
            menuItemWasTapped(menuItem)
            
        default:
            selectRow(at: nil)
        }
    }
    
    func menuItemWasTapped(
        _ menuItem: AMenuItem
    ) {
        finished?(menuItem.action)
    }
    
    func selectRow(at indexPath: IndexPath?) {
        if let selectedItem = selectedItem, selectedItem != indexPath {
            if let cell = tableView.cellForRow(at: selectedItem) as? AMenuRowCell {
                cell.deselect()
            }
        }
        if let indexPath = indexPath, indexPath.row > -1 {
            if let cell = tableView.cellForRow(at: indexPath) as? AMenuRowCell {
                cell.select()
            }
            if indexPath != selectedItem {
                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
            }
        }
        
        if indexPath?.row == -1 {
            selectedItem = nil
        } else {
            selectedItem = indexPath
        }
    }
    
    func indexPath(forRowAtPoint point: CGPoint) -> IndexPath? {
        tableView.indexPathForRow(at: point)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension AMenuViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return menuContent.menuItems.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: AMenuRowCell.self),
            for: indexPath
        ) as! AMenuRowCell
        
        let rowPosition: AMenuRowCell.RowPosition
        
        if indexPath.row == menuContent.menuItems.count - 1 {
            rowPosition = .bottom
        } else if indexPath.row == .zero {
            rowPosition = .top
        } else {
            rowPosition = .other
        }
        
        let menuItem = menuContent.menuItems[indexPath.row]
        
        cell.configure(
            with: menuItem,
            accentColor: .adamant.textColor,
            backgroundColor: .adamant.contextMenuDefaultBackgroundColor,
            font: font,
            rowPosition: rowPosition
        )
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        CGFloat(rowHeight)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let menuItem = menuContent.menuItems[indexPath.row]
        menuItemWasTapped(menuItem)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension AMenuViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
