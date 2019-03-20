import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    var scheduleData = ScheduleData()

    @IBOutlet weak var table: NSTableView!
    
    ////////////////////////////////////////////////////////////////////////////
    // ViewController overrides
    ////////////////////////////////////////////////////////////////////////////

    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.delegate = self
        table.dataSource = self
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    // The user has clicked Add, View or Edit, so do a quick validation to see
    // if the segue should proceed.
    override func shouldPerformSegue(withIdentifier identifier: NSStoryboardSegue.Identifier, sender: Any?) -> Bool {

        if let button = sender as? NSButton
        {
            let buttonName = button.stringValue.lowercased()
            if (buttonName == "edit") || (buttonName == "view")
            {
                if getSelectedSection() == nil
                {
                    displayError("Must select section to View or Edit")
                    return false
                }
            }
        }
        return true
    }

    // The user has clicked Add, View or Edit, and apparently shouldPerformSegue
    // validation passed, so decide what data we're going to send to
    // DetailViewController.
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        var sectionID : String? = nil
        var readOnly: Bool = false
        let selectedSection = getSelectedSection()

        if let button = sender as? NSButton
        {
            if button.title.lowercased() == "add"
            {
                print("prepare: from Add")
                sectionID = nil
            }
            else if button.title.lowercased() == "edit"
            {
                print("prepare: from Edit")
                sectionID = selectedSection?.sectionID ?? nil
            }
            else if button.title.lowercased() == "view"
            {
                print("prepare: from View")
                readOnly = true
                sectionID = selectedSection?.sectionID ?? nil
            }
            else
            {
                print("prepare: Sender is unrecognized button \(button.title)")
            }
        }
        else
        {
            print("prepare: sender isn't an NSButton")
        }

        if let dest = segue.destinationController as? DetailViewController
        {
            dest.scheduleData = scheduleData
            dest.sectionID = sectionID
            dest.readOnly = readOnly
            dest.parentController = self
            
            print("prepare: passing sectionID \(String(describing: sectionID)), readOnly \(readOnly)")
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // NSTableViewDataSource
    ////////////////////////////////////////////////////////////////////////////

    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return scheduleData.getSectionCount()
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // NSTableViewDelegate
    ////////////////////////////////////////////////////////////////////////////

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        // print("tableView: generating TableViewCell for row \(row)")
        
        guard let section = scheduleData.getSectionByIndex(row) else
        {
            print("tableView: error, no CourseSection found for row \(row)")
            return nil
        }
        
        var text = ""
        var cellID = ""
        
        // year, term, dept, courseNum, section
        if tableColumn == table.tableColumns[0]
        {
            text = String(format: "%04d", section.year)
            cellID = "cellYear"
        }
        else if tableColumn == tableView.tableColumns[1]
        {
            text = section.term
            cellID = "cellTerm"
        }
        else if tableColumn == tableView.tableColumns[2]
        {
            text = section.department
            cellID = "cellDept"
        }
        else if tableColumn == tableView.tableColumns[3]
        {
            text = String(section.courseNumber)
            cellID = "cellCourse"
        }
        else if tableColumn == tableView.tableColumns[4]
        {
            text = String(format: "%03d", section.sectionNumber)
            cellID = "cellSection"
        }
        
        let nsCellID = NSUserInterfaceItemIdentifier(cellID)
        // print("tableView: generating TableViewCell for row \(row), column \(cellID) (\(nsCellID)) = value \(text)")
        
        if let cell = table.makeView(withIdentifier: nsCellID, owner: nil) as? NSTableCellView
        {
            cell.textField?.stringValue = text
            return cell
        }
        
        print("tableView: failed to generate TableViewCell for row \(row), column \(cellID), value \(text)")
        return nil
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Callbacks
    ////////////////////////////////////////////////////////////////////////////

    @IBAction func deleteButtonClicked(_ sender: Any)
    {
        if let section = getSelectedSection()
        {
            scheduleData.removeSection(section.sectionID)
            scheduleData.saveFile()
            updateTable()
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////
    // Methods
    ////////////////////////////////////////////////////////////////////////////

    func updateTable()
    {
        print("reloading ScheduleData into Table")
        table.reloadData()
    }
    
    func getSelectedSection() -> CourseSection?
    {
        if table.selectedRow != -1
        {
            return scheduleData.getSectionByIndex(table.selectedRow)
        }
        return nil
    }
    
    func displayError(_ msg: String)
    {
        let alert = NSAlert()
        alert.messageText = "Application Error"
        alert.informativeText = msg
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("OK", comment: "OK"))
        alert.runModal()
    }
}

