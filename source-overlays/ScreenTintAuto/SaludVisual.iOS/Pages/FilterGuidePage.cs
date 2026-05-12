namespace SaludVisual.iOS.Pages;

public sealed class FilterGuidePage : ContentPage
{
    public FilterGuidePage()
    {
        Title = "Filtros iOS";
        BackgroundColor = Color.FromArgb("#F5F7FB");

        Content = new ScrollView
        {
            Content = new VerticalStackLayout
            {
                Padding = new Thickness(24),
                Spacing = 16,
                Children =
                {
                    Ui.Header("Configura los filtros nativos", "Estos ajustes son los que iOS permite aplicar a toda la pantalla."),
                    Ui.StepCard("1", "Reducir punto blanco", "Abre Ajustes > Accesibilidad > Pantalla y tamano del texto > Reducir punto blanco. Activalo y ajusta la intensidad."),
                    Ui.StepCard("2", "Filtros de color", "Abre Ajustes > Accesibilidad > Pantalla y tamano del texto > Filtros de color. Prueba Matiz de color para un tono mas calido."),
                    Ui.StepCard("3", "Night Shift", "Abre Ajustes > Pantalla y brillo > Night Shift. Programa el horario nocturno y ajusta la calidez."),
                    Ui.StepCard("4", "Funcion rapida", "Abre Ajustes > Accesibilidad > Funcion rapida y marca Filtros de color o Reducir punto blanco para activarlo con triple clic."),
                    Ui.SecondaryButton("Abrir Ajustes", async () => await Launcher.OpenAsync("app-settings:"))
                }
            }
        };
    }
}
