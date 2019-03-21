import Foundation

class ScheduleData
{
    let filename = "scheduleData.csv"
    var sections: [String:CourseSection] // sectionID -> CourseSection
    
    init()
    {
        print("instantiating ScheduleData")
        sections = [:]
        loadFromFile()
    }

    /// @todo should move validation logic here, so rules are applied whether
    /// adding from GUI or loading from file
    func addSection(_ newSection: CourseSection)
    {
        print("Adding \(newSection.sectionID)")
        sections[newSection.sectionID] = newSection
    }
    
    func removeSection(_ sectionID: String)
    {
        print("Removing \(sectionID)")
        sections.removeValue(forKey: sectionID)
    }

    func getSection(_ sectionID: String) -> CourseSection?
    {
        return sections[sectionID]
    }
    
    func getSectionCount() -> Int
    {
        return sections.count
    }
    
    func getSectionByIndex(_ row: Int) -> CourseSection?
    {
        if row >= getSectionCount()
        {
            return nil
        }
        
        let sectionIDs = Array(sections.keys)
        let sectionID = sectionIDs[row]
        return sections[sectionID]
    }
    
    // If the proposed new section would violate any of our scheduling rules,
    // return a string explaining the problem.  Return nil if no errors found.
    // This could be implemented by simply having the add() method throw an
    // exception.
    func canAdd(_ newSection: CourseSection, oldSectionID: String?) -> String?
    {
        for (sectionID, section) in sections
        {
            // ignore the PREVIOUS version of this section, if we're doing an update
            if (oldSectionID != nil) && (section.sectionID == oldSectionID)
            {
                print("ignoring potential conflicts with self")
                continue
            }
            
            // assuming that no conflicts can exist across terms
            if (section.year != newSection.year) || (section.term != newSection.term)
            {
                print("assuming no opportunity for conflict with different term/year \(section.term)/\(section.year)")
                continue
            }
            
            // handle time-space paradoxes
            if section.timeSlot == newSection.timeSlot
            {
                if (section.building == newSection.building) && (section.room == newSection.room)
                {
                    return String(format: "Overlaps \(sectionID) in time and space")
                }
                
                if (section.instructor == newSection.instructor)
                {
                    return String(format: "Instructor \(section.instructor) would need a Time-Turner!")
                }
            }
            
            // more rules here...
        }
        
        // seems legit?
        print("no conflicts found")
        return nil
    }
    
    func getPathname() -> URL?
    {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        {
            return dir.appendingPathComponent(filename)
        }
        return nil
    }
    
    /// Swift seems to have amazingly poor support for simply writing text files
    /// line-by-line; it really prefers to deal with large atomic writes.
    func generateFileContents() -> String
    {
        var text: String = "Year,Term,Department,CourseNumber,SectionNumber,Building,Room,TimeSlot,Instructor,CourseName\n"
        for (sectionID, section) in sections
        {
            text += String(format: "%4d,%@,%@,%d,%d,%@,%d,%@,%@,%@\n", section.year, section.term, section.department, section.courseNumber, section.sectionNumber, section.building, section.room, section.timeSlot, section.instructor, section.courseName)
        }
        return text
    }

    /// Completely overwrites the target file each time (doesn't append / update existing contents)
    func saveFile()
    {
        // get the name of the file we're going to write
        if let url = getPathname()
        {
            // generate the complete contents of the file we're going to write
            let text = generateFileContents()
            do
            {
                // write the entire file in one command
                try text.write(to: url, atomically: false, encoding: String.Encoding.utf8)
            }
            catch
            {
                print("ERROR: unable to write contents to \(url)")
            }
        }
        else
        {
            print("Can't generate url")
        }
    }
    
    func loadFromFile()
    {
        // clear the internal list
        sections = [:]
        
        // get the pathname of the file we're going to load
        if let url = getPathname()
        {
            do
            {
                // load the entire file in one command, because Swift is stupid
                let text = try String(contentsOf: url)
                
                // split the giant string we just read into an array of lines by delimiting at newline characters
                let lines = text.components(separatedBy: .newlines)
                
                // iterate over each line we read
                for line in lines
                {
                    // skip the header row
                    if !line.starts(with: "Year,")
                    {
                        // this wasn't the header row, so convert the line into a new CourseSection
                        loadSectionFromLine(line)
                    }
                }
            }
            catch
            {
                print("Error loading \(url): \(error)")
            }
        }
        else
        {
            print("Can't find document directory")
        }
    }
    
    func loadSectionFromLine(_ line: String)
    {
        // convert line into an array of strings by splitting on comma
        let tokens = line.components(separatedBy: ",")
        
        // check we found the expected number of fields
        if tokens.count != 10
        {
            print("ERROR: can't parse line \(tokens)")
            return
        }

        // "Year,Term,Department,CourseNumber,SectionNumber,Building,Room,TimeSlot,Instructor,CourseName"
        let year = Int(tokens[0])
        let term = tokens[1]
        let dept = tokens[2]
        let courseNum = Int(tokens[3])
        let sectionNum = Int(tokens[4])
        let building = tokens[5]
        let room = Int(tokens[6])
        let timeSlot = tokens[7]
        let instructor = tokens[8]
        let courseName = tokens[9]
        
        if year == nil || courseNum == nil || sectionNum == nil || room == nil
        {
            print("ERROR: can't parse one or more numeric fields: \(line)")
            return
        }
        
        // instantiate a new CourseSection from the fields we parsed
        let section = CourseSection(name: courseName, dept: dept, num: courseNum!, section: sectionNum!, instructor: instructor, building: building, room: room!, timeSlot: timeSlot, term: term, year: year!)
        var error = section.findErrors()
        if error != nil
        {
            print("ERROR: can't add invalid loaded CourseSection: \(String(describing: error))")
            return
        }
        
        // note that this will re-apply logic rules when loading files from disk;
        // you can't use Excel to generate conflicting sections and then sneak
        // them into the database that way
        error = canAdd(section, oldSectionID: nil)
        if error != nil
        {
            print("ERROR: can't add loaded CourseSection: \(String(describing: error))")
            return
        }
        
        addSection(section)
    }
}
