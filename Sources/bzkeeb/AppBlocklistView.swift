import AppKit
import UniformTypeIdentifiers

final class AppBlocklistView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    var bundleIdentifiers: [String] = [] {
        didSet {
            bundleIdentifiers = Array(Set(bundleIdentifiers)).sorted()
            table.reloadData()
            updateRemoveButton()
        }
    }

    private let table = NSTableView()
    private let removeButton = NSButton(title: "Remove", target: nil, action: nil)

    override init(frame: NSRect) {
        super.init(frame: frame)
        let title = NSTextField(labelWithString: "Blocked apps")
        title.font = .systemFont(ofSize: 17, weight: .semibold)
        title.frame = NSRect(x: 0, y: 466, width: 296, height: 24)
        addSubview(title)
        let subtitle = NSTextField(labelWithString: "bzkeeb stays off in these apps.")
        subtitle.textColor = .secondaryLabelColor
        subtitle.frame = NSRect(x: 0, y: 435, width: 296, height: 22)
        addSubview(subtitle)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("app"))
        column.width = 275
        table.addTableColumn(column)
        table.headerView = nil
        table.rowHeight = 44
        table.dataSource = self
        table.delegate = self
        table.allowsMultipleSelection = true
        table.setAccessibilityLabel("Blocked apps")
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 52, width: 296, height: 371))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.documentView = table
        addSubview(scroll)

        let add = NSButton(title: "Add app…", target: self, action: #selector(addApp))
        add.bezelStyle = .rounded
        add.frame = NSRect(x: 0, y: 8, width: 110, height: 32)
        addSubview(add)
        removeButton.target = self
        removeButton.action = #selector(removeApps)
        removeButton.bezelStyle = .rounded
        removeButton.frame = NSRect(x: 186, y: 8, width: 110, height: 32)
        addSubview(removeButton)
        updateRemoveButton()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func numberOfRows(in tableView: NSTableView) -> Int { bundleIdentifiers.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = bundleIdentifiers[row]
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier)
        let name = url.map { FileManager.default.displayName(atPath: $0.path) } ?? identifier
        let cell = NSTableCellView(frame: NSRect(x: 0, y: 0, width: 275, height: 44))
        let label = NSTextField(labelWithString: name)
        label.frame = NSRect(x: 8, y: 23, width: 259, height: 18)
        label.lineBreakMode = .byTruncatingTail
        cell.addSubview(label)
        cell.textField = label
        let detail = NSTextField(labelWithString: identifier)
        detail.font = .systemFont(ofSize: 11)
        detail.textColor = .secondaryLabelColor
        detail.frame = NSRect(x: 8, y: 4, width: 259, height: 16)
        detail.lineBreakMode = .byTruncatingMiddle
        cell.addSubview(detail)
        cell.toolTip = identifier
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) { updateRemoveButton() }

    private func updateRemoveButton() { removeButton.isEnabled = table.numberOfSelectedRows > 0 }

    @objc private func addApp() {
        guard let window else { return }
        let panel = NSOpenPanel()
        panel.title = "Block apps"
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let self else { return }
            let identifiers = panel.urls.compactMap { Bundle(url: $0)?.bundleIdentifier }
            self.bundleIdentifiers += identifiers
            if identifiers.count != panel.urls.count {
                let alert = NSAlert()
                alert.messageText = "Some apps could not be added"
                alert.informativeText = "The selected app must have a bundle identifier."
                alert.beginSheetModal(for: window)
            }
        }
    }

    @objc private func removeApps() {
        let selected = table.selectedRowIndexes
        bundleIdentifiers = bundleIdentifiers.enumerated().filter { !selected.contains($0.offset) }.map(\.element)
    }
}
