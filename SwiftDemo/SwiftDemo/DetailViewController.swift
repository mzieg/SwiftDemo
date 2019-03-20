import Cocoa

class DetailViewController: NSViewController
{
    var scheduleData: ScheduleData?
    var sectionID: String?
    var readOnly: Bool = false
    var controls: [NSControl] = []
    var parentController: ViewController?
    
    // controls on the ViewController (dragged via Xcode)
    @IBOutlet weak var buttonSave: NSButton!
    @IBOutlet weak var comboYear: NSComboBox!
    @IBOutlet weak var comboTerm: NSComboBox!
    @IBOutlet weak var textName: NSTextField!
    @IBOutlet weak var comboDept: NSComboBox!
    @IBOutlet weak var textCourseNum: NSTextField!
    @IBOutlet weak var comboSectionNum: NSComboBox!
    @IBOutlet weak var textInstructor: NSTextField!
    @IBOutlet weak var comboBuilding: NSComboBox!
    @IBOutlet weak var textRoom: NSTextField!
    @IBOutlet weak var comboTimeSlot: NSComboBox!
    
    /// This method fires the FIRST TIME the ViewController appears
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // populate the list of on-screen controls for convenient enabling / disabling
        controls.append(comboYear)
        controls.append(comboTerm)
        controls.append(textName)
        controls.append(comboDept)
        controls.append(textCourseNum)
        controls.append(comboSectionNum)
        controls.append(textInstructor)
        controls.append(comboBuilding)
        controls.append(textRoom)
        controls.append(comboTimeSlot)
    }
    
    /// This method fires EACH TIME before the ViewController appears
    override func viewWillAppear() {
        
        // hide or disable controls based on whether the detail view is to be read-only
        buttonSave.isHidden = readOnly
        for control in controls
        {
            control.isEnabled = !readOnly
        }
        
        populateControls()
    }
    
    func clearAllControls()
    {
        for control in controls
        {
            if let textField = control as? NSTextField
            {
                textField.stringValue = ""
            }
            else if let combo = control as? NSComboBox
            {
                combo.selectItem(at: 0)
            }
        }
    }
    
    func populateControls()
    {
        if sectionID != nil
        {
            if let section = scheduleData!.getSection(sectionID!)
            {
                populateComboStr(combo: comboTerm, value: section.term)
                populateComboStr(combo: comboDept, value: section.department)
                populateComboStr(combo: comboBuilding, value: section.building)
                populateComboStr(combo: comboTimeSlot, value: section.timeSlot)
                
                populateComboInt(combo: comboYear, value: section.year)
                populateComboInt(combo: comboSectionNum, value: section.sectionNumber)
                
                textName.stringValue = section.courseName
                textCourseNum.stringValue = String(section.courseNumber)
                textInstructor.stringValue = section.instructor
                textRoom.stringValue = String(section.room)
            }
            else
            {
                clearAllControls()
                displayError("Can't find section \(String(describing: sectionID)) in database!")
            }
        }
        else
        {
            // sectionID was nil, so we must be doing an "Add"
            clearAllControls()
        }
    }
    
    func populateComboStr(combo: NSComboBox, value: String)
    {
        let index = combo.indexOfItem(withObjectValue: value)
        if index >= 0 && index < combo.numberOfItems
        {
            combo.selectItem(at: index)
        }
    }
    
    func populateComboInt(combo: NSComboBox, value: Int)
    {
        let index = combo.indexOfItem(withObjectValue: String(value))
        if index >= 0 && index < combo.numberOfItems
        {
            combo.selectItem(at: index)
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        print("Saving data...")

        ////////////////////////////////////////////////////////////////////////
        // convert text fields to integers
        ////////////////////////////////////////////////////////////////////////

        var courseNum: Int = 0
        var sectionNum: Int = 0
        var roomNum: Int = 0
        var yearNum: Int = 0

        // is there a simpler way to do this?
        if let n = Int(textCourseNum.stringValue)
        {
            courseNum = n
        }
        else
        {
            displayError("Course number must be integral")
            return
        }
        
        if let n = Int(comboSectionNum.stringValue)
        {
            sectionNum = n
        }
        else
        {
            displayError("Section number must be integral")
            return
        }
        
        if let n = Int(textRoom.stringValue)
        {
            roomNum = n
        }
        else
        {
            displayError("Room number must be integral")
            return
        }

        if let n = Int(comboYear.stringValue)
        {
            yearNum = n
        }
        else
        {
            displayError("Year must be integral")
            return
        }

        ////////////////////////////////////////////////////////////////////////
        // instantiate a provisional CourseSection from the populated data
        ////////////////////////////////////////////////////////////////////////

        let newSection = CourseSection(
            name: textName.stringValue,
            dept: comboDept.stringValue,
            num: courseNum,
            section: sectionNum,
            instructor: textInstructor.stringValue,
            building: comboBuilding.stringValue,
            room: roomNum,
            timeSlot: comboTimeSlot.stringValue,
            term: comboTerm.stringValue,
            year: yearNum)
        
        // Check whether the CourseSection is valid according to its own rules.
        // This would be better done by throwing an exception from the ctor,
        // but that is left as an exercise for the reader.
        if let error = newSection.findErrors()
        {
            displayError(error)
            return
        }
        
        // Check whether this new CourseSection would be valid against the
        // existing ScheduleData
        if let error = scheduleData!.canAdd(newSection, oldSectionID: sectionID)
        {
            displayError(error)
            return
        }

        ////////////////////////////////////////////////////////////////////////
        // we've passed all the validation checks so go ahead and add it
        ////////////////////////////////////////////////////////////////////////

        // if we were doing an "Edit", first remove the old record
        if (sectionID != nil)
        {
            scheduleData!.removeSection(sectionID!)
        }
        scheduleData!.addSection(newSection)
        
        // update the file on-disk
        scheduleData!.saveFile()

        ////////////////////////////////////////////////////////////////////////
        // Return to caller
        ////////////////////////////////////////////////////////////////////////

        // since we've updated ScheduleData, tell the parent form to update itself
        self.parentController!.updateTable()
        
        // close this modal view
        self.dismiss(nil)
    }
    
    func displayError(_ msg: String)
    {
        let alert = NSAlert()
        alert.messageText = "Section Validation Error"
        alert.informativeText = msg
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("OK", comment: "OK"))
        alert.runModal()
    }
}
