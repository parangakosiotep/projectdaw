namespace CourseFinderWeb.Models
{
    public class UserAssessment
    {
        public List<string> SelectedSkills { get; set; } = new List<string>();
        public List<string> SelectedKnowledge { get; set; } = new List<string>();
        public List<string> SelectedHobbies { get; set; } = new List<string>();
    }
}
