using CourseFinder.Models;

namespace CourseFinder.Services
{
    public class RecommenderService
    {
        private List<Course> _courses = new List<Course>
        {
            new Course 
            { 
                Name = "BS Computer Science", 
                Category = "Technology",
                Description = "Study of software, hardware, and advanced computation.",
                Skills = new List<string> { "Logic", "Math", "Problem Solving", "Focus" },
                KnowledgeAreas = new List<string> { "Technology", "Science" },
                Hobbies = new List<string> { "Gaming", "Coding", "Building things" }
            },
            new Course 
            { 
                Name = "BS Information Technology", 
                Category = "Technology",
                Description = "Focus on the practical application of technology in business.",
                Skills = new List<string> { "Problem Solving", "Logic", "Communication" },
                KnowledgeAreas = new List<string> { "Technology", "Business" },
                Hobbies = new List<string> { "Gaming", "Social Media", "DIY" }
            },
            new Course 
            { 
                Name = "BS Business Administration", 
                Category = "Business",
                Description = "Managing organizational resources and leadership.",
                Skills = new List<string> { "Leadership", "Communication", "Interpersonal", "Organization" },
                KnowledgeAreas = new List<string> { "Economics", "Humanities", "Business" },
                Hobbies = new List<string> { "Networking", "Public Speaking", "Events" }
            },
            new Course 
            { 
                Name = "BS Accountancy", 
                Category = "Business",
                Description = "Recording, classifying, and reporting financial transactions.",
                Skills = new List<string> { "Math", "Attention to Detail", "Logic", "Ethics" },
                KnowledgeAreas = new List<string> { "Economics", "Mathematics" },
                Hobbies = new List<string> { "Reading", "Chess", "Organization" }
            },
            new Course 
            { 
                Name = "BS Civil Engineering", 
                Category = "Engineering",
                Description = "Designing and building infrastructure like roads and bridges.",
                Skills = new List<string> { "Math", "Design", "Problem Solving", "Physics" },
                KnowledgeAreas = new List<string> { "Science", "Technology", "Mathematics" },
                Hobbies = new List<string> { "DIY", "Building things", "Drawing" }
            },
            new Course 
            { 
                Name = "BS Nursing", 
                Category = "Health Science",
                Description = "Caring for individuals, families, and communities.",
                Skills = new List<string> { "Empathy", "Communication", "Interpersonal", "Attention to Detail" },
                KnowledgeAreas = new List<string> { "Science", "Biology", "Humanities" },
                Hobbies = new List<string> { "Volunteering", "Sports", "Reading" }
            },
            new Course 
            { 
                Name = "AB Psychology", 
                Category = "Social Science",
                Description = "Exploring human mind and complex behaviors.",
                Skills = new List<string> { "Empathy", "Analysis", "Communication", "Listening" },
                KnowledgeAreas = new List<string> { "Humanities", "Science", "History" },
                Hobbies = new List<string> { "Reading", "Podcasts", "Volunteering" }
            },
            new Course 
            { 
                Name = "Bachelor of Secondary Education", 
                Category = "Education",
                Description = "Preparing to teach and inspire future generations.",
                Skills = new List<string> { "Communication", "Leadership", "Creativity", "Patience" },
                KnowledgeAreas = new List<string> { "Humanities", "History", "History" },
                Hobbies = new List<string> { "Public Speaking", "Reading", "Sports" }
            },
            new Course 
            { 
                Name = "BS Architecture", 
                Category = "Design",
                Description = "The art and science of designing buildings.",
                Skills = new List<string> { "Creativity", "Visual Arts", "Math", "Design" },
                KnowledgeAreas = new List<string> { "Arts", "Science", "History" },
                Hobbies = new List<string> { "Drawing", "Photography", "Travel" }
            }
        };

        public List<Course> GetRecommendations(UserAssessment assessment)
        {
            foreach (var course in _courses)
            {
                double score = 0;

                // Simple scoring logic
                score += course.Skills.Intersect(assessment.SelectedSkills).Count() * 3;
                score += course.KnowledgeAreas.Intersect(assessment.SelectedKnowledge).Count() * 2;
                score += course.Hobbies.Intersect(assessment.SelectedHobbies).Count() * 1;

                // Normalize slightly based on course attribute count
                double totalPossible = (course.Skills.Count * 3) + (course.KnowledgeAreas.Count * 2) + (course.Hobbies.Count * 1);
                course.MatchScore = (totalPossible > 0) ? (score / totalPossible) * 100 : 0;
            }

            return _courses
                .Where(c => c.MatchScore > 0)
                .OrderByDescending(c => c.MatchScore)
                .Take(3)
                .ToList();
        }
    }
}
