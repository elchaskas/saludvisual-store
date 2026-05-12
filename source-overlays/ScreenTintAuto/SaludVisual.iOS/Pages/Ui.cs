using SaludVisual.Shared;
using Microsoft.Maui.Controls.Shapes;

namespace SaludVisual.iOS.Pages;

internal static class Ui
{
    public static View Header(string title, string subtitle)
    {
        return new VerticalStackLayout
        {
            Spacing = 8,
            Children =
            {
                new Label
                {
                    Text = title,
                    FontSize = 30,
                    FontAttributes = FontAttributes.Bold,
                    TextColor = Color.FromArgb("#16324F")
                },
                new Label
                {
                    Text = subtitle,
                    FontSize = 16,
                    TextColor = Color.FromArgb("#4B5563")
                }
            }
        };
    }

    public static Border Card(params View[] children)
    {
        var stack = new VerticalStackLayout
        {
            Spacing = 12
        };
        foreach (var child in children)
        {
            stack.Children.Add(child);
        }

        return new Border
        {
            StrokeShape = new RoundRectangle { CornerRadius = 18 },
            Stroke = Color.FromArgb("#E5E7EB"),
            BackgroundColor = Colors.White,
            Padding = new Thickness(18),
            Content = stack
        };
    }

    public static Border StepCard(string number, string title, string body)
    {
        return Card(
            new Label
            {
                Text = $"{number}. {title}",
                FontAttributes = FontAttributes.Bold,
                FontSize = 18,
                TextColor = Color.FromArgb("#16324F")
            },
            new Label
            {
                Text = body,
                FontSize = 15,
                TextColor = Color.FromArgb("#374151")
            });
    }

    public static Button PrimaryButton(string text)
    {
        return new Button
        {
            Text = text,
            BackgroundColor = Color.FromArgb("#1D6F91"),
            TextColor = Colors.White,
            CornerRadius = 12,
            Padding = new Thickness(18, 12)
        };
    }

    public static Button SecondaryButton(string text)
    {
        return new Button
        {
            Text = text,
            BackgroundColor = Colors.White,
            BorderColor = Color.FromArgb("#1D6F91"),
            BorderWidth = 1,
            TextColor = Color.FromArgb("#1D6F91"),
            CornerRadius = 12,
            Padding = new Thickness(18, 12)
        };
    }

    public static Button SecondaryButton(string text, Func<Task> onClick)
    {
        var button = SecondaryButton(text);
        button.Clicked += async (_, _) => await onClick();
        return button;
    }

    public static Button LinkButton(string text, string url)
    {
        return SecondaryButton(text, async () => await Launcher.OpenAsync(url));
    }
}
