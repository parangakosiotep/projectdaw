namespace CourseFinderWeb.Models
{
    public class Course
    {
        public string Name { get; set; }
        public string Description { get; set; }
        public string Category { get; set; }
        public List<string> Skills { get; set; } = new List<string>();
        public List<string> KnowledgeAreas { get; set; } = new List<string>();
        public List<string> Hobbies { get; set; } = new List<string>();
        public double MatchScore { get; set; }
    }
}
