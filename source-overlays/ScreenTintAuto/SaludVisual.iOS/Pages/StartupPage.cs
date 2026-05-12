namespace SaludVisual.iOS.Pages;

public sealed class StartupPage : ContentPage
{
    public StartupPage()
    {
        Title = "Salud Visual";
        BackgroundColor = Color.FromArgb("#F5F7FB");
        Content = new VerticalStackLayout
        {
            Padding = new Thickness(28),
            Spacing = 18,
            VerticalOptions = LayoutOptions.Center,
            Children =
            {
                new ActivityIndicator
                {
                    IsRunning = true,
                    Color = Color.FromArgb("#1D6F91")
                },
                new Label
                {
                    Text = "Preparando Salud Visual...",
                    HorizontalTextAlignment = TextAlignment.Center,
                    FontSize = 18,
                    TextColor = Color.FromArgb("#16324F")
                }
            }
        };
    }
}
