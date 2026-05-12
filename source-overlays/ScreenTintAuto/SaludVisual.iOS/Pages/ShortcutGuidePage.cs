namespace SaludVisual.iOS.Pages;

public sealed class ShortcutGuidePage : ContentPage
{
    public ShortcutGuidePage()
    {
        Title = "Atajos";
        BackgroundColor = Color.FromArgb("#F5F7FB");

        Content = new ScrollView
        {
            Content = new VerticalStackLayout
            {
                Padding = new Thickness(24),
                Spacing = 16,
                Children =
                {
                    Ui.Header("Automatizaciones con Atajos", "iOS permite programar acciones propias desde la app Atajos."),
                    Ui.StepCard("1", "Abre Atajos", "Entra en Automatizacion y crea una automatizacion personal."),
                    Ui.StepCard("2", "Elige horario", "Selecciona Hora del dia, Atardecer o Amanecer segun tu rutina visual."),
                    Ui.StepCard("3", "Anade accion", "Busca acciones relacionadas con Night Shift, brillo, punto blanco o filtros disponibles en tu version de iOS."),
                    Ui.StepCard("4", "Evita confirmaciones", "Si iOS muestra Preguntar antes de ejecutar, desactivalo cuando este disponible."),
                    Ui.StepCard("5", "Crea una automatizacion inversa", "Programa otra automatizacion para volver a tu configuracion normal por la manana."),
                    Ui.SecondaryButton("Abrir Atajos", async () => await Launcher.OpenAsync("shortcuts://"))
                }
            }
        };
    }
}
