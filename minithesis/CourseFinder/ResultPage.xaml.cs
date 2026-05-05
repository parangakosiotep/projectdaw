using System;
using System.Collections.Generic;
using Microsoft.Maui.Controls;
using CourseFinder.Models;

namespace CourseFinder
{
    public partial class ResultPage : ContentPage
    {
        public ResultPage(List<Course> recommendations)
        {
            InitializeComponent();
            ResultsListView.ItemsSource = recommendations;
        }

        private async void OnRestartClicked(object sender, EventArgs e)
        {
            await Navigation.PopToRootAsync();
        }
    }
}
