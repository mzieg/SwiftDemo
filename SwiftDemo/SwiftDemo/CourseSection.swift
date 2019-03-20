import Foundation

class CourseSection
{
    var courseName: String  // e.g. "Data Structures"
    var department: String  // e.g. "CS"
    var courseNumber: Int   // e.g. 420
    var sectionNumber: Int  // e.g. 1-3
    var instructor: String  // e.g. "Prof. Knuth"
    var building: String    // e.g. "Leonard Hall"
    var room: Int           // e.g. 203
    var timeSlot: String    // e.g. "TR 9:15am"
    var term: String        // e.g. "Fall", "Spring" etc
    var year: Int           // e.g. 2019
    
    var sectionID: String   // e.g. "2019-Spring-CS-420-001" (year + term + dept + num + section)
    
    init(name:String, dept: String, num: Int, section: Int, instructor: String, building: String, room: Int, timeSlot: String, term: String, year: Int)
    {
        self.courseName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.department = dept.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.instructor = instructor.trimmingCharacters(in: .whitespacesAndNewlines)
        self.building = building.trimmingCharacters(in: .whitespacesAndNewlines)
        self.timeSlot = timeSlot.trimmingCharacters(in: .whitespacesAndNewlines)
        self.term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        self.courseNumber = num
        self.sectionNumber = section
        self.room = room
        self.year = year
        
        self.sectionID = String(format: "%04d-%@-%@-%d-%03d", year, term, dept, num, section)
        
        print("instantiated CourseSection \(self.sectionID)")
    }
    
    func findErrors() -> String?
    {
        if courseName.isEmpty
        {
            return "Course Name cannot be blank"
        }
        
        if department.isEmpty
        {
            return "Department cannot be blank"
        }
        
        if instructor.isEmpty
        {
            return "Instructor cannot be blank"
        }
        
        if building.isEmpty
        {
            return "Building cannot be blank"
        }
        
        if timeSlot.isEmpty
        {
            return "Time slot cannot be blank"
        }
        
        if term.isEmpty
        {
            return "Term cannot be blank"
        }
        
        let all = courseName + department + instructor + building + timeSlot + term
        if all.contains(",")
        {
            return "No commas allowed"
        }
        
        return nil
    }
}
