using CourseFinder.Models;
using CourseFinder.Services;

namespace CourseFinder
{
    public partial class AssessmentPage : ContentPage
    {
        private List<string> _skills = new List<string> { "Logic", "Math", "Problem Solving", "Creativity", "Visual Arts", "Leadership", "Communication", "Interpersonal", "Attention to Detail", "Empathy", "Analysis", "Design", "Physics", "Biology", "Ethics", "Listening", "Patience", "Organization", "Focus" };
        private List<string> _knowledge = new List<string> { "Technology", "Science", "Humanities", "History", "Economics", "Business", "Mathematics", "Biology", "Arts" };
        private List<string> _hobbies = new List<string> { "Gaming", "Coding", "Drawing", "Painting", "Photography", "Networking", "Public Speaking", "DIY", "Fixing things", "Building things", "Reading", "Volunteering", "Podcasts", "Sports", "Social Media", "Events", "Chess", "Travel" };

        private Dictionary<string, CheckBox> _skillBoxes = new Dictionary<string, CheckBox>();
        private Dictionary<string, CheckBox> _knowledgeBoxes = new Dictionary<string, CheckBox>();
        private Dictionary<string, CheckBox> _hobbyBoxes = new Dictionary<string, CheckBox>();

        public AssessmentPage()
        {
            InitializeComponent();
            PopulateLayouts();
        }

        private void PopulateLayouts()
        {
            foreach (var s in _skills) AddToLayout(SkillsLayout, s, _skillBoxes);
            foreach (var k in _knowledge) AddToLayout(KnowledgeLayout, k, _knowledgeBoxes);
            foreach (var h in _hobbies) AddToLayout(HobbiesLayout, h, _hobbyBoxes);
        }

        private void AddToLayout(FlexLayout layout, string text, Dictionary<string, CheckBox> dict)
        {
            var stack = new HorizontalStackLayout { Spacing = 5, Margin = new Thickness(0, 5, 15, 5) };
            var cb = new CheckBox { Color = (Color)Application.Current.Resources["PrimaryLight"] };
            var lbl = new Label { Text = text, VerticalOptions = LayoutOptions.Center, TextColor = (Color)Application.Current.Resources["White"] };
            
            stack.Children.Add(cb);
            stack.Children.Add(lbl);
            dict.Add(text, cb);
            layout.Children.Add(stack);
        }

        private async void OnCalculateClicked(object sender, EventArgs e)
        {
            var assessment = new UserAssessment
            {
                SelectedSkills = _skillBoxes.Where(x => x.Value.IsChecked).Select(x => x.Key).ToList(),
                SelectedKnowledge = _knowledgeBoxes.Where(x => x.Value.IsChecked).Select(x => x.Key).ToList(),
                SelectedHobbies = _hobbyBoxes.Where(x => x.Value.IsChecked).Select(x => x.Key).ToList()
            };

            if (!assessment.SelectedSkills.Any() && !assessment.SelectedKnowledge.Any() && !assessment.SelectedHobbies.Any())
            {
                await DisplayAlert("Selection Empty", "Please select at least one skill, knowledge area, or hobby.", "OK");
                return;
            }

            var service = App.Current.Handler.MauiContext.Services.GetService<RecommenderService>();
            var results = service.GetRecommendations(assessment);

            await Navigation.PushAsync(new ResultPage(results));
        }
    }
}
