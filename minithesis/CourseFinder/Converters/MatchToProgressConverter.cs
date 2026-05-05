using System;
using System.Globalization;
using Microsoft.Maui.Controls;

namespace CourseFinder.Converters
{
    public class MatchToProgressConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is double matchScore)
            {
                // Convert percentage (0-100) to a fraction (0.0 - 1.0) for the ProgressBar
                return matchScore / 100.0;
            }
            return 0.0;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
